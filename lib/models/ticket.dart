import '../config/ticketing_platforms.dart';

/// Model representing a ticket identified from an email
class Ticket {
  final String id;
  final String emailId;
  final String subject;
  final String sender;
  final String? platform;
  final DateTime receivedDate;
  final DateTime? eventDate;
  final String? eventName;
  final String? eventLocation;
  final String? ticketType;
  final String? ticketQuantity;
  final String? ticketPrice;
  final String? orderNumber;
  final String? confirmationCode;
  final String? qrCode;
  final String? barcode;
  final TicketStatus status;
  final Map<String, dynamic>? metadata;

  const Ticket({
    required this.id,
    required this.emailId,
    required this.subject,
    required this.sender,
    this.platform,
    required this.receivedDate,
    this.eventDate,
    this.eventName,
    this.eventLocation,
    this.ticketType,
    this.ticketQuantity,
    this.ticketPrice,
    this.orderNumber,
    this.confirmationCode,
    this.qrCode,
    this.barcode,
    this.status = TicketStatus.active,
    this.metadata,
  });

  /// Create a Ticket from a Gmail message
  factory Ticket.fromGmailMessage({
    required String emailId,
    required String subject,
    required String sender,
    required DateTime receivedDate,
    required String body,
  }) {
    final platform = TicketingPlatforms.getIdentifiedPlatform(
      subject: subject,
      sender: sender,
      body: body,
    );

    return Ticket(
      id: emailId, // Use email ID as ticket ID for now
      emailId: emailId,
      subject: subject,
      sender: sender,
      platform: platform,
      receivedDate: receivedDate,
      status: TicketStatus.active,
    );
  }

  /// Create a copy of this ticket with updated fields
  Ticket copyWith({
    String? id,
    String? emailId,
    String? subject,
    String? sender,
    String? platform,
    DateTime? receivedDate,
    DateTime? eventDate,
    String? eventName,
    String? eventLocation,
    String? ticketType,
    String? ticketQuantity,
    String? ticketPrice,
    String? orderNumber,
    String? confirmationCode,
    String? qrCode,
    String? barcode,
    TicketStatus? status,
    Map<String, dynamic>? metadata,
  }) {
    return Ticket(
      id: id ?? this.id,
      emailId: emailId ?? this.emailId,
      subject: subject ?? this.subject,
      sender: sender ?? this.sender,
      platform: platform ?? this.platform,
      receivedDate: receivedDate ?? this.receivedDate,
      eventDate: eventDate ?? this.eventDate,
      eventName: eventName ?? this.eventName,
      eventLocation: eventLocation ?? this.eventLocation,
      ticketType: ticketType ?? this.ticketType,
      ticketQuantity: ticketQuantity ?? this.ticketQuantity,
      ticketPrice: ticketPrice ?? this.ticketPrice,
      orderNumber: orderNumber ?? this.orderNumber,
      confirmationCode: confirmationCode ?? this.confirmationCode,
      qrCode: qrCode ?? this.qrCode,
      barcode: barcode ?? this.barcode,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'emailId': emailId,
      'subject': subject,
      'sender': sender,
      'platform': platform,
      'receivedDate': receivedDate.toIso8601String(),
      'eventDate': eventDate?.toIso8601String(),
      'eventName': eventName,
      'eventLocation': eventLocation,
      'ticketType': ticketType,
      'ticketQuantity': ticketQuantity,
      'ticketPrice': ticketPrice,
      'orderNumber': orderNumber,
      'confirmationCode': confirmationCode,
      'qrCode': qrCode,
      'barcode': barcode,
      'status': status.name,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as String,
      emailId: json['emailId'] as String,
      subject: json['subject'] as String,
      sender: json['sender'] as String,
      platform: json['platform'] as String?,
      receivedDate: DateTime.parse(json['receivedDate'] as String),
      eventDate: json['eventDate'] != null
          ? DateTime.parse(json['eventDate'] as String)
          : null,
      eventName: json['eventName'] as String?,
      eventLocation: json['eventLocation'] as String?,
      ticketType: json['ticketType'] as String?,
      ticketQuantity: json['ticketQuantity'] as String?,
      ticketPrice: json['ticketPrice'] as String?,
      orderNumber: json['orderNumber'] as String?,
      confirmationCode: json['confirmationCode'] as String?,
      qrCode: json['qrCode'] as String?,
      barcode: json['barcode'] as String?,
      status: TicketStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TicketStatus.active,
      ),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() {
    return 'Ticket(id: $id, platform: $platform, eventName: $eventName, eventDate: $eventDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Ticket && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Status of a ticket
enum TicketStatus {
  active, // Ticket is valid and active
  used, // Ticket has been used
  expired, // Event has passed
  cancelled, // Ticket was cancelled
  pending, // Ticket is pending confirmation
}

/// Extension to add helper methods to TicketStatus
extension TicketStatusExtension on TicketStatus {
  String get displayName {
    switch (this) {
      case TicketStatus.active:
        return 'Active';
      case TicketStatus.used:
        return 'Used';
      case TicketStatus.expired:
        return 'Expired';
      case TicketStatus.cancelled:
        return 'Cancelled';
      case TicketStatus.pending:
        return 'Pending';
    }
  }

  bool get isActive =>
      this == TicketStatus.active || this == TicketStatus.pending;
  bool get isExpired =>
      this == TicketStatus.expired || this == TicketStatus.used;
}
