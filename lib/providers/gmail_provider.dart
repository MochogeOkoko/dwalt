import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import '../services/gmail_service.dart';
import '../services/auth_service.dart';
import 'auth_provider.dart';

// Provider for Gmail profile
final gmailProfileProvider = FutureProvider<gmail.Profile?>((ref) async {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  if (!isAuthenticated) {
    return null;
  }

  try {
    await GmailService.initialize();
    return await GmailService.getProfile();
  } catch (e) {
    throw Exception('Failed to get Gmail profile: $e');
  }
});

// Provider for Gmail emails
final gmailEmailsProvider =
    FutureProvider.family<List<gmail.Message>, Map<String, dynamic>>((
      ref,
      params,
    ) async {
      final isAuthenticated = ref.watch(isAuthenticatedProvider);
      if (!isAuthenticated) {
        return [];
      }

      try {
        await GmailService.initialize();
        return await GmailService.getEmails(
          maxResults: params['maxResults'] ?? 10,
          query: params['query'],
        );
      } catch (e) {
        throw Exception('Failed to get emails: $e');
      }
    });

// Notifier for Gmail operations
class GmailNotifier extends StateNotifier<AsyncValue<List<gmail.Message>>> {
  GmailNotifier() : super(const AsyncValue.data([]));

  Future<void> loadEmails({int maxResults = 10, String? query}) async {
    state = const AsyncValue.loading();
    try {
      await GmailService.initialize();
      final emails = await GmailService.getEmails(
        maxResults: maxResults,
        query: query,
      );
      state = AsyncValue.data(emails);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> sendEmail({
    required String to,
    required String subject,
    required String body,
    String? from,
  }) async {
    try {
      await GmailService.initialize();
      await GmailService.sendEmail(
        to: to,
        subject: subject,
        body: body,
        from: from,
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void clearEmails() {
    state = const AsyncValue.data([]);
  }
}

// Provider for Gmail notifier
final gmailNotifierProvider =
    StateNotifierProvider<GmailNotifier, AsyncValue<List<gmail.Message>>>((
      ref,
    ) {
      return GmailNotifier();
    });

// Provider for checking if Gmail is available
final gmailAvailableProvider = Provider<bool>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  return isAuthenticated && GmailService.isInitialized;
});
