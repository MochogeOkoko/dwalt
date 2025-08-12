import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ticket.dart';
import '../services/ticket_service.dart';
import '../services/gmail_service.dart';
import '../services/auth_service.dart';
import 'auth_provider.dart';

/// Provider for ticket-related operations
class TicketNotifier extends StateNotifier<AsyncValue<List<Ticket>>> {
  TicketNotifier() : super(const AsyncValue.loading()) {
    // Automatically load tickets when the notifier is created
    _loadTicketsOnInit();
  }

  /// Load tickets on initialization
  Future<void> _loadTicketsOnInit() async {
    try {
      print('🎫 TicketNotifier: Starting initial ticket load...');

      // Check if user is authenticated
      if (!AuthService.isAuthenticated) {
        print('❌ User not authenticated, skipping ticket load');
        state = const AsyncValue.data([]);
        return;
      }

      // Check if we have Google access token
      var googleToken = await AuthService.accessToken;
      if (googleToken == null) {
        print('❌ No Google access token available, attempting to refresh...');
        final refreshed = await AuthService.refreshGoogleToken();
        if (refreshed) {
          googleToken = await AuthService.accessToken;
        }
      }

      if (googleToken == null) {
        print('❌ Still no Google access token available, skipping ticket load');
        state = const AsyncValue.data([]);
        return;
      }

      final tickets = await TicketService.identifyTicketsFromEmails(
        maxResults: 20,
      );
      print('🎫 TicketNotifier: Loaded ${tickets.length} tickets');
      state = AsyncValue.data(tickets);
    } catch (error, stackTrace) {
      print('❌ TicketNotifier: Error loading tickets: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Load tickets from Gmail
  Future<void> loadTickets({int maxResults = 20}) async {
    state = const AsyncValue.loading();
    try {
      final tickets = await TicketService.identifyTicketsFromEmails(
        maxResults: maxResults,
      );
      state = AsyncValue.data(tickets);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Refresh tickets
  Future<void> refreshTickets({int maxResults = 20}) async {
    await loadTickets(maxResults: maxResults);
  }

  /// Filter tickets by various criteria
  List<Ticket> filterTickets({
    String? platform,
    TicketStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
    String? searchQuery,
  }) {
    final tickets = state.value ?? [];
    return TicketService.filterTickets(
      tickets: tickets,
      platform: platform,
      status: status,
      fromDate: fromDate,
      toDate: toDate,
      searchQuery: searchQuery,
    );
  }

  /// Get ticket statistics
  Map<String, dynamic> getStatistics() {
    final tickets = state.value ?? [];
    return TicketService.getTicketStatistics(tickets);
  }

  /// Update ticket status
  void updateTicketStatus(String ticketId, TicketStatus newStatus) {
    final tickets = state.value ?? [];
    final updatedTickets = tickets.map((ticket) {
      if (ticket.id == ticketId) {
        return ticket.copyWith(status: newStatus);
      }
      return ticket;
    }).toList();
    state = AsyncValue.data(updatedTickets);
  }

  /// Add a new platform keyword
  void addPlatformKeyword(String keyword) {
    // This would typically update a persistent storage
    // For now, just reload tickets to pick up new keywords
    loadTickets();
  }
}

/// Provider for ticket state
final ticketProvider =
    StateNotifierProvider<TicketNotifier, AsyncValue<List<Ticket>>>(
      (ref) => TicketNotifier(),
    );

/// Provider for filtered tickets
final filteredTicketsProvider =
    Provider.family<List<Ticket>, Map<String, dynamic>>((ref, filters) {
      final ticketNotifier = ref.watch(ticketProvider.notifier);
      return ticketNotifier.filterTickets(
        platform: filters['platform'] as String?,
        status: filters['status'] as TicketStatus?,
        fromDate: filters['fromDate'] as DateTime?,
        toDate: filters['toDate'] as DateTime?,
        searchQuery: filters['searchQuery'] as String?,
      );
    });

/// Provider for ticket statistics
final ticketStatisticsProvider = Provider<Map<String, dynamic>>((ref) {
  final ticketNotifier = ref.watch(ticketProvider.notifier);
  return ticketNotifier.getStatistics();
});

/// Provider for available platforms
final availablePlatformsProvider = Provider<List<String>>((ref) {
  final tickets = ref.watch(ticketProvider).value ?? [];
  final platforms = tickets
      .map((ticket) => ticket.platform)
      .where((platform) => platform != null)
      .cast<String>()
      .toSet()
      .toList();
  platforms.sort();
  return platforms;
});

/// Provider for tickets by platform
final ticketsByPlatformProvider = Provider.family<List<Ticket>, String>((
  ref,
  platform,
) {
  final tickets = ref.watch(ticketProvider).value ?? [];
  return tickets.where((ticket) => ticket.platform == platform).toList();
});

/// Provider for active tickets
final activeTicketsProvider = Provider<List<Ticket>>((ref) {
  final tickets = ref.watch(ticketProvider).value ?? [];
  return tickets.where((ticket) => ticket.status.isActive).toList();
});

/// Provider for expired tickets
final expiredTicketsProvider = Provider<List<Ticket>>((ref) {
  final tickets = ref.watch(ticketProvider).value ?? [];
  return tickets.where((ticket) => ticket.status.isExpired).toList();
});

/// Provider for upcoming tickets (active tickets with future event dates)
final upcomingTicketsProvider = Provider<List<Ticket>>((ref) {
  final tickets = ref.watch(ticketProvider).value ?? [];
  final now = DateTime.now();
  return tickets.where((ticket) {
    return ticket.status.isActive &&
        ticket.eventDate != null &&
        ticket.eventDate!.isAfter(now);
  }).toList()..sort(
    (a, b) => (a.eventDate ?? DateTime(2100)).compareTo(
      b.eventDate ?? DateTime(2100),
    ),
  );
});

/// Provider for recent tickets (received in the last 30 days)
final recentTicketsProvider = Provider<List<Ticket>>((ref) {
  final tickets = ref.watch(ticketProvider).value ?? [];
  final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
  return tickets
      .where((ticket) => ticket.receivedDate.isAfter(thirtyDaysAgo))
      .toList()
    ..sort((a, b) => b.receivedDate.compareTo(a.receivedDate));
});
