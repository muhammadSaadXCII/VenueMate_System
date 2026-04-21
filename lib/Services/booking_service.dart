import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../Models/booking_model.dart';
import '../Models/menu_item_model.dart';
import '../Models/service_item_model.dart';
import 'storage_service.dart';

/// Handles all Firestore + Storage operations for the `bookings` collection.
///
/// REFUND POLICY:
///   Cancelled > 2 days before event  → refund 10% of advance (15% stays with hall admin)
///   Cancelled <= 2 days before event → NO refund
///
/// REFUND STATUS VALUES (stored on booking doc):
///   'none'                  → no refund applicable or not yet triggered
///   'pending_upload'        → refund applicable, hall admin must upload refund receipt
///   'uploaded'              → hall admin uploaded receipt, waiting for customer to verify
///   'accepted'              → customer accepted — refund complete
///   'rejected_by_customer'  → customer rejected, hall admin must re-upload
class BookingService {
  static final _db = FirebaseFirestore.instance;
  static final _bookings = _db.collection('bookings');
  static final _feedbacks = _db.collection('booking_feedbacks');
  static const _uuid = Uuid();

  // ════════════════════════════════════════════════════════════════════════════
  //  AVAILABILITY CHECK
  // ════════════════════════════════════════════════════════════════════════════

