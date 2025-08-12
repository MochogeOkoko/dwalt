import 'package:googleapis/gmail/v1.dart' as gmail;
import '../models/ticket.dart';
import '../config/ticketing_platforms.dart';
import 'gmail_service.dart';
import 'dart:convert';

/// Service for identifying and managing tickets from Gmail
class TicketService {
  /// Filter emails to identify potential tickets
  static Future<List<Ticket>> identifyTicketsFromEmails({
    List<gmail.Message>? emails,
    int maxResults = 20,
  }) async {
    try {
      print('🔍 Starting ticket identification...');

      // Get emails if not provided
      if (emails == null) {
        print('📧 Initializing Gmail service...');
        await GmailService.initialize();
        print('📧 Fetching emails from Gmail with sender patterns...');

        // Get sender patterns from TicketingPlatforms
        final senderPatterns = TicketingPlatforms.ticketSenderPatterns;
        print('📧 Using sender patterns: $senderPatterns');

        emails = await GmailService.getEmails(
          maxResults: maxResults,
          senderPatterns: senderPatterns,
        );
        print('📧 Found ${emails.length} emails from ticketing platforms');
      }

      final List<Ticket> tickets = [];

      for (final email in emails) {
        final ticket = await _processEmailForTicket(email);
        if (ticket != null) {
          print('🎫 Found ticket: ${ticket.subject} from ${ticket.platform}');
          tickets.add(ticket);
        }
      }

      print(
        '✅ Ticket identification complete. Found ${tickets.length} tickets.',
      );
      return tickets;
    } catch (e) {
      print('❌ Error identifying tickets: $e');
      throw Exception('Failed to identify tickets from emails: $e');
    }
  }

  /// Process a single email to check if it contains a ticket
  static Future<Ticket?> _processEmailForTicket(gmail.Message email) async {
    try {
      // Extract email details
      final subject = _getEmailSubject(email);
      final sender = _getEmailSender(email);
      final body = await _getEmailBody(email);
      final receivedDate = _getEmailDate(email);

      if (subject.isEmpty || sender.isEmpty) {
        return null;
      }

      print('📬 Processing email: "$subject" from "$sender"');

      // Since we're already filtering by sender patterns at the Gmail API level,
      // we can assume this email is from a ticketing platform
      final platform = TicketingPlatforms.getIdentifiedPlatform(
        subject: subject,
        sender: sender,
        body: body,
      );

      if (platform == null) {
        print(
          '❌ Could not identify platform for email: "$subject" from "$sender"',
        );
        return null;
      }

      print(
        '✅ Found ticket email: "$subject" from "$sender" (Platform: $platform)',
      );

      // Create ticket from email
      final ticket = Ticket.fromGmailMessage(
        emailId: email.id!,
        subject: subject,
        sender: sender,
        receivedDate: receivedDate,
        body: body,
      );

      // Try to extract additional ticket information
      return await _extractTicketDetails(ticket, body);
    } catch (e) {
      print('Error processing email for ticket: $e');
      return null;
    }
  }

  /// Extract additional ticket details from email body
  static Future<Ticket> _extractTicketDetails(
    Ticket ticket,
    String body,
  ) async {
    // Extract attachment information
    final attachments = await _extractAttachments(ticket.emailId);
    final links = _extractLinks(body);

    // Create metadata with attachment and link information
    final metadata = <String, dynamic>{
      'attachments': attachments,
      'links': links,
      'hasQrCode': attachments.isNotEmpty || links.isNotEmpty,
    };

    return ticket.copyWith(metadata: metadata);
  }

  /// Extract attachment information from the email
  static Future<List<Map<String, dynamic>>> _extractAttachments(
    String emailId,
  ) async {
    try {
      final gmailApi = GmailService.gmailApi;
      if (gmailApi == null) return [];

      final message = await gmailApi.users.messages.get('me', emailId);
      if (message.payload == null) return [];

      final attachments = <Map<String, dynamic>>[];
      _extractAttachmentsFromPart(message.payload!, attachments);

      return attachments;
    } catch (e) {
      print('Error extracting attachments: $e');
      return [];
    }
  }

  /// Recursively extract attachments from message parts
  static void _extractAttachmentsFromPart(
    gmail.MessagePart part,
    List<Map<String, dynamic>> attachments,
  ) {
    // Check if this part is an attachment
    if (part.filename != null && part.filename!.isNotEmpty) {
      attachments.add({
        'filename': part.filename,
        'mimeType': part.mimeType ?? 'unknown',
        'size': part.body?.size ?? 0,
        'attachmentId': part.body?.attachmentId,
      });
      print('📎 Found attachment: ${part.filename} (${part.mimeType})');
    }

    // Check nested parts
    if (part.parts != null) {
      for (final nestedPart in part.parts!) {
        _extractAttachmentsFromPart(nestedPart, attachments);
      }
    }
  }

