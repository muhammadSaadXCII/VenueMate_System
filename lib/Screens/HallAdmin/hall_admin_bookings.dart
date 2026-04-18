import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
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

  // ── Cached streams — created ONCE when hall loads, never recreated on rebuild
  Stream<List<BookingModel>>? _upcomingStream;
  Stream<List<BookingModel>>? _pendingStream;
  Stream<List<BookingModel>>? _completedStream;
  Stream<List<BookingModel>>? _cancelledStream;

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
    if (mounted) {
      setState(() {
        _hall = hall;
        _loadingHall = false;
        if (hall != null) {
          _upcomingStream = BookingService.streamUpcomingBookings(hall.hallId);
          _pendingStream = BookingService.streamPendingBookings(hall.hallId);
          _completedStream = BookingService.streamCompletedBookings(
            hall.hallId,
          );
          _cancelledStream = BookingService.streamCancelledBookings(
            hall.hallId,
          );
        }
      });
    }
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
                          stream: _upcomingStream!,
                          tabLabel: 'Upcoming',
                          hall: _hall!,
                          emptyMessage: 'No upcoming confirmed bookings yet.',
                        ),
                        _BookingTab(
                          stream: _pendingStream!,
                          tabLabel: 'Pending',
                          hall: _hall!,
                          emptyMessage: 'No pending receipts to verify.',
                        ),
                        _BookingTab(
                          stream: _completedStream!,
                          tabLabel: 'Completed',
                          hall: _hall!,
                          emptyMessage: 'No completed events yet.',
                        ),
                        _BookingTab(
                          stream: _cancelledStream!,
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

  // ── Pending tab ────────────────────────────────────────────────────────────

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

  // ── Upcoming tab: View Details + Mark as Complete ──────────────────────────

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
        Row(
          children: [
            // View Details button
            Expanded(
              child: SizedBox(
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
            ),
            const SizedBox(width: 10),
            // Mark as Complete button
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmMarkAsComplete(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF388E3C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'Mark Complete',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Completed tab: View Details only ──────────────────────────────────────

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
    // Only show Manage Refund for customer-cancelled bookings with a refund applicable
    final showRefund = booking.isCancelled && booking.hasRefundApplicable;

    if (showRefund) {
      return Column(
        children: [
          // Refund status mini-badge
          _buildAdminRefundBadge(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
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
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed:
                        booking.refundStatus == 'accepted'
                            ? null
                            : () => _showAdminRefundSheet(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          booking.refundStatus == 'accepted'
                              ? Colors.green
                              : const Color(0xFFF47C20),
                      disabledBackgroundColor: Colors.green,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: Icon(
                      booking.refundStatus == 'accepted'
                          ? Icons.check_circle_outline
                          : Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      booking.refundStatus == 'accepted'
                          ? 'Refund Done'
                          : 'Manage Refund',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

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

  Widget _buildAdminRefundBadge() {
    String msg;
    Color bg;
    Color textColor;

    switch (booking.refundStatus) {
      case 'pending_upload':
        msg =
            'Refund Rs. ${booking.refundAmount.toStringAsFixed(0)} — Upload refund receipt';
        bg = const Color(0xFFFFF9C4);
        textColor = const Color(0xFF7B6000);
        break;
      case 'uploaded':
        msg = 'Receipt uploaded — Waiting for customer to verify';
        bg = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1565C0);
        break;
      case 'rejected_by_customer':
        msg = 'Customer rejected receipt — Re-upload required';
        bg = const Color(0xFFFFECB3);
        textColor = const Color(0xFFE65100);
        break;
      case 'accepted':
        msg =
            '✅ Refund of Rs. ${booking.refundAmount.toStringAsFixed(0)} accepted by customer';
        bg = const Color(0xFFC8E6C9);
        textColor = const Color(0xFF1B5E20);
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        msg,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Mark as Complete confirmation dialog ───────────────────────────────────

  void _confirmMarkAsComplete(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder:
          (dialogCtx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF388E3C),
                  size: 50,
                ),
                SizedBox(height: 12),
                Text(
                  'Mark as Completed?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            content: Text(
              'Mark "${booking.eventName}" as completed?\n\nThis will move it to the Completed tab for both you and the customer.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogCtx);
                  final error = await BookingService.markBookingAsCompleted(
                    booking.bookingId,
                  );
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        error == null
                            ? '✅ Booking marked as completed!'
                            : 'Error: $error',
                      ),
                      backgroundColor:
                          error == null ? Colors.green : Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF388E3C),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Yes, Complete',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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

  void _showAdminRefundSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdminRefundSheet(booking: booking),
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
            fontWeight: FontWeight.bold,
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
//  BOOKING DETAIL SHEET
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

                _section('Customer Information', [
                  _row('Name', b.customerName),
                  _row('Phone', b.customerPhone),
                  _row('Email', b.customerEmail),
                  _row('CNIC', b.customerCnic),
                ]),

                const SizedBox(height: 16),

                _section('Event Details', [
                  _row('Event', b.eventName),
                  _row('Date', b.eventDateLabel),
                  _row('Guests', '${b.guestCount}'),
                  _row('Booking', b.invoiceId),
                ]),

                const SizedBox(height: 16),

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

                if (b.selectedMenuItems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _section(
                    'Menu Items (${b.selectedMenuItems.length})',
                    b.selectedMenuItems
                        .map((m) => _row(m.name, m.priceLabel))
                        .toList(),
                  ),
                ],

                if (b.selectedServices.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _section(
                    'Services (${b.selectedServices.length})',
                    b.selectedServices
                        .map((s) => _row(s.name, s.priceLabel))
                        .toList(),
                  ),
                ],

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

// ══════════════════════════════════════════════════════════════════════════════
//  ADMIN REFUND SHEET
//  Hall admin views original payment receipt, uploads refund receipt
// ══════════════════════════════════════════════════════════════════════════════

class _AdminRefundSheet extends StatefulWidget {
  final BookingModel booking;
  const _AdminRefundSheet({required this.booking});

  @override
  State<_AdminRefundSheet> createState() => _AdminRefundSheetState();
}

class _AdminRefundSheetState extends State<_AdminRefundSheet> {
  File? _refundReceiptFile;
  bool _uploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      setState(() => _refundReceiptFile = File(picked.path));
    }
  }

  Future<void> _uploadRefund() async {
    if (_refundReceiptFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a refund receipt image first'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _uploading = true);
    final error = await BookingService.uploadRefundReceipt(
      bookingId: widget.booking.bookingId,
      receiptFile: _refundReceiptFile!,
    );
    if (!mounted) return;
    setState(() => _uploading = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? '✅ Refund receipt uploaded. Waiting for customer verification.'
              : 'Error: $error',
        ),
        backgroundColor: error == null ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BookingModel?>(
      stream: BookingService.streamBookingById(widget.booking.bookingId),
      builder: (context, snap) {
        final booking = snap.data ?? widget.booking;
        return DraggableScrollableSheet(
          initialChildSize: 0.88,
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
                    // Drag handle
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const Text(
                      'Manage Refund',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${booking.customerName} · ${booking.eventName}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),

                    // ── Refund amount summary ─────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF47C20), Color(0xFFFFD166)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rs. ${booking.refundAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'Amount to refund to customer',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Status card ───────────────────────────────────────────
                    _buildAdminStatusCard(booking),
                    const SizedBox(height: 16),

                    // ── Customer's original payment receipt ───────────────────
                    const Text(
                      'Customer\'s Original Payment Receipt',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Use the account number in this receipt to send the refund',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 8),
                    _buildNetworkImageBox(booking.receiptImageUrl, context),
                    const SizedBox(height: 20),

                    // ── Customer rejection reason (if re-upload needed) ───────
                    if (booking.refundStatus == 'rejected_by_customer' &&
                        booking.refundRejectionReason.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer rejection reason:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              booking.refundRejectionReason,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.red.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Already accepted — success banner ─────────────────────
                    if (booking.refundStatus == 'accepted') ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green.shade600,
                              size: 48,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Refund Successfully Completed!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Customer has accepted the refund receipt.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ── Upload section (shown when needs to upload / re-upload) ─
                    if (booking.refundStatus == 'pending_upload' ||
                        booking.refundStatus == 'rejected_by_customer') ...[
                      Text(
                        booking.refundStatus == 'rejected_by_customer'
                            ? 'Upload New Refund Receipt'
                            : 'Upload Refund Receipt',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Send Rs. ${booking.refundAmount.toStringAsFixed(0)} to the account in the receipt above, then upload proof here.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 10),

                      // Image picker area
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 160,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color:
                                  _refundReceiptFile != null
                                      ? const Color(0xFFF47C20)
                                      : Colors.grey.shade300,
                              width: _refundReceiptFile != null ? 2 : 1,
                            ),
                          ),
                          child:
                              _refundReceiptFile != null
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(13),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.file(
                                          _refundReceiptFile!,
                                          fit: BoxFit.cover,
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: _pickImage,
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.edit,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.upload_file_outlined,
                                        size: 40,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Tap to select refund receipt',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Choose from gallery',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ],
                                  ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed:
                              (_refundReceiptFile != null && !_uploading)
                                  ? _uploadRefund
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF47C20),
                            disabledBackgroundColor: Colors.grey[300],
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              _uploading
                                  ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                  : const Text(
                                    'Upload Refund Receipt',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                        ),
                      ),
                    ],

                    // ── Waiting for customer (uploaded state) ─────────────────
                    if (booking.refundStatus == 'uploaded') ...[
                      const Text(
                        'Uploaded Refund Receipt',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildNetworkImageBox(booking.refundReceiptUrl, context),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.hourglass_empty_outlined,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Waiting for customer to verify and accept the refund receipt.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue.shade800,
                                ),
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
      },
    );
  }

  Widget _buildAdminStatusCard(BookingModel booking) {
    String title;
    String subtitle;
    Color color;
    IconData icon;

    switch (booking.refundStatus) {
      case 'pending_upload':
        title = 'Action Required: Upload Refund Receipt';
        subtitle =
            'Send Rs. ${booking.refundAmount.toStringAsFixed(0)} to the account in the receipt below, then upload proof.';
        color = Colors.amber.shade800;
        icon = Icons.upload_outlined;
        break;
      case 'uploaded':
        title = 'Waiting for Customer Verification';
        subtitle = 'Customer will accept or reject your receipt.';
        color = Colors.blue.shade700;
        icon = Icons.hourglass_empty_outlined;
        break;
      case 'rejected_by_customer':
        title = 'Customer Rejected — Re-upload Required';
        subtitle = 'See reason below and upload a corrected receipt.';
        color = Colors.red.shade700;
        icon = Icons.refresh_outlined;
        break;
      case 'accepted':
        title = 'Refund Complete ✅';
        subtitle = 'Customer confirmed the refund receipt.';
        color = Colors.green.shade700;
        icon = Icons.check_circle_outline;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkImageBox(String url, BuildContext context) {
    if (url.isEmpty) {
      return Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 32,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Not available',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }
    return GestureDetector(
      onTap: () => _showFullImage(context, url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
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
          errorBuilder:
              (_, __, ___) => Container(
                height: 140,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.broken_image_outlined, size: 36),
                ),
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
}
