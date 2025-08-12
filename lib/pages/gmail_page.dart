import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/gmail_provider.dart';

class GmailPage extends ConsumerWidget {
  const GmailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailsAsync = ref.watch(gmailNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gmail'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(gmailNotifierProvider.notifier).loadEmails(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: emailsAsync.when(
        data: (emails) => emails.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.email, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No emails found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: emails.length,
                itemBuilder: (context, index) {
                  final email = emails[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Text(
                          email.snippet?.substring(0, 1).toUpperCase() ?? 'E',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        email.snippet ?? 'No subject',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        email.snippet ?? 'No content',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        // TODO: Show email details
                      },
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error: $error',
                style: const TextStyle(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(gmailNotifierProvider.notifier).loadEmails(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
