/// Google configuration constants
class GoogleConfig {
  // TODO: Replace these with your actual Google Cloud client IDs

  /// Web Client ID from Google Cloud Console
  /// Format: 'your-project-id.apps.googleusercontent.com'
  static const String webClientId =
      '355719794786-9o6600nsj2nfv1kfodc6s2j5gj8dvg9k.apps.googleusercontent.com';


  static const String iosClientId =
      'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com';

  static const String androidClientId =
      '355719794786-1qkksbv0701ouis6efdaj003anoqpcma.apps.googleusercontent.com';

  /// Gmail API scopes
  static const List<String> gmailScopes = [
    'email',
    'profile',
    'https://www.googleapis.com/auth/gmail.readonly',
    'https://www.googleapis.com/auth/gmail.send',
  ];
}
