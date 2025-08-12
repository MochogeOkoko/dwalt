import 'dart:convert';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class GmailService {
  static gmail.GmailApi? _gmailApi;
  static AccessToken? _accessToken;

  /// Initialize Gmail API with Supabase access token
  static Future<void> initialize() async {
    try {
      print('🔐 Initializing Gmail service...');
      final token = await AuthService.accessToken;
      if (token != null) {
        print('✅ Found Google access token');
        _accessToken = AccessToken(
          'Bearer',
          token,
          DateTime.now().toUtc().add(const Duration(hours: 1)),
        );
        final credentials = AccessCredentials(_accessToken!, null, [
          'https://www.googleapis.com/auth/gmail.readonly',
          'https://www.googleapis.com/auth/gmail.send',
        ]);

        final client = authenticatedClient(http.Client(), credentials);
        _gmailApi = gmail.GmailApi(client);
        print('✅ Gmail API initialized successfully');
      } else {
        print('❌ No Google access token found');
        throw Exception('No Google access token available');
      }
    } catch (e) {
      print('❌ Failed to initialize Gmail API: $e');
      throw Exception('Failed to initialize Gmail API: $e');
    }
  }

  /// Get Gmail API instance
  static gmail.GmailApi? get gmailApi => _gmailApi;

  /// Check if Gmail API is initialized
  static bool get isInitialized => _gmailApi != null;

  /// Get user's Gmail profile
  static Future<gmail.Profile?> getProfile() async {
    if (!isInitialized) {
      await initialize();
    }

    try {
      return await _gmailApi?.users.getProfile('me');
    } catch (e) {
      throw Exception('Failed to get Gmail profile: $e');
    }
  }

  /// Get emails from Gmail
  static Future<List<gmail.Message>> getEmails({
    int maxResults = 20,
    String? query,
    List<String>? senderPatterns,
  }) async {
    if (!isInitialized) {
      await initialize();
    }

    try {
      print('📧 Fetching emails from Gmail (max: $maxResults)...');

      // Build query string if sender patterns are provided
      String? finalQuery = query;
      if (senderPatterns != null && senderPatterns.isNotEmpty) {
        final senderQueries = senderPatterns
            .map((pattern) => 'from:$pattern')
            .join(' OR ');
        finalQuery = finalQuery != null
            ? '($finalQuery) AND ($senderQueries)'
            : senderQueries;
        print('📧 Using query filter: $finalQuery');
      }

      final response = await _gmailApi?.users.messages.list(
        'me',
        maxResults: maxResults,
        q: finalQuery,
      );

      if (response?.messages == null) {
        print('📧 No messages found in Gmail');
        return [];
      }

      print(
        '📧 Found ${response!.messages!.length} message IDs, fetching full details...',
      );

      // Get full message details for each message
      final messages = <gmail.Message>[];
      for (final message in response.messages!) {
        final fullMessage = await _gmailApi?.users.messages.get(
          'me',
          message.id!,
        );
        if (fullMessage != null) {
          // Check if the message has relevant attachments
          if (_hasRelevantAttachments(fullMessage)) {
            messages.add(fullMessage);
            print(
              '📎 Found message with relevant attachments: ${getEmailSubject(fullMessage)}',
            );
          } else {
            print(
              '❌ Message skipped - no relevant attachments: ${getEmailSubject(fullMessage)}',
            );
          }
        }
      }

      print(
        '📧 Successfully fetched ${messages.length} messages with relevant attachments',
      );
      return messages;
    } catch (e) {
      print('❌ Failed to get emails: $e');
      throw Exception('Failed to get emails: $e');
    }
  }

  /// Check if a message has relevant attachments (PDF, images, or links)
  static bool _hasRelevantAttachments(gmail.Message message) {
    try {
      final payload = message.payload;
      if (payload == null) return false;

      // Check for attachments in the main payload
      if (_hasAttachmentsInPart(payload)) {
        return true;
      }

      // Check for attachments in message parts
      if (payload.parts != null) {
        for (final part in payload.parts!) {
          if (_hasAttachmentsInPart(part)) {
            return true;
          }
          // Recursively check nested parts
          if (part.parts != null) {
            for (final nestedPart in part.parts!) {
              if (_hasAttachmentsInPart(nestedPart)) {
                return true;
              }
            }
          }
        }
      }

      // Check for links in the email body
      if (_hasLinksInBody(message)) {
        return true;
      }

      return false;
    } catch (e) {
      print('Error checking attachments: $e');
      return false;
    }
  }

  /// Check if a message part has relevant attachments
  static bool _hasAttachmentsInPart(gmail.MessagePart part) {
    // Check for PDF attachments
    if (part.mimeType == 'application/pdf') {
      print('📎 Found PDF attachment');
      return true;
    }

    // Check for image attachments (common QR code formats)
    if (part.mimeType?.startsWith('image/') == true) {
      final imageType = part.mimeType?.toLowerCase();
      if (imageType == 'image/jpeg' ||
          imageType == 'image/jpg' ||
          imageType == 'image/png' ||
          imageType == 'image/gif' ||
          imageType == 'image/webp') {
        print('📎 Found image attachment: $imageType');
        return true;
      }
    }

    // Check for other document types that might contain QR codes
    if (part.mimeType ==
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document' ||
        part.mimeType == 'application/msword' ||
        part.mimeType ==
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' ||
        part.mimeType == 'application/vnd.ms-excel') {
      print('📎 Found document attachment: ${part.mimeType}');
      return true;
    }

    return false;
  }

  /// Check if the email body contains links
  static bool _hasLinksInBody(gmail.Message message) {
    try {
      final body = getEmailContent(message);
      if (body.isEmpty) return false;

      // Check for common link patterns
      final linkPatterns = [
        RegExp(r'https?://[^\s]+'),
        RegExp(r'www\.[^\s]+'),
        RegExp(r'bit\.ly/[^\s]+'),
        RegExp(r'tinyurl\.com/[^\s]+'),
        RegExp(r'qr\.co/[^\s]+'),
        RegExp(r'qr-code[^\s]*'),
      ];

      for (final pattern in linkPatterns) {
        if (pattern.hasMatch(body)) {
          print('🔗 Found link in email body');
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error checking links in body: $e');
      return false;
    }
  }

  /// Send email using Gmail API
  static Future<void> sendEmail({
    required String to,
    required String subject,
    required String body,
    String? from,
  }) async {
    if (!isInitialized) {
      await initialize();
    }

    try {
      final message = gmail.Message(
        raw: _createRawEmail(to: to, subject: subject, body: body, from: from),
      );

      await _gmailApi?.users.messages.send(message, 'me');
    } catch (e) {
      throw Exception('Failed to send email: $e');
    }
  }

  /// Create raw email in base64 format
  static String _createRawEmail({
    required String to,
    required String subject,
    required String body,
    String? from,
  }) {
    final email =
        '''
From: ${from ?? 'me'}
To: $to
Subject: $subject
Content-Type: text/plain; charset=UTF-8

$body
''';

    return base64Url.encode(utf8.encode(email));
  }

  /// Get email content as text
  static String getEmailContent(gmail.Message message) {
    if (message.payload?.body?.data != null) {
      return utf8.decode(base64Url.decode(message.payload!.body!.data!));
    } else if (message.payload?.parts != null) {
      for (final part in message.payload!.parts!) {
        if (part.mimeType == 'text/plain' && part.body?.data != null) {
          return utf8.decode(base64Url.decode(part.body!.data!));
        }
      }
    }
    return '';
  }

  /// Get email subject
  static String getEmailSubject(gmail.Message message) {
    if (message.payload?.headers != null) {
      for (final header in message.payload!.headers!) {
        if (header.name?.toLowerCase() == 'subject') {
          return header.value ?? '';
        }
      }
    }
    return '';
  }

  /// Get email sender
  static String getEmailSender(gmail.Message message) {
    if (message.payload?.headers != null) {
      for (final header in message.payload!.headers!) {
        if (header.name?.toLowerCase() == 'from') {
          return header.value ?? '';
        }
      }
    }
    return '';
  }
}