  static Future<SlotAvailability> checkSlotAvailability({
    required String hallId,
    required DateTime date,
    required String timeSlot,
    required int hallCapacityMax,
  }) async {
    try {
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final snap =
          await _bookings
              .where('hallId', isEqualTo: hallId)
              .where('timeSlot', isEqualTo: timeSlot)
              .where('status', isEqualTo: 'confirmed')
              .where(
                'eventDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart),
              )
              .where('eventDate', isLessThan: Timestamp.fromDate(dayEnd))
              .get();

      final bookedGuests = snap.docs
          .map((d) => (d.data()['guestCount'] as num? ?? 0).toInt())
          .fold(0, (a, b) => a + b);

      final remaining = hallCapacityMax - bookedGuests;
      return SlotAvailability(
        hallCapacityMax: hallCapacityMax,
        bookedGuests: bookedGuests,
        remainingSlots: remaining.clamp(0, hallCapacityMax),
        isFullyBooked: remaining <= 0,
      );
    } catch (_) {
      return SlotAvailability(
        hallCapacityMax: hallCapacityMax,
        bookedGuests: 0,
        remainingSlots: hallCapacityMax,
        isFullyBooked: false,
      );
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  CREATE
  // ════════════════════════════════════════════════════════════════════════════

  static Future<String?> createBooking({
    required String hallId,
    required String hallName,
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String customerCnic,
    required String customerEmail,
    required String eventName,
    required int guestCount,
    required String timeSlot,
    required DateTime eventDate,
    required List<MenuItemModel> selectedMenuItems,
    required List<ServiceItemModel> selectedServices,
    required double hallRent,
    required int hallCapacityMax,
    required File receiptFile,
  }) async {
    // 1. Re-check availability
    final avail = await checkSlotAvailability(
      hallId: hallId,
      date: eventDate,
      timeSlot: timeSlot,
      hallCapacityMax: hallCapacityMax,
    );
    if (guestCount > avail.remainingSlots) return 'SLOT_FULL';

    // 2. Upload receipt image to Firebase Storage
    final String bookingId = _uuid.v4();
    final String? receiptUrl = await StorageService.uploadPaymentReceipt(
      bookingId: bookingId,
      receiptFile: receiptFile,
    );

    if (receiptUrl == null) {
      throw Exception(
        'Receipt upload failed.\n\n'
        'Possible causes:\n'
        '• Firebase Storage rules are blocking the upload\n'
        '• No internet connection\n'
        '• Android API key is empty in main.dart\n\n'
        'Check Firebase Storage Rules — they must allow authenticated writes:\n'
        '  allow write: if request.auth != null;',
      );
    }

    // 3. Compute totals
    final double menuSubtotal = selectedMenuItems.fold(
      0.0,
      (s, m) => s + m.price,
    );
    final double servicesSubtotal = selectedServices.fold(
      0.0,
      (s, sv) => s + sv.price,
    );
    final double grandTotal = hallRent + menuSubtotal + servicesSubtotal;
    final double advancePayment = grandTotal * 0.25;

    // 4. Build model
    final booking = BookingModel(
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
      selectedMenuItems:
          selectedMenuItems
              .map(
                (m) => BookingMenuItemModel(
                  itemId: m.itemId,
                  name: m.name,
                  price: m.price,
                  priceUnit: m.priceUnit,
                ),
              )
              .toList(),
      selectedServices:
          selectedServices
              .map(
                (s) => BookingServiceModel(
                  serviceId: s.serviceId,
                  name: s.name,
                  price: s.price,
                ),
              )
              .toList(),
      hallRent: hallRent,
      menuSubtotal: menuSubtotal,
      servicesSubtotal: servicesSubtotal,
      grandTotal: grandTotal,
      advancePayment: advancePayment,
      receiptImageUrl: receiptUrl,
      status: 'pending',
      createdAt: DateTime.now(),
      hallCapacityMax: hallCapacityMax,
    );

    // 5. Save to Firestore
    await _bookings.doc(bookingId).set(booking.toMap());
    return bookingId;
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  READ — Customer
  // ════════════════════════════════════════════════════════════════════════════

  static Stream<List<BookingModel>> streamCustomerBookings(String customerId) {
    return _bookings
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => BookingModel.fromDoc(d)).toList());
  }

  /// Stream customer bookings filtered by a single status.
  static Stream<List<BookingModel>> streamCustomerBookingsByStatus(
    String customerId,
    String status,
  ) {
    return _bookings
        .where('customerId', isEqualTo: customerId)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => BookingModel.fromDoc(d)).toList());
  }

  /// Stream customer PENDING tab — includes both 'pending' and 'rejected'
  static Stream<List<BookingModel>> streamCustomerPendingAndRejected(
    String customerId,
  ) {
    final pendingStream = _bookings
        .where('customerId', isEqualTo: customerId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => BookingModel.fromDoc(d)).toList());

    final rejectedStream = _bookings
        .where('customerId', isEqualTo: customerId)
        .where('status', isEqualTo: 'rejected')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => BookingModel.fromDoc(d)).toList());

    return _combineLatest2(pendingStream, rejectedStream, (a, b) {
      final merged = [...a, ...b];
      merged.sort((x, y) => y.createdAt.compareTo(x.createdAt));
      return merged;
    });
  }

  /// Stream customer cancelled bookings — only 'cancelled' status.
  /// (rejected-receipt bookings appear in pending tab, not here)
  static Stream<List<BookingModel>> streamCustomerCancelledBookings(
    String customerId,
  ) {
    return _bookings
        .where('customerId', isEqualTo: customerId)
        .where('status', isEqualTo: 'cancelled')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => BookingModel.fromDoc(d)).toList());
  }

  static Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      final doc = await _bookings.doc(bookingId).get();
      if (!doc.exists) return null;
      return BookingModel.fromDoc(doc);
    } catch (_) {
      return null;
    }
  }

  static Stream<BookingModel?> streamBookingById(String bookingId) {
    return _bookings.doc(bookingId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return BookingModel.fromDoc(doc);
    });
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  READ — Hall Admin
  // ════════════════════════════════════════════════════════════════════════════

  static Stream<List<BookingModel>> streamHallBookings(String hallId) {
    return _bookings
        .where('hallId', isEqualTo: hallId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => BookingModel.fromDoc(d)).toList());
  }

  static Stream<List<BookingModel>> streamPendingBookings(String hallId) {
    return _bookings
        .where('hallId', isEqualTo: hallId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map((d) => BookingModel.fromDoc(d)).toList());
  }

  static Stream<List<BookingModel>> streamUpcomingBookings(String hallId) {
    return _bookings
        .where('hallId', isEqualTo: hallId)
        .where('status', isEqualTo: 'confirmed')
        .snapshots()
        .map((snap) => snap.docs.map((d) => BookingModel.fromDoc(d)).toList());
  }

  static Stream<List<BookingModel>> streamCompletedBookings(String hallId) {
    return _bookings
        .where('hallId', isEqualTo: hallId)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snap) => snap.docs.map((d) => BookingModel.fromDoc(d)).toList());
  }

  /// Hall Admin Cancelled tab shows BOTH 'cancelled' and 'rejected' bookings.
  static Stream<List<BookingModel>> streamCancelledBookings(String hallId) {
    final cancelledStream = _bookings
        .where('hallId', isEqualTo: hallId)
        .where('status', isEqualTo: 'cancelled')
        .snapshots()
        .map((snap) => snap.docs.map((d) => BookingModel.fromDoc(d)).toList());

    final rejectedStream = _bookings
        .where('hallId', isEqualTo: hallId)
        .where('status', isEqualTo: 'rejected')
        .snapshots()
        .map((snap) => snap.docs.map((d) => BookingModel.fromDoc(d)).toList());

    return _combineLatest2(cancelledStream, rejectedStream, (a, b) {
      final merged = [...a, ...b];
      merged.sort((x, y) => y.createdAt.compareTo(x.createdAt));
      return merged;
    });
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  UPDATE — Hall Admin actions
  // ════════════════════════════════════════════════════════════════════════════

  static Future<String?> confirmBooking(String bookingId) async {
    try {
      await _bookings.doc(bookingId).update({
        'status': 'confirmed',
        'rejectionReason': '',
        'confirmedAt': Timestamp.fromDate(DateTime.now()),
      });
      return null;
    } catch (e) {
      return 'Failed to confirm booking: $e';
    }
  }

  static Future<String?> markBookingAsCompleted(String bookingId) async {
    try {
      await _bookings.doc(bookingId).update({
        'status': 'completed',
        'completedAt': Timestamp.fromDate(DateTime.now()),
      });
      return null;
    } catch (e) {
      return 'Failed to mark as completed: $e';
    }
  }

  static Future<String?> rejectBookingPayment({
    required String bookingId,
    required String reason,
  }) async {
    try {
      await _bookings.doc(bookingId).update({
        'status': 'rejected',
        'rejectionReason': reason,
      });
      return null;
    } catch (e) {
      return 'Failed to reject booking: $e';
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  UPDATE — Customer cancel
  // ════════════════════════════════════════════════════════════════════════════

  /// Cancel a confirmed booking with automatic refund policy calculation.
  ///
  /// Policy:
  ///   days until event > 2  → refund 10% of advance ('partial_10')
  ///   days until event <= 2 → no refund ('no_refund')
  ///
  /// If refundAmount > 0, sets refundStatus = 'pending_upload' so hall admin
  /// knows they must upload a refund receipt.
  static Future<String?> cancelBookingWithRefund(
    String bookingId, {
    required String reason,
    required double advancePayment,
    required DateTime eventDate,
  }) async {
    try {
      final today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      final evDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
      final daysLeft = evDay.difference(today).inDays;

      double refundAmount = 0.0;
      String refundPolicy = 'no_refund';
      String refundStatus = 'none';

      if (daysLeft > 2) {
        // 10% of advance is refunded to customer; hall admin keeps 15%
        refundAmount = advancePayment * 0.10 / 0.25;
        // advancePayment = grandTotal * 0.25
        // 10% of grandTotal * 0.25 = grandTotal * 0.025
        // Simpler: refund = (10/25) * advancePayment = 0.4 * advancePayment
        refundAmount = advancePayment * 0.4; // 10% of total = 40% of advance
        refundPolicy = 'partial_10';
        refundStatus = 'pending_upload';
      }

      await _bookings.doc(bookingId).update({
        'status': 'cancelled',
        'cancellationReason': reason,
        'cancelledAt': Timestamp.fromDate(DateTime.now()),
        'refundAmount': refundAmount,
        'refundPolicy': refundPolicy,
        'refundStatus': refundStatus,
        'refundReceiptUrl': '',
        'refundRejectionReason': '',
      });
      return null;
    } catch (e) {
      return 'Failed to cancel booking: $e';
    }
  }

  /// Legacy cancel (for non-confirmed bookings if needed).
  static Future<String?> cancelBooking(
    String bookingId, {
    String reason = '',
  }) async {
    try {
      await _bookings.doc(bookingId).update({
        'status': 'cancelled',
        'cancellationReason': reason,
        'cancelledAt': Timestamp.fromDate(DateTime.now()),
      });
      return null;
    } catch (e) {
      return 'Failed to cancel booking: $e';
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  RESUBMIT RECEIPT (customer re-upload after rejection)
  // ════════════════════════════════════════════════════════════════════════════

  static Future<String?> resubmitReceipt({
    required String bookingId,
    required File newReceiptFile,
  }) async {
    try {
      final String? newUrl = await StorageService.uploadPaymentReceipt(
        bookingId: bookingId,
        receiptFile: newReceiptFile,
      );
      if (newUrl == null) return 'Failed to upload receipt image.';

      await _bookings.doc(bookingId).update({
        'receiptImageUrl': newUrl,
        'status': 'pending',
        'rejectionReason': '',
        'resubmittedAt': Timestamp.fromDate(DateTime.now()),
      });
      return null;
    } catch (e) {
      return 'Failed to resubmit receipt: $e';
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  REFUND FLOW — Hall Admin uploads, Customer verifies
  // ════════════════════════════════════════════════════════════════════════════

  /// Hall admin uploads a refund receipt image to Storage, then updates Firestore.
  /// Sets refundStatus = 'uploaded'.
  static Future<String?> uploadRefundReceipt({
    required String bookingId,
    required File receiptFile,
  }) async {
    try {
      final String? url = await StorageService.uploadRefundReceipt(
        bookingId: bookingId,
        receiptFile: receiptFile,
      );
      if (url == null) return 'Failed to upload refund receipt image.';

      await _bookings.doc(bookingId).update({
        'refundReceiptUrl': url,
        'refundStatus': 'uploaded',
        'refundRejectionReason': '',
        'refundUploadedAt': Timestamp.fromDate(DateTime.now()),
      });
      return null;
    } catch (e) {
      return 'Failed to upload refund receipt: $e';
    }
  }

  /// Web-safe variant: bytes instead of dart:io File.
  /// Works identically on mobile — preferred for new code.
  static Future<String?> uploadRefundReceiptBytes({
    required String bookingId,
    required Uint8List receiptBytes,
    String fileName = 'refund_receipt.jpg',
  }) async {
    try {
      final String? url = await StorageService.uploadRefundReceiptBytes(
        bookingId: bookingId,
        receiptBytes: receiptBytes,
        fileName: fileName,
      );
      if (url == null) return 'Failed to upload refund receipt image.';

      await _bookings.doc(bookingId).update({
        'refundReceiptUrl': url,
        'refundStatus': 'uploaded',
        'refundRejectionReason': '',
        'refundUploadedAt': Timestamp.fromDate(DateTime.now()),
      });
      return null;
    } catch (e) {
      return 'Failed to upload refund receipt: $e';
    }
  }

  /// Customer accepts the refund receipt — marks refund as complete.
  static Future<String?> acceptRefund(String bookingId) async {
    try {
      await _bookings.doc(bookingId).update({
        'refundStatus': 'accepted',
        'refundAcceptedAt': Timestamp.fromDate(DateTime.now()),
      });
      return null;
    } catch (e) {
      return 'Failed to accept refund: $e';
    }
  }

  /// Customer rejects the refund receipt with a reason.
  /// Sets refundStatus = 'rejected_by_customer' so hall admin must re-upload.
  static Future<String?> rejectRefund({
    required String bookingId,
    required String reason,
  }) async {
    try {
      await _bookings.doc(bookingId).update({
        'refundStatus': 'rejected_by_customer',
        'refundRejectionReason': reason,
        'refundReceiptUrl': '',
        'refundRejectedAt': Timestamp.fromDate(DateTime.now()),
      });
      return null;
    } catch (e) {
      return 'Failed to reject refund: $e';
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  FEEDBACK — Customer submits, Hall Admin views
  // ════════════════════════════════════════════════════════════════════════════

  static Future<String?> submitFeedback({
    required String bookingId,
    required String hallId,
    required String customerId,
    required String customerName,
    required String hallName,
    required int rating,
    required String reviewText,
  }) async {
    try {
      final feedbackId = _uuid.v4();
      final hallRef = _db.collection('halls').doc(hallId);

      // Read the hall rating BEFORE any writes (outside transaction/batch)
      // so we can compute the new rolling average cleanly.
      final hallSnap = await hallRef.get();
      final data = hallSnap.data() ?? {};
      final ratingMap = (data['rating'] as Map<String, dynamic>?) ?? {};
      final oldCount = (ratingMap['count'] as num? ?? 0).toInt();
      final oldAvg = (ratingMap['avg'] as num? ?? 0).toDouble();

      // Compute new rolling average and incremented count.
      final newCount = oldCount + 1;
      final newAvg = ((oldAvg * oldCount) + rating) / newCount;

      // Use a WriteBatch (writes only — no reads) for atomic commit.
      final batch = _db.batch();

      batch.set(_feedbacks.doc(bookingId), {
        'feedbackId': feedbackId,
        'bookingId': bookingId,
        'hallId': hallId,
        'customerId': customerId,
        'customerName': customerName,
        'hallName': hallName,
        'rating': rating,
        'reviewText': reviewText,
        'submittedAt': Timestamp.fromDate(DateTime.now()),
      });

      batch.update(hallRef, {
        'rating': {
          'count': newCount,
          'avg': double.parse(newAvg.toStringAsFixed(2)),
        },
      });

      await batch.commit();

      return null;
    } catch (e) {
      return 'Failed to submit feedback: $e';
    }
  }

  static Future<bool> hasFeedback(String bookingId) async {
    try {
      final doc = await _feedbacks.doc(bookingId).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  static Stream<Map<String, dynamic>?> streamFeedbackForBooking(
    String bookingId,
  ) {
    return _feedbacks.doc(bookingId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return doc.data();
    });
  }

  static Stream<List<Map<String, dynamic>>> streamHallFeedbacks(String hallId) {
    return _feedbacks
        .where('hallId', isEqualTo: hallId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  COUNTS
  // ════════════════════════════════════════════════════════════════════════════

  static Future<Map<String, int>> getBookingCounts(String hallId) async {
    try {
      final snap = await _bookings.where('hallId', isEqualTo: hallId).get();
      final all = snap.docs.map((d) => BookingModel.fromDoc(d)).toList();

      return {
        'pending': all.where((b) => b.isPending).length,
        'upcoming': all.where((b) => b.isConfirmed).length,
        'completed': all.where((b) => b.isCompleted).length,
        'cancelled': all.where((b) => b.isCancelled || b.isRejected).length,
      };
    } catch (_) {
      return {'pending': 0, 'upcoming': 0, 'completed': 0, 'cancelled': 0};
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  INTERNAL HELPERS
  // ════════════════════════════════════════════════════════════════════════════

  static Stream<T> _combineLatest2<A, B, T>(
    Stream<A> streamA,
    Stream<B> streamB,
    T Function(A, B) combiner,
  ) {
    A? latestA;
    B? latestB;
    StreamSubscription<A>? subA;
    StreamSubscription<B>? subB;
    StreamController<T>? controller;

    controller = StreamController<T>.broadcast(
      onListen: () {
        subA = streamA.listen((a) {
          latestA = a;
          if (latestB != null) {
            controller!.add(combiner(latestA as A, latestB as B));
          }
        }, onError: (e) => controller!.addError(e));
        subB = streamB.listen((b) {
          latestB = b;
          if (latestA != null) {
            controller!.add(combiner(latestA as A, latestB as B));
          }
        }, onError: (e) => controller!.addError(e));
      },
      onCancel: () {
        subA?.cancel();
        subB?.cancel();
        subA = null;
        subB = null;
        latestA = null;
        latestB = null;
      },
    );
    return controller.stream;
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SLOT AVAILABILITY
// ══════════════════════════════════════════════════════════════════════════════

class SlotAvailability {
  final int hallCapacityMax;
  final int bookedGuests;
  final int remainingSlots;
  final bool isFullyBooked;

  const SlotAvailability({
    required this.hallCapacityMax,
    required this.bookedGuests,
    required this.remainingSlots,
    required this.isFullyBooked,
  });

  String get label =>
      isFullyBooked
          ? 'Fully Booked'
          : '$remainingSlots / $hallCapacityMax guests available';
}
