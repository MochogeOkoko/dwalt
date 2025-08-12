import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email, size: 100, color: Colors.blue),
              const SizedBox(height: 32),
              const Text(
                'Ticket Aggregator',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sign in with your Google account to access Gmail',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              authState.when(
                data: (user) => user == null
                    ? _buildSignInButton(ref)
                    : _buildUserInfo(user),
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => _buildErrorWidget(error.toString()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton(WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () =>
          ref.read(authNotifierProvider.notifier).signInWithGoogle(),
      icon: const Icon(Icons.login),
      label: const Text('Sign in with Google'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        textStyle: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildUserInfo(user) {
    return Column(
      children: [
        const Icon(Icons.check_circle, size: 64, color: Colors.green),
        const SizedBox(height: 16),
        Text(
          'Welcome, ${user.email ?? 'User'}!',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'You are now signed in',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(String error) {
    return Column(
      children: [
        const Icon(Icons.error, size: 64, color: Colors.red),
        const SizedBox(height: 16),
        Text(
          'Error: $error',
          style: const TextStyle(fontSize: 16, color: Colors.red),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
