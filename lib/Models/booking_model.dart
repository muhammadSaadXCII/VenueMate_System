import 'package:cloud_firestore/cloud_firestore.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  BOOKING MODEL  →  bookings/{bookingId}
// ══════════════════════════════════════════════════════════════════════════════

class BookingMenuItemModel {
  final String itemId;
  final String name;
  final double price;
  final String priceUnit;

  BookingMenuItemModel({
    required this.itemId,
    required this.name,
    required this.price,
    required this.priceUnit,
  });

  factory BookingMenuItemModel.fromMap(Map<String, dynamic> map) {
    return BookingMenuItemModel(
      itemId: map['itemId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      priceUnit: map['priceUnit'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'itemId': itemId,
    'name': name,
    'price': price,
    'priceUnit': priceUnit,
  };

  String get priceLabel => 'Rs. ${price.toStringAsFixed(0)}$priceUnit';
}

class BookingServiceModel {
  final String serviceId;
  final String name;
  final double price;

  BookingServiceModel({
    required this.serviceId,
    required this.name,
    required this.price,
  });

  factory BookingServiceModel.fromMap(Map<String, dynamic> map) {
    return BookingServiceModel(
      serviceId: map['serviceId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'serviceId': serviceId,
    'name': name,
    'price': price,
  };

  String get priceLabel => 'Rs. ${price.toStringAsFixed(0)}';
}

/// Maps to the `bookings/{bookingId}` Firestore document.
class BookingModel {
  final String bookingId;
  final String hallId;
  final String hallName;
  final String customerId;

  // ── Step 1 ─────────────────────────────────────────────────────────────────
  final String customerName;
  final String customerPhone;
  final String customerCnic;
  final String customerEmail;

  // ── Step 2 ─────────────────────────────────────────────────────────────────
  final String eventName;
  final int guestCount;
  final String timeSlot; // 'Morning' | 'Evening'
  final DateTime eventDate;

  // ── Step 3 ─────────────────────────────────────────────────────────────────
  final List<BookingMenuItemModel> selectedMenuItems;
  final List<BookingServiceModel> selectedServices;

  // ── Payment ────────────────────────────────────────────────────────────────
  final double hallRent;
  final double menuSubtotal;
  final double servicesSubtotal;
  final double grandTotal;
  final double advancePayment;
  final String receiptImageUrl;

  // ── Status ────────────────────────────────────────────────────────────────
  /// 'pending'   → waiting for hall admin to verify receipt
  /// 'confirmed' → hall admin approved, hall is booked
  /// 'rejected'  → hall admin rejected the receipt
  /// 'completed' → event date has passed
  /// 'cancelled' → cancelled by customer or admin
  final String status;
  final String rejectionReason;
  final String cancellationReason;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final DateTime createdAt;

  // ── Capacity snapshot ──────────────────────────────────────────────────────
  final int hallCapacityMax;

  // ── Refund fields ──────────────────────────────────────────────────────────
  /// Amount to be refunded (10% of advance if cancelled > 2 days before, 0 otherwise)
  final double refundAmount;

  /// 'partial_10' | 'no_refund' | 'none'
  final String refundPolicy;

  /// 'none' | 'pending_upload' | 'uploaded' | 'accepted' | 'rejected_by_customer'
  final String refundStatus;

  /// URL of the refund receipt uploaded by hall admin
  final String refundReceiptUrl;

  /// Reason given by customer when rejecting hall admin's refund receipt
  final String refundRejectionReason;

  BookingModel({
    required this.bookingId,
    required this.hallId,
    required this.hallName,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerCnic,
    required this.customerEmail,
    required this.eventName,
    required this.guestCount,
    required this.timeSlot,
    required this.eventDate,
    required this.selectedMenuItems,
    required this.selectedServices,
    required this.hallRent,
    required this.menuSubtotal,
    required this.servicesSubtotal,
    required this.grandTotal,
    required this.advancePayment,
    this.receiptImageUrl = '',
    this.status = 'pending',
    this.rejectionReason = '',
    this.cancellationReason = '',
    this.confirmedAt,
    this.cancelledAt,
    required this.createdAt,
    this.hallCapacityMax = 0,
    this.refundAmount = 0.0,
    this.refundPolicy = 'none',
    this.refundStatus = 'none',
    this.refundReceiptUrl = '',
    this.refundRejectionReason = '',
  });

  // ── Firestore → Model ──────────────────────────────────────────────────────
  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      bookingId: map['bookingId'] ?? '',
      hallId: map['hallId'] ?? '',
      hallName: map['hallName'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      customerCnic: map['customerCnic'] ?? '',
      customerEmail: map['customerEmail'] ?? '',
      eventName: map['eventName'] ?? '',
      guestCount: (map['guestCount'] ?? 0).toInt(),
      timeSlot: map['timeSlot'] ?? 'Morning',
      eventDate:
          map['eventDate'] != null
              ? (map['eventDate'] as Timestamp).toDate()
              : DateTime.now(),
      selectedMenuItems:
          (map['selectedMenuItems'] as List<dynamic>? ?? [])
              .map(
                (e) => BookingMenuItemModel.fromMap(e as Map<String, dynamic>),
              )
              .toList(),
      selectedServices:
          (map['selectedServices'] as List<dynamic>? ?? [])
              .map(
                (e) => BookingServiceModel.fromMap(e as Map<String, dynamic>),
              )
              .toList(),
      hallRent: (map['hallRent'] ?? 0).toDouble(),
      menuSubtotal: (map['menuSubtotal'] ?? 0).toDouble(),
      servicesSubtotal: (map['servicesSubtotal'] ?? 0).toDouble(),
      grandTotal: (map['grandTotal'] ?? 0).toDouble(),
      advancePayment: (map['advancePayment'] ?? 0).toDouble(),
      receiptImageUrl: map['receiptImageUrl'] ?? '',
      status: map['status'] ?? 'pending',
      rejectionReason: map['rejectionReason'] ?? '',
      cancellationReason: map['cancellationReason'] ?? '',
      confirmedAt:
          map['confirmedAt'] != null
              ? (map['confirmedAt'] as Timestamp).toDate()
              : null,
      cancelledAt:
          map['cancelledAt'] != null
              ? (map['cancelledAt'] as Timestamp).toDate()
              : null,
      createdAt:
          map['createdAt'] != null
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
      hallCapacityMax: (map['hallCapacityMax'] ?? 0).toInt(),
      refundAmount: (map['refundAmount'] ?? 0).toDouble(),
      refundPolicy: map['refundPolicy'] ?? 'none',
      refundStatus: map['refundStatus'] ?? 'none',
      refundReceiptUrl: map['refundReceiptUrl'] ?? '',
      refundRejectionReason: map['refundRejectionReason'] ?? '',
    );
  }

  factory BookingModel.fromDoc(DocumentSnapshot doc) =>
      BookingModel.fromMap(doc.data() as Map<String, dynamic>);

  // ── Model → Firestore ──────────────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
    'bookingId': bookingId,
    'hallId': hallId,
    'hallName': hallName,
    'customerId': customerId,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'customerCnic': customerCnic,
    'customerEmail': customerEmail,
    'eventName': eventName,
    'guestCount': guestCount,
    'timeSlot': timeSlot,
    'eventDate': Timestamp.fromDate(eventDate),
    'selectedMenuItems': selectedMenuItems.map((e) => e.toMap()).toList(),
    'selectedServices': selectedServices.map((e) => e.toMap()).toList(),
    'hallRent': hallRent,
    'menuSubtotal': menuSubtotal,
    'servicesSubtotal': servicesSubtotal,
    'grandTotal': grandTotal,
    'advancePayment': advancePayment,
    'receiptImageUrl': receiptImageUrl,
    'status': status,
    'rejectionReason': rejectionReason,
    'cancellationReason': cancellationReason,
    'confirmedAt':
        confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
    'cancelledAt':
        cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
    'createdAt': Timestamp.fromDate(createdAt),
    'hallCapacityMax': hallCapacityMax,
    'refundAmount': refundAmount,
    'refundPolicy': refundPolicy,
    'refundStatus': refundStatus,
    'refundReceiptUrl': refundReceiptUrl,
    'refundRejectionReason': refundRejectionReason,
  };

  // ── CopyWith ───────────────────────────────────────────────────────────────
  BookingModel copyWith({
    String? receiptImageUrl,
    String? status,
    String? rejectionReason,
    String? cancellationReason,
    DateTime? confirmedAt,
    DateTime? cancelledAt,
    double? refundAmount,
    String? refundPolicy,
    String? refundStatus,
    String? refundReceiptUrl,
    String? refundRejectionReason,
  }) {
    return BookingModel(
      bookingId: bookingId,
      hallId: hallId,
      hallName: hallName,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerCnic: customerCnic,
      customerEmail: customerEmail,
      eventName: eventName,
      guestCount: guestCount,
      timeSlot: timeSlot,
      eventDate: eventDate,
      selectedMenuItems: selectedMenuItems,
      selectedServices: selectedServices,
      hallRent: hallRent,
      menuSubtotal: menuSubtotal,
      servicesSubtotal: servicesSubtotal,
      grandTotal: grandTotal,
      advancePayment: advancePayment,
      receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      createdAt: createdAt,
      hallCapacityMax: hallCapacityMax,
      refundAmount: refundAmount ?? this.refundAmount,
      refundPolicy: refundPolicy ?? this.refundPolicy,
      refundStatus: refundStatus ?? this.refundStatus,
      refundReceiptUrl: refundReceiptUrl ?? this.refundReceiptUrl,
      refundRejectionReason:
          refundRejectionReason ?? this.refundRejectionReason,
    );
  }

  // ── Computed helpers ───────────────────────────────────────────────────────
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isRejected => status == 'rejected';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  bool get isUpcoming {
    if (!isConfirmed) return false;
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final evDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
    return !evDay.isBefore(today);
  }

  int get daysUntilEvent {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final evDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
    return evDay.difference(today).inDays;
  }

  double get remainingPayment => grandTotal - advancePayment;

  /// Whether a refund is applicable (10% of advance, cancelled > 2 days before)
  bool get hasRefundApplicable =>
      refundPolicy == 'partial_10' && refundAmount > 0;

  String get eventDateLabel {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${eventDate.day} ${months[eventDate.month - 1]}, ${eventDate.year} ($timeSlot)';
  }

  String get shortDateLabel {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${eventDate.day} ${months[eventDate.month - 1]}, ${eventDate.year}';
  }

  String get invoiceId => '#VM-${bookingId.substring(0, 6).toUpperCase()}';
}