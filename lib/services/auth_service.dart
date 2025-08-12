import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/google_config.dart';
import 'gmail_service.dart';

class AuthService {
  static SupabaseClient get client => Supabase.instance.client;
  static String? _googleAccessToken;
  static const String _googleTokenKey = 'google_access_token';

  /// Sign in with Google using native Google Sign-In
  static Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: GoogleConfig.iosClientId,
        serverClientId: GoogleConfig.webClientId,
        scopes: GoogleConfig.gmailScopes,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign-In was cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw Exception('No Access Token found.');
      }
      if (idToken == null) {
        throw Exception('No ID Token found.');
      }

      // Store the Google access token for Gmail API
      await _storeGoogleAccessToken(accessToken);

      await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      return true;
    } catch (e) {
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  /// Sign out from Supabase and Google
  static Future<void> signOut() async {
    try {
      // Sign out from Supabase
      await client.auth.signOut();

      // Sign out from Google
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      // Clear stored Google access token
      await _clearGoogleAccessToken();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  /// Store Google access token in shared preferences
  static Future<void> _storeGoogleAccessToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_googleTokenKey, token);
      _googleAccessToken = token;
      print('✅ Google access token stored successfully');
    } catch (e) {
      print('❌ Failed to store Google access token: $e');
    }
  }

  /// Retrieve Google access token from shared preferences
  static Future<String?> _retrieveGoogleAccessToken() async {
    try {
      if (_googleAccessToken != null) {
        return _googleAccessToken;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_googleTokenKey);
      if (token != null) {
        _googleAccessToken = token;
        print('✅ Google access token retrieved from storage');
      } else {
        print('❌ No Google access token found in storage');
      }
      return token;
    } catch (e) {
      print('❌ Failed to retrieve Google access token: $e');
      return null;
    }
  }

  /// Clear Google access token from shared preferences
  static Future<void> _clearGoogleAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_googleTokenKey);
      _googleAccessToken = null;
      print('✅ Google access token cleared');
    } catch (e) {
      print('❌ Failed to clear Google access token: $e');
    }
  }

  /// Get current user from Supabase
  static User? get currentUser => client.auth.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Get user's access token for Gmail API (Google access token)
  static Future<String?> get accessToken async =>
      await _retrieveGoogleAccessToken();

  /// Check if Google access token is valid and refresh if needed
  static Future<bool> isGoogleTokenValid() async {
    try {
      final token = await accessToken;
      if (token == null) {
        print('❌ No Google access token found');
        return false;
      }

      // Try to use the token to make a simple Gmail API call
      // This will tell us if the token is still valid
      await GmailService.initialize();

      // Try to get the user's profile to test the token
      final profile = await GmailService.getProfile();
      if (profile != null) {
        print('✅ Google access token is valid');
        return true;
      } else {
        print('❌ Google access token is invalid');
        return false;
      }
    } catch (e) {
      print('❌ Error checking Google token validity: $e');
      return false;
    }
  }

  /// Refresh Google access token if needed
  static Future<bool> refreshGoogleToken() async {
    try {
      print('🔄 Attempting to refresh Google access token...');

      // Try to get a fresh token from Google Sign-In
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: GoogleConfig.iosClientId,
        serverClientId: GoogleConfig.webClientId,
        scopes: GoogleConfig.gmailScopes,
      );

      // Check if user is already signed in
      final currentUser = googleSignIn.currentUser;
      if (currentUser != null) {
        final googleAuth = await currentUser.authentication;
        if (googleAuth.accessToken != null) {
          await _storeGoogleAccessToken(googleAuth.accessToken!);
          print('✅ Google access token refreshed successfully');
          return true;
        }
      }

      print('❌ No current Google user found, need to sign in again');
      return false;
    } catch (e) {
      print('❌ Failed to refresh Google access token: $e');
      return false;
    }
  }

  /// Get Supabase access token
  static String? get supabaseAccessToken {
    final session = client.auth.currentSession;
    return session?.accessToken;
  }

  /// Stream of auth state changes
  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  /// Get user's email
  static String? get userEmail => currentUser?.email;

  /// Get user's display name
  static String? get userDisplayName =>
      currentUser?.userMetadata?['full_name'] as String?;

  /// Get user's avatar URL
  static String? get userAvatarUrl =>
      currentUser?.userMetadata?['avatar_url'] as String?;
}
