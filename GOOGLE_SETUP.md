# Google Sign-In Setup Guide

This guide will help you set up Google Sign-In for your Flutter app using Supabase.

## Prerequisites

1. A Google Cloud Console project
2. Supabase project with Google OAuth enabled
3. Flutter app with the required dependencies

## Step 1: Google Cloud Console Setup

### 1.1 Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Google+ API and Gmail API

### 1.2 Configure OAuth Consent Screen

1. Go to "APIs & Services" > "OAuth consent screen"
2. Choose "External" user type
3. Fill in the required information:
   - App name: "Ticket Aggregator"
   - User support email: Your email
   - Developer contact information: Your email
4. Add scopes:
   - `email`
   - `profile`
   - `https://www.googleapis.com/auth/gmail.readonly`
   - `https://www.googleapis.com/auth/gmail.send`

### 1.3 Create OAuth 2.0 Credentials

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "OAuth 2.0 Client IDs"

#### For Web Application:
1. Choose "Web application"
2. Name: "Ticket Aggregator Web"
3. Authorized JavaScript origins:
   - `http://localhost:3000`
   - `https://your-supabase-project.supabase.co`
4. Authorized redirect URIs:
   - `http://localhost:3000/auth/callback`
   - `https://your-supabase-project.supabase.co/auth/v1/callback`
5. Copy the **Client ID** (you'll need this for `webClientId`)

#### For iOS Application:
1. Choose "iOS"
2. Name: "Ticket Aggregator iOS"
3. Bundle ID: `com.giglab.dwalt`
4. Copy the **Client ID** (you'll need this for `iosClientId`)

#### For Android Application (if needed):
1. Choose "Android"
2. Name: "Ticket Aggregator Android"
3. Package name: `com.giglab.dwalt`
4. SHA-1 certificate fingerprint: Your app's SHA-1 fingerprint
5. Copy the **Client ID** (you'll need this for `androidClientId`)

## Step 2: Update Configuration

### 2.1 Update Google Config

Open `lib/config/google_config.dart` and replace the placeholder values:

```dart
class GoogleConfig {
  // Replace these with your actual Google Cloud client IDs
  
  /// Web Client ID from Google Cloud Console
  static const String webClientId = 'your-web-client-id.apps.googleusercontent.com';
  
  /// iOS Client ID from Google Cloud Console
  static const String iosClientId = 'your-ios-client-id.apps.googleusercontent.com';
  
  /// Android Client ID (if needed)
  static const String androidClientId = 'your-android-client-id.apps.googleusercontent.com';
  
  /// Gmail API scopes
  static const List<String> gmailScopes = [
    'email',
    'profile',
    'https://www.googleapis.com/auth/gmail.readonly',
    'https://www.googleapis.com/auth/gmail.send',
  ];
}
```

### 2.2 Update Supabase Configuration

1. Go to your Supabase project dashboard
2. Navigate to "Authentication" > "Providers"
3. Enable Google provider
4. Add your Google OAuth credentials:
   - Client ID: Your web client ID
   - Client Secret: Your web client secret

## Step 3: Platform-Specific Configuration

### 3.1 iOS Configuration

1. Open `ios/Runner/Info.plist`
2. The following configuration should already be present:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.giglab.dwalt</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.giglab.dwalt</string>
        </array>
    </dict>
</array>
```

### 3.2 Android Configuration

1. Open `android/app/build.gradle.kts`
2. Ensure your `applicationId` is set to `com.giglab.dwalt`
3. The following should already be present in `android/app/src/main/AndroidManifest.xml`:

```xml
<activity>
    <!-- ... existing activity configuration ... -->
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="com.giglab.dwalt" />
    </intent-filter>
</activity>
```

## Step 4: Testing

1. Run your Flutter app
2. Navigate to the login page
3. Tap "Sign in with Google"
4. You should see the native Google Sign-In overlay
5. Complete the sign-in process

## Troubleshooting

### Common Issues:

1. **"No Access Token found"**: Check your Google Cloud Console configuration
2. **"No ID Token found"**: Ensure you've enabled the correct APIs
3. **Sign-in not working**: Verify your client IDs and bundle IDs match
4. **Gmail API not working**: Ensure you've enabled the Gmail API in Google Cloud Console

### 403 Access Denied Error

If you get a "403 access_denied" error saying "dwalt has not completed verification process and only testers can access the app":

#### Quick Fix (Add Test Users):
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to "APIs & Services" > "OAuth consent screen"
3. Scroll down to "Test users" section
4. Click "Add Users"
5. Add the email addresses of users who should be able to test the app
6. **Important**: Add your own email address that you're using to sign in
7. Click "Save" at the bottom of the page

#### Alternative Solutions:

**Option 1: Use Internal User Type (if available)**
- Change user type from "External" to "Internal" (only works with Google Workspace)
- This allows all users in your organization to access the app

**Option 2: Publish the App**
- Complete all required information in OAuth consent screen
- Submit for verification (can take several days)
- Once verified, the app will be available to all users

**Option 3: Complete App Verification**
- Fill in all required fields:
  - Privacy policy URL
  - Terms of service URL
  - App description
  - App logo
- Submit for verification

### Debug Steps:

1. Check the console logs for error messages
2. Verify your Google Cloud Console configuration
3. Ensure your Supabase project has Google OAuth enabled
4. Test with a different Google account
5. Make sure the test user email is added to the OAuth consent screen

## Security Notes

- Never commit your actual client IDs to version control
- Use environment variables or secure configuration management
- Regularly rotate your OAuth credentials
- Monitor your Google Cloud Console for any suspicious activity

## Additional Resources

- [Google Sign-In Flutter Plugin](https://pub.dev/packages/google_sign_in)
- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Google Cloud Console](https://console.cloud.google.com/)
- [Google OAuth 2.0 Documentation](https://developers.google.com/identity/protocols/oauth2) 