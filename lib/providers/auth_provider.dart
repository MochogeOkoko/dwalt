import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

// Provider for the current user
final currentUserProvider = StreamProvider<User?>((ref) {
  return AuthService.authStateChanges.map((event) => event.session?.user);
});

// Provider for authentication state
final authStateProvider = StreamProvider<AuthState>((ref) {
  return AuthService.authStateChanges;
});

// Provider for checking if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

// Provider for user email
final userEmailProvider = Provider<String?>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user?.email,
    loading: () => null,
    error: (_, __) => null,
  );
});

// Provider for user display name
final userDisplayNameProvider = Provider<String?>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user?.userMetadata?['full_name'] as String?,
    loading: () => null,
    error: (_, __) => null,
  );
});

// Notifier for authentication actions
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    AuthService.authStateChanges.listen((authState) {
      state = AsyncValue.data(authState.session?.user);
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final success = await AuthService.signInWithGoogle();
      if (!success) {
        throw Exception('Google Sign-In was cancelled or failed');
      }
      // The state will be updated automatically through the auth state listener
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await AuthService.signOut();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// Provider for auth notifier
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
      return AuthNotifier();
    });
