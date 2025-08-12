/// Configuration for ticketing platform identification
/// This file contains keywords and patterns used to identify emails from various ticketing platforms
class TicketingPlatforms {
  /// Email sender patterns that indicate ticketing platforms
  static const List<String> ticketSenderPatterns = [
    'hello@hustlesasa.com',
    'hello@mookh.africa',
  ];

  /// Check if an email is from a ticketing platform
  static bool isFromTicketingPlatform({
    required String subject,
    required String sender,
    required String body,
  }) {
    final lowerSender = sender.toLowerCase();
    print(
      '🔍 Checking sender: "$lowerSender" against patterns: $ticketSenderPatterns',
    );

    // Check sender patterns only
    for (final pattern in ticketSenderPatterns) {
      if (lowerSender.contains(pattern.toLowerCase())) {
        print('✅ Matched pattern: "$pattern"');
        return true;
      }
    }

    print('❌ No pattern match found');
    return false;
  }

  /// Get the identified platform from an email
  static String? getIdentifiedPlatform({
    required String subject,
    required String sender,
    required String body,
  }) {
    final lowerSender = sender.toLowerCase();

    // Check sender patterns and return the first match
    for (final pattern in ticketSenderPatterns) {
      if (lowerSender.contains(pattern.toLowerCase())) {
        return pattern;
      }
    }

    return null;
  }

  /// Add a new platform sender pattern
  static void addPlatformSenderPattern(String pattern) {
    // Note: This would need to be implemented with persistent storage
    // For now, this is a placeholder for future implementation
    print('Adding platform sender pattern: $pattern');
  }
}
