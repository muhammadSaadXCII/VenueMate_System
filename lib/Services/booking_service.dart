import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../Models/booking_model.dart';
import '../Models/menu_item_model.dart';
import '../Models/service_item_model.dart';
import 'storage_service.dart';

/// Handles all Firestore + Storage operations for the `bookings` collection.
///
/// KEY RULES enforced here:
///   1. Each slot (Morning / Evening) is checked independently for the date.
///   2. A slot's remaining capacity = hallCapacityMax − sum of confirmed
///      guestCounts for that hallId + date + slot.
///   3. A new booking is rejected if guestCount > remainingCapacity.
///   4. When hall admin confirms → status = 'confirmed', confirmedAt = now.
///   5. When hall admin rejects → status = 'rejected'.
///   6. Bookings whose eventDate < today AND status == 'confirmed' are
///      auto-marked 'completed' lazily on fetch.
///
/// STATUS VALUES:
///   'pending'   → customer submitted receipt, waiting for hall admin to verify
///   'confirmed' → hall admin approved → shows in Upcoming on both sides
///   'rejected'  → hall admin rejected receipt → shows in Cancelled on both sides
///   'completed' → event date has passed (auto from confirmed)
///   'cancelled' → cancelled by customer → shows in Cancelled on both sides
class BookingService {
  static final _db = FirebaseFirestore.instance;
  static final _bookings = _db.collection('bookings');
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
        .map(
          (snap) =>
              snap.docs
                  .map((d) => BookingModel.fromDoc(d))
                  .map(_autoComplete)
                  .toList(),
        );
  }

  /// Stream customer bookings filtered by a single status.
  /// Used for: 'pending', 'confirmed', 'completed' tabs.
  static Stream<List<BookingModel>> streamCustomerBookingsByStatus(
    String customerId,
    String status,
  ) {
    return _bookings
        .where('customerId', isEqualTo: customerId)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((d) => BookingModel.fromDoc(d))
                  .map(_autoComplete)
                  .toList(),
        );
  }

  /// FIX: Stream customer bookings for the Cancelled tab.
  /// Combines both 'cancelled' (customer-cancelled) and 'rejected'
  /// (hall admin rejected receipt) bookings — both show in Cancelled tab.
  static Stream<List<BookingModel>> streamCustomerCancelledBookings(
    String customerId,
  ) {
    // Firestore does not support OR queries on different field values in a
    // single snapshot, so we merge two streams client-side.
    final cancelledStream = _bookings
        .where('customerId', isEqualTo: customerId)
        .where('status', isEqualTo: 'cancelled')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => BookingModel.fromDoc(d)).toList());

    final rejectedStream = _bookings
        .where('customerId', isEqualTo: customerId)
        .where('status', isEqualTo: 'rejected')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => BookingModel.fromDoc(d)).toList());

    // Combine both streams: emit merged list whenever either emits
    return _combineLatest2(cancelledStream, rejectedStream, (a, b) {
      final merged = [...a, ...b];
      merged.sort((x, y) => y.createdAt.compareTo(x.createdAt));
      return merged;
    });
  }

  static Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      final doc = await _bookings.doc(bookingId).get();
      if (!doc.exists) return null;
      return _autoComplete(BookingModel.fromDoc(doc));
    } catch (_) {
      return null;
    }
  }

  static Stream<BookingModel?> streamBookingById(String bookingId) {
    return _bookings.doc(bookingId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return _autoComplete(BookingModel.fromDoc(doc));
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
        .map(
          (snap) =>
              snap.docs
                  .map((d) => BookingModel.fromDoc(d))
                  .map(_autoComplete)
                  .toList(),
        );
  }

  /// Pending bookings → receipt not yet verified by hall admin.
  static Stream<List<BookingModel>> streamPendingBookings(String hallId) {
    return _bookings
        .where('hallId', isEqualTo: hallId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => BookingModel.fromDoc(d)).toList());
  }

  /// Upcoming = confirmed AND eventDate >= today.
  static Stream<List<BookingModel>> streamUpcomingBookings(String hallId) {
    final todayStart = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    return _bookings
        .where('hallId', isEqualTo: hallId)
        .where('status', isEqualTo: 'confirmed')
        .where(
          'eventDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
        )
        .orderBy('eventDate', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => BookingModel.fromDoc(d)).toList());
  }

  static Stream<List<BookingModel>> streamCompletedBookings(String hallId) {
    return _bookings
        .where('hallId', isEqualTo: hallId)
        .where('status', isEqualTo: 'completed')
        .orderBy('eventDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => BookingModel.fromDoc(d)).toList());
  }

  /// FIX: Hall Admin Cancelled tab shows BOTH 'cancelled' and 'rejected' bookings.
  /// 'cancelled' = customer cancelled their own booking.
  /// 'rejected'  = hall admin rejected the payment receipt.
  static Stream<List<BookingModel>> streamCancelledBookings(String hallId) {
    final cancelledStream = _bookings
        .where('hallId', isEqualTo: hallId)
        .where('status', isEqualTo: 'cancelled')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => BookingModel.fromDoc(d)).toList());

    final rejectedStream = _bookings
        .where('hallId', isEqualTo: hallId)
        .where('status', isEqualTo: 'rejected')
        .orderBy('createdAt', descending: true)
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

  /// Confirm a booking (receipt verified, money received).
  /// Returns null on success, error string on failure.
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

  /// Reject a booking's payment receipt.
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
  //  UPDATE — Customer
  // ════════════════════════════════════════════════════════════════════════════

  static Future<String?> cancelBooking(String bookingId) async {
    try {
      await _bookings.doc(bookingId).update({'status': 'cancelled'});
      return null;
    } catch (e) {
      return 'Failed to cancel booking: $e';
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  COUNTS
  // ════════════════════════════════════════════════════════════════════════════

  static Future<Map<String, int>> getBookingCounts(String hallId) async {
    try {
      final snap = await _bookings.where('hallId', isEqualTo: hallId).get();
      final all = snap.docs.map((d) => BookingModel.fromDoc(d)).toList();
      final todayStart = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );

      return {
        'pending': all.where((b) => b.isPending).length,
        'upcoming':
            all
                .where(
                  (b) => b.isConfirmed && !b.eventDate.isBefore(todayStart),
                )
                .length,
        'completed': all.where((b) => b.isCompleted).length,
        // FIX: count both cancelled and rejected in the cancelled bucket
        'cancelled': all.where((b) => b.isCancelled || b.isRejected).length,
      };
    } catch (_) {
      return {'pending': 0, 'upcoming': 0, 'completed': 0, 'cancelled': 0};
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  INTERNAL HELPERS
  // ════════════════════════════════════════════════════════════════════════════

  static BookingModel _autoComplete(BookingModel b) {
    if (b.isConfirmed) {
      final todayStart = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      final evDay = DateTime(
        b.eventDate.year,
        b.eventDate.month,
        b.eventDate.day,
      );
      if (evDay.isBefore(todayStart)) {
        _bookings.doc(b.bookingId).update({'status': 'completed'}).ignore();
        return b.copyWith(status: 'completed');
      }
    }
    return b;
  }

  /// Utility: combine two streams and emit merged result whenever either fires.
  /// Uses a broadcast StreamController so multiple StreamBuilder listeners
  /// (e.g. after tab switches or widget rebuilds) can subscribe without
  /// restarting the underlying Firestore subscriptions.
  static Stream<T> _combineLatest2<A, B, T>(
    Stream<A> streamA,
    Stream<B> streamB,
    T Function(A, B) combiner,
  ) {
    // ignore: close_sinks
    late StreamController<T> controller;
    A? latestA;
    B? latestB;
    StreamSubscription<A>? subA;
    StreamSubscription<B>? subB;

    controller = StreamController<T>.broadcast(
      onListen: () {
        subA = streamA.listen((a) {
          latestA = a;
          if (latestB != null) {
            controller.add(combiner(latestA as A, latestB as B));
          }
        }, onError: controller.addError);
        subB = streamB.listen((b) {
          latestB = b;
          if (latestA != null) {
            controller.add(combiner(latestA as A, latestB as B));
          }
        }, onError: controller.addError);
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
