import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/ticket_provider.dart';
import '../models/ticket.dart';
import '../router/routes.dart';

class TicketsPage extends ConsumerWidget {
  const TicketsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(ticketProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Tickets'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.homePath),
          tooltip: 'Back to Home',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(ticketProvider.notifier).refreshTickets(),
            tooltip: 'Refresh Tickets',
          ),
        ],
      ),
      body: ticketsAsync.when(
        data: (tickets) => _buildTicketsList(context, tickets),
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading tickets...'),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading tickets: $error',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(ticketProvider.notifier).refreshTickets(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketsList(BuildContext context, List<Ticket> tickets) {
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.confirmation_number, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No tickets found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tickets from supported platforms will appear here.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.go(AppRoutes.homePath),
              icon: const Icon(Icons.home),
              label: const Text('Back to Home'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header with ticket count
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: Row(
            children: [
              const Icon(Icons.confirmation_number, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                '${tickets.length} ticket${tickets.length == 1 ? '' : 's'} found',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Tickets list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return _buildTicketCard(context, ticket);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTicketCard(BuildContext context, Ticket ticket) {
    final hasAttachments = ticket.metadata?['hasQrCode'] == true;
    final attachments = ticket.metadata?['attachments'] as List<dynamic>? ?? [];
    final links = ticket.metadata?['links'] as List<dynamic>? ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getPlatformColor(ticket.platform),
          child: Stack(
            children: [
              Center(
                child: Text(
                  _getPlatformInitial(ticket.platform),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (hasAttachments)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.qr_code,
                      size: 8,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
        title: Text(
          ticket.subject,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'From: ${ticket.sender}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Received: ${_formatDate(ticket.receivedDate)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (ticket.platform != null) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPlatformColor(ticket.platform).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ticket.platform!,
                  style: TextStyle(
                    fontSize: 10,
                    color: _getPlatformColor(ticket.platform),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            if (hasAttachments) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  if (attachments.isNotEmpty) ...[
                    Icon(Icons.attach_file, size: 12, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      '${attachments.length} attachment${attachments.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (links.isNotEmpty) ...[
                    if (attachments.isNotEmpty) const SizedBox(width: 8),
                    Icon(Icons.link, size: 12, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      '${links.length} link${links.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
        trailing: _buildStatusChip(ticket.status),
        onTap: () {
          _showTicketDetails(context, ticket);
        },
      ),
    );
  }

  void _showTicketDetails(BuildContext context, Ticket ticket) {
    final attachments = ticket.metadata?['attachments'] as List<dynamic>? ?? [];
    final links = ticket.metadata?['links'] as List<dynamic>? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.subject,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'From: ${ticket.sender}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Received: ${_formatDate(ticket.receivedDate)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              if (ticket.platform != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getPlatformColor(ticket.platform).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Platform: ${ticket.platform}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _getPlatformColor(ticket.platform),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (attachments.isNotEmpty) ...[
                const Text(
                  'Attachments',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: attachments.length,
                    itemBuilder: (context, index) {
                      final attachment = attachments[index];
                      return ListTile(
                        leading: const Icon(Icons.attach_file, color: Colors.blue),
                        title: Text(attachment['filename'] ?? 'Unknown'),
                        subtitle: Text('${attachment['mimeType']} - ${_formatFileSize(attachment['size'] ?? 0)}'),
                        onTap: () {
                          // TODO: Download or view attachment
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Viewing: ${attachment['filename']}')),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
              if (links.isNotEmpty) ...[
                const Text(
                  'Links',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: links.length,
                    itemBuilder: (context, index) {
                      final link = links[index];
                      return ListTile(
                        leading: const Icon(Icons.link, color: Colors.green),
                        title: Text(link),
                        onTap: () {
                          // TODO: Open link
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Opening: $link')),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(TicketStatus status) {
    Color color;
    String text;

    switch (status) {
      case TicketStatus.active:
        color = Colors.green;
        text = 'Active';
        break;
      case TicketStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case TicketStatus.used:
        color = Colors.grey;
        text = 'Used';
        break;
      case TicketStatus.expired:
        color = Colors.red;
        text = 'Expired';
        break;
      case TicketStatus.cancelled:
        color = Colors.red;
        text = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getPlatformColor(String? platform) {
    if (platform == null) return Colors.grey;

    switch (platform.toLowerCase()) {
      case 'hello@hustlesasa.com':
        return Colors.blue;
      case 'hello@mookh.africa':
        return Colors.green;
      default:
        return Colors.purple;
    }
  }

  String _getPlatformInitial(String? platform) {
    if (platform == null) return '?';

    if (platform.contains('hustlesasa')) return 'H';
    if (platform.contains('mookh')) return 'M';

    return platform.isNotEmpty ? platform[0].toUpperCase() : '?';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today at ${_formatTime(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${_formatTime(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
