import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:venuemate_system/Models/booking_model.dart';
import 'package:venuemate_system/Models/hall_model.dart';
import 'package:venuemate_system/Services/booking_service.dart';
import 'package:venuemate_system/Services/hall_service.dart';
import 'package:venuemate_system/Widgets/common_button.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  HALL ADMIN BOOKINGS SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class HallAdminBookingsScreen extends StatefulWidget {
  const HallAdminBookingsScreen({super.key});

  @override
  State<HallAdminBookingsScreen> createState() =>
      _HallAdminBookingsScreenState();
}

class _HallAdminBookingsScreenState extends State<HallAdminBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  HallModel? _hall;
  bool _loadingHall = true;

  // Tabs: Upcoming | Pending | Completed | Cancelled
  static const _tabs = ['Upcoming', 'Pending', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadHall();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHall() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loadingHall = false);
      return;
    }
    final hall = await HallService.getHallByOwnerId(uid);
    if (mounted)
      setState(() {
        _hall = hall;
        _loadingHall = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Bookings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body:
          _loadingHall
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFF47C20)),
              )
              : _hall == null
              ? _buildNoHall()
              : Column(
                children: [
                  const SizedBox(height: 10),
                  _buildTabBar(),
                  const SizedBox(height: 20),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _BookingTab(
                          stream: BookingService.streamUpcomingBookings(
                            _hall!.hallId,
                          ),
                          tabLabel: 'Upcoming',
                          hall: _hall!,
                          emptyMessage: 'No upcoming confirmed bookings yet.',
                        ),
                        _BookingTab(
                          stream: BookingService.streamPendingBookings(
                            _hall!.hallId,
                          ),
                          tabLabel: 'Pending',
                          hall: _hall!,
                          emptyMessage: 'No pending receipts to verify.',
                        ),
                        _BookingTab(
                          stream: BookingService.streamCompletedBookings(
                            _hall!.hallId,
                          ),
                          tabLabel: 'Completed',
                          hall: _hall!,
                          emptyMessage: 'No completed events yet.',
                        ),
                        _BookingTab(
                          stream: BookingService.streamCancelledBookings(
                            _hall!.hallId,
                          ),
                          tabLabel: 'Cancelled',
                          hall: _hall!,
                          emptyMessage: 'No cancelled bookings.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: const Color(0xFFF47C20),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade700,
        labelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        padding: EdgeInsets.zero,
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  Widget _buildNoHall() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.store_outlined, size: 60, color: Colors.grey[400]),
        const SizedBox(height: 12),
        Text(
          'No hall registered.',
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  BOOKING TAB (one per tab)
// ══════════════════════════════════════════════════════════════════════════════

class _BookingTab extends StatelessWidget {
  final Stream<List<BookingModel>> stream;
  final String tabLabel;
  final HallModel hall;
  final String emptyMessage;

  const _BookingTab({
    required this.stream,
    required this.tabLabel,
    required this.hall,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BookingModel>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFF47C20)),
          );
        }
        final bookings = snap.data ?? [];
        if (bookings.isEmpty) {
          return _emptyState();
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: bookings.length,
          itemBuilder:
              (_, i) => _AdminBookingCard(
                booking: bookings[i],
                tabLabel: tabLabel,
                hall: hall,
              ),
        );
      },
    );
  }

  Widget _emptyState() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[400]),
        const SizedBox(height: 12),
        Text(
          emptyMessage,
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  ADMIN BOOKING CARD
// ══════════════════════════════════════════════════════════════════════════════

class _AdminBookingCard extends StatelessWidget {
  final BookingModel booking;
  final String tabLabel;
  final HallModel hall;

  const _AdminBookingCard({
    required this.booking,
    required this.tabLabel,
    required this.hall,
  });

  // ── Status badge ───────────────────────────────────────────────────────────

  Color get _badgeBg {
    switch (tabLabel) {
      case 'Pending':
        return const Color(0xFFFFF9C4);
      case 'Upcoming':
        return const Color(0xFFD1FAE5);
      case 'Completed':
        return const Color(0xFFC8E6C9);
      case 'Cancelled':
        return const Color(0xFFFFCDD2);
      default:
        return Colors.grey.shade200;
    }
  }

  Color get _badgeColor {
    switch (tabLabel) {
      case 'Pending':
        return const Color(0xFFFBC02D);
      case 'Upcoming':
        return const Color(0xFF059669);
      case 'Completed':
        return const Color(0xFF388E3C);
      case 'Cancelled':
        return const Color(0xFFD32F2F);
      default:
        return Colors.grey;
    }
  }

  String get _badgeLabel {
    if (tabLabel == 'Upcoming') {
      final days = booking.daysUntilEvent;
      if (days == 0) return 'Today';
      if (days <= 3) return 'In $days day${days > 1 ? 's' : ''}';
      return 'Upcoming';
    }
    return tabLabel;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ─────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hall image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child:
                    hall.imageUrls.isNotEmpty
                        ? Image.network(
                          hall.imageUrls.first,
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imageFallback(),
                        )
                        : _imageFallback(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.eventName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: Color(0xFFF47C20),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              booking.shortDateLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _badgeBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _badgeLabel,
                            style: TextStyle(
                              color: _badgeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Slot chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${booking.timeSlot} Slot',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFF97316),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _richText('Customer: ', booking.customerName),
                    const SizedBox(height: 2),
                    _richText('Guests: ', '${booking.guestCount}'),
                    const SizedBox(height: 2),
                    _richText(
                      'Total: ',
                      'Rs. ${booking.grandTotal.toStringAsFixed(0)}',
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Action buttons per tab ─────────────────────────────────────
          if (tabLabel == 'Pending')
            _buildPendingActions(context)
          else if (tabLabel == 'Upcoming')
            _buildUpcomingActions(context)
          else if (tabLabel == 'Completed')
            _buildCompletedActions(context)
          else
            _buildCancelledActions(context),
        ],
      ),
    );
  }

  // ── Pending tab: View Receipt → Confirm or Reject ──────────────────────────

  Widget _buildPendingActions(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () => _showReceiptSheet(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF47C20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        icon: const Icon(
          Icons.receipt_long_outlined,
          color: Colors.white,
          size: 18,
        ),
        label: const Text(
          'View & Verify Receipt',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ── Upcoming tab: View Details + days-left chip ────────────────────────────

  Widget _buildUpcomingActions(BuildContext context) {
    final days = booking.daysUntilEvent;
    return Column(
      children: [
        if (days <= 3 && days >= 0)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  days == 0 ? const Color(0xFFFFE4E4) : const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  days == 0 ? Icons.today : Icons.access_alarm,
                  size: 16,
                  color: days == 0 ? Colors.red : const Color(0xFFD97706),
                ),
                const SizedBox(width: 8),
                Text(
                  days == 0
                      ? 'Event is TODAY!'
                      : 'Event in $days day${days > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: days == 0 ? Colors.red : const Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => _showBookingDetailSheet(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(
              Icons.info_outline,
              size: 18,
              color: Colors.black54,
            ),
            label: const Text(
              'View Details',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedActions(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () => _showBookingDetailSheet(context),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(Icons.info_outline, size: 18, color: Colors.black54),
        label: const Text(
          'View Details',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCancelledActions(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () => _showBookingDetailSheet(context),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(Icons.info_outline, size: 18, color: Colors.black54),
        label: const Text(
          'View Details',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ── Sheet launchers ────────────────────────────────────────────────────────

  void _showReceiptSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReceiptVerificationSheet(booking: booking),
    );
  }

  void _showBookingDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingDetailSheet(booking: booking),
    );
  }

  // ── Micro helpers ──────────────────────────────────────────────────────────

  Widget _imageFallback() => Container(
    height: 80,
    width: 80,
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(Icons.store, color: Colors.grey[400], size: 32),
  );

  Widget _richText(String label, String value) => RichText(
    text: TextSpan(
      style: const TextStyle(fontSize: 12, color: Colors.black87),
      children: [
        TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(text: value),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  RECEIPT VERIFICATION SHEET
//  Shown when hall admin taps "View & Verify Receipt" on a pending booking.
// ══════════════════════════════════════════════════════════════════════════════

class _ReceiptVerificationSheet extends StatefulWidget {
  final BookingModel booking;
  const _ReceiptVerificationSheet({required this.booking});

  @override
  State<_ReceiptVerificationSheet> createState() =>
      _ReceiptVerificationSheetState();
}

class _ReceiptVerificationSheetState extends State<_ReceiptVerificationSheet> {
  bool _processingConfirm = false;
  bool _processingReject = false;

  Future<void> _confirm() async {
    setState(() => _processingConfirm = true);
    final error = await BookingService.confirmBooking(widget.booking.bookingId);
    if (!mounted) return;
    setState(() => _processingConfirm = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? '✅ Booking confirmed! Customer has been notified.'
              : 'Error: $error',
        ),
        backgroundColor: error == null ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openRejectScreen() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => _RejectPaymentScreen(bookingId: widget.booking.bookingId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const Text(
                'Verify Payment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Booking info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.person_outline,
                    color: Color(0xFFF47C20),
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.eventName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: Color(0xFFF47C20),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              b.eventDateLabel,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Customer: ${b.customerName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'Guests: ${b.guestCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Divider(thickness: 4, color: Colors.grey.shade200),
              const SizedBox(height: 16),

              _financialRow(
                'Advance Due (25%)',
                'Rs. ${b.advancePayment.toStringAsFixed(0)}',
              ),
              const SizedBox(height: 12),
              _financialRow(
                'Remaining Amount',
                'Rs. ${b.remainingPayment.toStringAsFixed(0)}',
              ),
              const SizedBox(height: 12),
              _financialRow(
                'Grand Total',
                'Rs. ${b.grandTotal.toStringAsFixed(0)}',
                isBold: true,
              ),

              const SizedBox(height: 20),

              const Text(
                'Uploaded Receipt',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Receipt image
              b.receiptImageUrl.isNotEmpty
                  ? GestureDetector(
                    onTap: () => _showFullImage(context, b.receiptImageUrl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        b.receiptImageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder:
                            (_, child, progress) =>
                                progress == null
                                    ? child
                                    : Container(
                                      height: 200,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFFF47C20),
                                        ),
                                      ),
                                    ),
                        errorBuilder: (_, __, ___) => _receiptPlaceholder(),
                      ),
                    ),
                  )
                  : _receiptPlaceholder(),

              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Tap receipt image to view full size',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ),

              const SizedBox(height: 25),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _processingReject ? null : _openRejectScreen,
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD6D1C4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Reject Payment',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child:
                        _processingConfirm
                            ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFF47C20),
                              ),
                            )
                            : CommonButton(
                              text: 'Confirm Payment',
                              onTap: _confirm,
                            ),
                  ),
                ],
              ),

              SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            backgroundColor: Colors.black,
            insetPadding: EdgeInsets.zero,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
          ),
    );
  }

  Widget _receiptPlaceholder() => Container(
    height: 150,
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.grey[300],
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.receipt_long_outlined, size: 32, color: Colors.black54),
        SizedBox(height: 8),
        Text(
          'Receipt Image',
          style: TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );

  Widget _financialRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 17 : 16,
            fontWeight: FontWeight.bold,
            color: isBold ? const Color(0xFFF47C20) : Colors.black,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  BOOKING DETAIL SHEET  (Upcoming / Completed / Cancelled)
// ══════════════════════════════════════════════════════════════════════════════

class _BookingDetailSheet extends StatelessWidget {
  final BookingModel booking;
  const _BookingDetailSheet({required this.booking});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder:
          (_, controller) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const Text(
                  'Booking Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // ── Customer Info ─────────────────────────────────────────
                _section('Customer Information', [
                  _row('Name', b.customerName),
                  _row('Phone', b.customerPhone),
                  _row('Email', b.customerEmail),
                  _row('CNIC', b.customerCnic),
                ]),

                const SizedBox(height: 16),

                // ── Event Info ────────────────────────────────────────────
                _section('Event Details', [
                  _row('Event', b.eventName),
                  _row('Date', b.eventDateLabel),
                  _row('Guests', '${b.guestCount}'),
                  _row('Booking', b.invoiceId),
                ]),

                const SizedBox(height: 16),

                // ── Financial ─────────────────────────────────────────────
                _section('Payment Summary', [
                  _row('Hall Rent', 'Rs. ${b.hallRent.toStringAsFixed(0)}'),
                  if (b.menuSubtotal > 0)
                    _row('Menu', 'Rs. ${b.menuSubtotal.toStringAsFixed(0)}'),
                  if (b.servicesSubtotal > 0)
                    _row(
                      'Services',
                      'Rs. ${b.servicesSubtotal.toStringAsFixed(0)}',
                    ),
                  _row(
                    'Grand Total',
                    'Rs. ${b.grandTotal.toStringAsFixed(0)}',
                    highlight: true,
                  ),
                  _row(
                    'Advance Paid (25%)',
                    'Rs. ${b.advancePayment.toStringAsFixed(0)}',
                  ),
                  _row(
                    'Remaining',
                    'Rs. ${b.remainingPayment.toStringAsFixed(0)}',
                  ),
                ]),

                // ── Menu items ────────────────────────────────────────────
                if (b.selectedMenuItems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _section(
                    'Menu Items (${b.selectedMenuItems.length})',
                    b.selectedMenuItems
                        .map((m) => _row(m.name, m.priceLabel))
                        .toList(),
                  ),
                ],

                // ── Services ──────────────────────────────────────────────
                if (b.selectedServices.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _section(
                    'Services (${b.selectedServices.length})',
                    b.selectedServices
                        .map((s) => _row(s.name, s.priceLabel))
                        .toList(),
                  ),
                ],

                // ── Rejection reason (if any) ─────────────────────────────
                if (b.isRejected && b.rejectionReason.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rejection Reason:',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          b.rejectionReason,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
    );
  }

  Widget _section(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF47C20),
            ),
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: highlight ? const Color(0xFFF47C20) : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  REJECT PAYMENT SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class _RejectPaymentScreen extends StatefulWidget {
  final String bookingId;
  const _RejectPaymentScreen({required this.bookingId});

  @override
  State<_RejectPaymentScreen> createState() => _RejectPaymentScreenState();
}

class _RejectPaymentScreenState extends State<_RejectPaymentScreen> {
  String? _selectedReason = 'Incorrect Amount';
  final TextEditingController _customController = TextEditingController();
  bool _submitting = false;

  final List<String> _reasons = [
    'Incorrect Amount',
    'Blurry / Unreadable Image',
    'Invalid Receipt',
    'Payment Not Received',
    'Another reason',
  ];

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason =
        _selectedReason == 'Another reason'
            ? _customController.text.trim()
            : _selectedReason ?? '';

    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a reason for rejection'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    final error = await BookingService.rejectBookingPayment(
      bookingId: widget.bookingId,
      reason: reason,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? '❌ Payment rejected. Customer has been notified.'
              : 'Error: $error',
        ),
        backgroundColor: error == null ? Colors.orange : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Reject Payment',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF47C20),
              disabledBackgroundColor: const Color(0xFFF47C20).withOpacity(0.6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child:
                _submitting
                    ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                    : const Text(
                      'Submit Reason',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Reason for Rejection',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ..._reasons.map(_buildOption),
            const SizedBox(height: 24),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _selectedReason == 'Another reason' ? 150 : 0,
              curve: Curves.easeInOut,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Container(
                  height: 140,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFF47C20),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF47C20).withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _customController,
                    enabled: _selectedReason == 'Another reason',
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      hintText: 'Please describe the specific reason…',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(String label) {
    final isSelected = _selectedReason == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedReason = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF8EC) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFF47C20) : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isSelected ? const Color(0xFFF47C20) : Colors.transparent,
                border: Border.all(
                  color:
                      isSelected
                          ? const Color(0xFFF47C20)
                          : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child:
                  isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.black87 : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
