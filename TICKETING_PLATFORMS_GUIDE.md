# 🎫 Ticketing Platforms Configuration Guide

This guide explains how to add new ticketing platforms to the ticket identification system.

## 📁 File Location

The ticketing platform configuration is located in:
```
lib/config/ticketing_platforms.dart
```

## 🔧 How to Add New Platforms

### **Add Sender Email Patterns**

The system now uses **only sender email patterns** to identify ticketing platforms. Add new patterns to the `ticketSenderPatterns` list:

```dart
static const List<String> ticketSenderPatterns = [
  // Existing patterns...
  'hello@hustlesasa.com',
  'hello@mookh.africa',
  
  // Add your new platform sender patterns
  'noreply@yournewplatform.com',
  'tickets@yournewplatform.com',
  'support@yournewplatform.com',
];
```

## 🎯 How the Filtering Works

The system identifies tickets using **sender email patterns only**:

1. **Sender Pattern Matching**: Checks if the sender email contains any of the predefined patterns
2. **Case-insensitive matching**: Patterns are matched regardless of case
3. **Exact pattern matching**: Looks for the exact pattern within the sender email

### **Example:**
- Email from: `"John Doe <hello@hustlesasa.com>"`
- Pattern: `"hello@hustlesasa.com"`
- **Result**: ✅ **Ticket identified**

## 📋 Common Ticketing Platform Sender Patterns

Here are some popular platforms you might want to add:

### **Major Platforms**
- `noreply@eventbrite.com` - Eventbrite
- `tickets@ticketmaster.com` - Ticketmaster
- `noreply@seatgeek.com` - SeatGeek
- `support@stubhub.com` - StubHub
- `noreply@viagogo.com` - Viagogo
- `tickets@axs.com` - AXS
- `noreply@ticketfly.com` - Ticketfly
- `tickets@brownpapertickets.com` - Brown Paper Tickets

### **Regional Platforms**
- `noreply@dice.fm` - DICE (UK/Europe)
- `tickets@residentadvisor.net` - Resident Advisor
- `noreply@skiddle.com` - Skiddle (UK)
- `tickets@fatsoma.com` - Fatsoma (UK)

### **Specialized Platforms**
- `noreply@tixr.com` - TIXR
- `tickets@tickettailor.com` - Ticket Tailor
- `support@eventbee.com` - Eventbee
- `noreply@ticketleap.com` - TicketLeap

## 🔍 Testing Your Changes

After adding new sender patterns:

1. **Restart the app** to load the new configuration
2. **Refresh tickets** in the app to scan emails with the new patterns
3. **Check the results** to ensure tickets are being identified correctly

## 📝 Best Practices

### **Sender Pattern Selection**
- **Use exact email addresses** when possible (e.g., `noreply@platform.com`)
- **Include common variations** like `tickets@`, `support@`, `info@`
- **Test with real emails** to ensure patterns match correctly
- **Be specific** to avoid false positives

### **Pattern Examples**
```dart
// Good patterns (specific)
'noreply@eventbrite.com',
'tickets@ticketmaster.com',
'support@seatgeek.com',

// Avoid overly broad patterns
'@eventbrite',  // Too broad
'eventbrite',   // Too broad
```

## 🚀 Future Enhancements

The system is designed to be easily extensible. Future versions may include:

- **Persistent Storage**: Save custom sender patterns to device storage
- **User Interface**: Add/remove patterns through the app settings
- **Pattern Validation**: Validate patterns before adding them
- **Pattern Categories**: Group patterns by platform or region

## 📞 Support

If you need help adding new sender patterns or have suggestions for improvements, please refer to the main project documentation or create an issue in the project repository. 