  /// Extract links from email body
  static List<String> _extractLinks(String body) {
    final links = <String>[];

    // Common link patterns
    final linkPatterns = [
      RegExp(r'https?://[^\s]+'),
      RegExp(r'www\.[^\s]+'),
      RegExp(r'bit\.ly/[^\s]+'),
      RegExp(r'tinyurl\.com/[^\s]+'),
      RegExp(r'qr\.co/[^\s]+'),
      RegExp(r'qr-code[^\s]*'),
    ];

    for (final pattern in linkPatterns) {
      final matches = pattern.allMatches(body);
      for (final match in matches) {
        final link = match.group(0);
        if (link != null && !links.contains(link)) {
          links.add(link);
          print('🔗 Found link: $link');
        }
      }
    }

    return links;
  }

  /// Get email subject from Gmail message
  static String _getEmailSubject(gmail.Message email) {
    try {
      final headers = email.payload?.headers;
      if (headers != null) {
        final subjectHeader = headers.firstWhere(
          (header) => header.name?.toLowerCase() == 'subject',
          orElse: () => gmail.MessagePartHeader(),
        );
        return subjectHeader.value ?? '';
      }
    } catch (e) {
      print('Error extracting subject: $e');
    }
    return '';
  }

  /// Get email sender from Gmail message
  static String _getEmailSender(gmail.Message email) {
    try {
      final headers = email.payload?.headers;
      if (headers != null) {
        final fromHeader = headers.firstWhere(
          (header) => header.name?.toLowerCase() == 'from',
          orElse: () => gmail.MessagePartHeader(),
        );
        return fromHeader.value ?? '';
      }
    } catch (e) {
      print('Error extracting sender: $e');
    }
    return '';
  }

  /// Get email date from Gmail message
  static DateTime _getEmailDate(gmail.Message email) {
    try {
      final headers = email.payload?.headers;
      if (headers != null) {
        final dateHeader = headers.firstWhere(
          (header) => header.name?.toLowerCase() == 'date',
          orElse: () => gmail.MessagePartHeader(),
        );
        if (dateHeader.value != null) {
          return DateTime.parse(dateHeader.value!);
        }
      }
    } catch (e) {
      print('Error extracting date: $e');
    }
    return DateTime.now();
  }

  /// Get email body from Gmail message
  static Future<String> _getEmailBody(gmail.Message email) async {
    try {
      final payload = email.payload;
      if (payload == null) return '';

      // Try to get plain text body first
      String body = _extractBodyFromPart(payload);

      // If no plain text, try HTML and strip tags
      if (body.isEmpty && payload.parts != null) {
        for (final part in payload.parts!) {
          if (part.mimeType == 'text/html') {
            body = _extractBodyFromPart(part);
            // Simple HTML tag removal (you might want to use a proper HTML parser)
            body = body.replaceAll(RegExp(r'<[^>]*>'), '');
            break;
          }
        }
      }

      return body;
    } catch (e) {
      print('Error extracting body: $e');
      return '';
    }
  }

  /// Extract body text from a message part
  static String _extractBodyFromPart(gmail.MessagePart part) {
    try {
      if (part.body?.data != null) {
        // Decode base64 data directly
        final decoded = utf8.decode(base64Url.decode(part.body!.data!));
        return decoded;
      }
    } catch (e) {
      print('Error extracting body from part: $e');
    }
    return '';
  }

  /// Filter tickets by various criteria
  static List<Ticket> filterTickets({
    required List<Ticket> tickets,
    String? platform,
    TicketStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
    String? searchQuery,
  }) {
    return tickets.where((ticket) {
      // Filter by platform
      if (platform != null && ticket.platform != platform) {
        return false;
      }

      // Filter by status
      if (status != null && ticket.status != status) {
        return false;
      }

      // Filter by date range
      if (fromDate != null && ticket.receivedDate.isBefore(fromDate)) {
        return false;
      }
      if (toDate != null && ticket.receivedDate.isAfter(toDate)) {
        return false;
      }

      // Filter by search query
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matches =
            ticket.subject.toLowerCase().contains(query) ||
            (ticket.eventName?.toLowerCase().contains(query) ?? false) ||
            (ticket.eventLocation?.toLowerCase().contains(query) ?? false) ||
            (ticket.platform?.toLowerCase().contains(query) ?? false);
        if (!matches) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Get statistics about tickets
  static Map<String, dynamic> getTicketStatistics(List<Ticket> tickets) {
    final totalTickets = tickets.length;
    final activeTickets = tickets.where((t) => t.status.isActive).length;
    final expiredTickets = tickets.where((t) => t.status.isExpired).length;

    final platformCounts = <String, int>{};
    for (final ticket in tickets) {
      final platform = ticket.platform ?? 'Unknown';
      platformCounts[platform] = (platformCounts[platform] ?? 0) + 1;
    }

    return {
      'totalTickets': totalTickets,
      'activeTickets': activeTickets,
      'expiredTickets': expiredTickets,
      'platformCounts': platformCounts,
    };
  }
}
