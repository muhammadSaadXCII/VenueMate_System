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

  /// Creates a booking after a final capacity re-check.
  ///
  /// Returns:
  ///   • bookingId (String) on success
  ///   • 'SLOT_FULL' if the slot just filled up before saving
  ///   • throws Exception with a real message on failure   ← FIX: was silently returning null
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
    // ── FIX: Do NOT wrap the whole thing in catch(_) — let errors bubble up
    //         so PaymentScreen can show a real message and so YOU can see
    //         what is actually failing in the debug console.

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

    // ── FIX: Previously this silently returned null when the upload failed.
    //         Now we throw so PaymentScreen shows the real reason.
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
      status: 'pending', // ← Hall admin sees this in Pending tab
      createdAt: DateTime.now(),
      hallCapacityMax: hallCapacityMax,
    );

    // 5. Save to Firestore — bookings/{bookingId}
    // ── FIX: Previously catch(_) swallowed the FirebaseException here.
    //         Now we let it throw so the real error (permissions, missing
    //         index, bad API key) appears in PaymentScreen and in the console.
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

  static Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      final doc = await _bookings.doc(bookingId).get();
      if (!doc.exists) return null
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

  static Stream<List<BookingModel>> streamCancelledBookings(String hallId) {
    return _bookings
        .where('hallId', isEqualTo: hallId)
        .where('status', isEqualTo: 'cancelled')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => BookingModel.fromDoc(d)).toList());
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
        'cancelled': all.where((b) => b.isCancelled).length,
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
