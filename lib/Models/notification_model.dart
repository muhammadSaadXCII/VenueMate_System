import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  NOTIFICATION TYPE
//  Each value maps to a specific event in the VenueMate system.
// ─────────────────────────────────────────────────────────────────────────────
enum NotificationType {
  // ── Booking lifecycle ──────────────────────────────────────────────────────
  bookingReceived,    // Hall admin ← customer submitted a booking
  bookingConfirmed,   // Customer ← hall admin confirmed the booking
  bookingRejected,    // Customer ← hall admin rejected the booking
  bookingCancelled,   // Hall admin ← customer cancelled the booking

  // ── Payment lifecycle ──────────────────────────────────────────────────────
  paymentUploaded,    // Hall admin ← customer uploaded payment receipt
  paymentApproved,    // Customer ← hall admin approved the payment
  paymentRejected,    // Customer ← hall admin rejected the payment
  refundProcessed,    // Customer ← hall admin processed a refund

  // ── Hall registration (System Admin flow) ─────────────────────────────────
  registrationSubmitted, // System admin ← venue owner submitted hall for review
  hallApproved,          // Venue owner ← system admin approved hall
  hallRejected,          // Venue owner ← system admin rejected hall
  hallDisabled,          // Venue owner ← system admin disabled hall
  hallEnabled,           // Venue owner ← system admin re-enabled hall

  // ── Messaging ──────────────────────────────────────────────────────────────
  newMessage,         // Any user ← received a chat message

  // ── Complaints ─────────────────────────────────────────────────────────────
  complaintFiled,     // System admin ← user filed a complaint
  complaintResolved,  // User ← system admin resolved the complaint

  // ── General / fallback ────────────────────────────────────────────────────
  general,
}

// ─────────────────────────────────────────────────────────────────────────────
//  HELPERS  –  convert enum ↔ Firestore string
// ─────────────────────────────────────────────────────────────────────────────
extension NotificationTypeX on NotificationType {
  /// The string stored in Firestore.
  String get value => name; // uses enum name, e.g. 'bookingConfirmed'

  /// Icon category used by the UI to pick the right icon/colour.
  String get category {
    switch (this) {
      case NotificationType.bookingReceived:
      case NotificationType.bookingConfirmed:
      case NotificationType.bookingRejected:
      case NotificationType.bookingCancelled:
        return 'booking';
      case NotificationType.paymentUploaded:
      case NotificationType.paymentApproved:
      case NotificationType.paymentRejected:
      case NotificationType.refundProcessed:
        return 'payment';
      case NotificationType.registrationSubmitted:
      case NotificationType.hallApproved:
      case NotificationType.hallRejected:
      case NotificationType.hallDisabled:
      case NotificationType.hallEnabled:
        return 'registration';
      case NotificationType.newMessage:
        return 'message';
      case NotificationType.complaintFiled:
      case NotificationType.complaintResolved:
        return 'complaint';
      case NotificationType.general:
        return 'general';
    }
  }
}

/// Parse a Firestore string back to the enum. Falls back to [NotificationType.general].
NotificationType notificationTypeFromString(String? value) {
  if (value == null) return NotificationType.general;
  return NotificationType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => NotificationType.general,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  NOTIFICATION MODEL
//  Maps to  notifications/{notificationId}  in Firestore.
// ─────────────────────────────────────────────────────────────────────────────

/// Represents a single notification document in Firestore.
///
/// Firestore path:  `notifications/{notificationId}`
///
/// Fields:
/// ```
/// notificationId  : String   – auto-generated doc ID
/// userId          : String   – recipient's UID
/// title           : String   – short heading shown in the notification card
/// body            : String   – detail text shown below the title
/// type            : String   – NotificationType.value  (e.g. 'bookingConfirmed')
/// referenceId     : String   – ID of the related document (bookingId, hallId…)
/// referenceType   : String   – 'booking' | 'hall' | 'payment' | 'complaint' | 'message'
/// isRead          : bool     – false until the user opens it
/// createdAt       : Timestamp
/// ```
class NotificationModel {
  final String notificationId;
  final String userId;       // recipient
  final String title;
  final String body;
  final NotificationType type;
  final String referenceId;   // related document ID (bookingId, hallId, etc.)
  final String referenceType; // 'booking' | 'hall' | 'payment' | 'complaint' | 'message'
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.referenceId = '',
    this.referenceType = '',
    this.isRead = false,
    required this.createdAt,
  });

  // ── Firestore → Model ──────────────────────────────────────────────────────
  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) {
    return NotificationModel(
      notificationId: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: notificationTypeFromString(map['type']),
      referenceId: map['referenceId'] ?? '',
      referenceType: map['referenceType'] ?? '',
      isRead: map['isRead'] ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory NotificationModel.fromDoc(DocumentSnapshot doc) {
    return NotificationModel.fromMap(
      doc.id,
      doc.data() as Map<String, dynamic>,
    );
  }

  // ── Model → Firestore ──────────────────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.value,
      'referenceId': referenceId,
      'referenceType': referenceType,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // ── Copy with updated fields ───────────────────────────────────────────────
  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      notificationId: notificationId,
      userId: userId,
      title: title,
      body: body,
      type: type,
      referenceId: referenceId,
      referenceType: referenceType,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  // ── Helper getters ─────────────────────────────────────────────────────────
  bool get isUnread => !isRead;

  /// Returns a human-readable relative time string, e.g. "2 mins ago".
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    // Older — show full date
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  /// Returns 'Today', 'Yesterday', or the date string for grouping in the UI.
  String get groupLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notifDay = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final diff = today.difference(notifDay).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}