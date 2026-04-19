// ignore: file_names
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:venuemate_system/Models/booking_model.dart';
import 'package:venuemate_system/Services/booking_service.dart';
import 'package:venuemate_system/Screens/Shared/user_booking_details.dart';
import 'CancelBookingScreen.dart';
import 'ViewReciept.dart';

class AllEventsScreen extends StatefulWidget {
  final int initialTabIndex;

  const AllEventsScreen({super.key, this.initialTabIndex = 0});

  @override
  State<AllEventsScreen> createState() => _AllEventsScreenState();
}

class _AllEventsScreenState extends State<AllEventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _customerId;

  @override
  void initState() {
    super.initState();
    // 4 tabs: Pending | Upcoming | Completed | Cancelled
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _customerId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'All Events',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFFF47C20),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.black54,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'Pending'),
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Completed'),
                  Tab(text: 'Cancelled'),
                ],
              ),
            ),
          ),
        ),
      ),
      body:
          _customerId == null
              ? const Center(child: Text('Please log in'))
              : TabBarView(
                controller: _tabController,
                children: [
                  _BookingList(
                    stream: BookingService.streamCustomerPendingAndRejected(
                      _customerId!,
                    ),
                    emptyTitle: 'No Pending Bookings',
                    emptySubtitle:
                        'Bookings waiting for hall admin approval will appear here',
                    emptyIcon: Icons.hourglass_empty_outlined,
                  ),
                  _BookingList(
                    stream: BookingService.streamCustomerBookingsByStatus(
                      _customerId!,
                      'confirmed',
                    ),
                    emptyTitle: 'No Upcoming Events',
                    emptySubtitle:
                        'You don\'t have any upcoming events scheduled',
                    emptyIcon: Icons.event_available_outlined,
                  ),
                  _BookingList(
                    stream: BookingService.streamCustomerBookingsByStatus(
                      _customerId!,
                      'completed',
                    ),
                    emptyTitle: 'No Completed Events',
                    emptySubtitle: 'You haven\'t completed any events yet',
                    emptyIcon: Icons.event_outlined,
                  ),
                  _BookingList(
                    stream: BookingService.streamCustomerCancelledBookings(
                      _customerId!,
                    ),
                    emptyTitle: 'No Cancelled Events',
                    emptySubtitle: 'You haven\'t cancelled any events',
                    emptyIcon: Icons.event_busy_outlined,
                  ),
                ],
              ),
    );
  }
}

// ── Real-time Booking List ─────────────────────────────────────────────────

class _BookingList extends StatelessWidget {
  final Stream<List<BookingModel>> stream;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;

  const _BookingList({
    required this.stream,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyIcon,
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
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final bookings = snap.data ?? [];
        if (bookings.isEmpty) {
          return _buildEmptyState(emptyTitle, emptySubtitle, emptyIcon);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            return _BookingCard(booking: bookings[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Booking Card ──────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.orange.shade200, Colors.orange.shade400],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.business_outlined,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.hallName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          height: 1.3,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        booking.eventName,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              booking.shortDateLabel,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildStatusBadge(booking.status),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey.shade200,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildActionButtons(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case 'pending':
        backgroundColor = Colors.amber.shade50;
        textColor = Colors.amber.shade800;
        text = 'Pending Approval';
        break;
      case 'confirmed':
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        text = 'Upcoming';
        break;
      case 'completed':
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        text = 'Completed';
        break;
      case 'cancelled':
        backgroundColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        text = 'Cancelled';
        break;
      case 'rejected':
        backgroundColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        text = 'Rejected';
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    switch (booking.status) {
      case 'rejected':
        // ── Rejected: show rejection reason + re-upload button ─────────────
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.cancel_outlined,
                        color: Colors.red.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Receipt Rejected',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  if (booking.rejectionReason.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Reason: ${booking.rejectionReason}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showReuploadSheet(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF47C20),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(
                  Icons.upload_file_outlined,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text(
                  'Re-upload Receipt',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );

      case 'pending':
        return Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time, color: Color(0xFFD97706), size: 16),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Waiting for hall admin approval',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF92400E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => ViewReceiptScreen(bookingId: booking.bookingId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF47C20),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
              ),
              child: const Text(
                'View Receipt',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );

      case 'confirmed':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CancelBookingScreen(booking: booking),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  side: BorderSide(color: Colors.red.shade300, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Cancel Booking',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) =>
                              ViewReceiptScreen(bookingId: booking.bookingId),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF47C20),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'View Receipt',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );

      case 'completed':
        // ── Completed: View Details + Give Feedback ───────────────────────
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => UserBookingDetailsScreen(booking: booking),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF47C20),
                  side: const BorderSide(color: Colors.orange, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'View Details',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _showFeedbackSheet(context, booking);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF47C20),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Give Feedback',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );

      default: // cancelled / rejected
        if (booking.isCancelled && booking.hasRefundApplicable) {
          // Cancelled with refund applicable — show View Details + Manage Refund
          return Column(
            children: [
              // Refund status banner
              _buildRefundStatusBanner(),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) =>
                                    UserBookingDetailsScreen(booking: booking),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF47C20),
                        side: const BorderSide(
                          color: Color(0xFFF47C20),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          booking.refundStatus == 'accepted'
                              ? null
                              : () => _showCustomerRefundSheet(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            booking.refundStatus == 'accepted'
                                ? Colors.green
                                : const Color(0xFFF47C20),
                        disabledBackgroundColor: Colors.green,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: Icon(
                        booking.refundStatus == 'accepted'
                            ? Icons.check_circle_outline
                            : Icons.account_balance_wallet_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
                      label: Text(
                        booking.refundStatus == 'accepted'
                            ? 'Refund Done'
                            : 'Manage Refund',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        }
        // Cancelled with no refund OR rejected-receipt status
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserBookingDetailsScreen(booking: booking),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFF47C20),
              side: const BorderSide(color: Color(0xFFF47C20), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              'View Details',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        );
    }
  }

  /// Refund status banner shown above the buttons for cancelled+refund bookings
  Widget _buildRefundStatusBanner() {
    String msg;
    Color bg;
    Color textColor;
    IconData icon;

    switch (booking.refundStatus) {
      case 'pending_upload':
        msg =
            'Refund Rs. ${booking.refundAmount.toStringAsFixed(0)} — Waiting for hall admin to upload receipt';
        bg = Colors.amber.shade50;
        textColor = Colors.amber.shade900;
        icon = Icons.hourglass_empty_outlined;
        break;
      case 'uploaded':
        msg = 'Refund receipt uploaded — Please verify it';
        bg = Colors.blue.shade50;
        textColor = Colors.blue.shade800;
        icon = Icons.upload_file_outlined;
        break;
      case 'rejected_by_customer':
        msg = 'You rejected the receipt — Waiting for hall admin to re-upload';
        bg = Colors.orange.shade50;
        textColor = Colors.orange.shade900;
        icon = Icons.refresh_outlined;
        break;
      case 'accepted':
        msg =
            'Refund of Rs. ${booking.refundAmount.toStringAsFixed(0)} successfully processed ✅';
        bg = Colors.green.shade50;
        textColor = Colors.green.shade800;
        icon = Icons.check_circle_outline;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomerRefundSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomerRefundSheet(booking: booking),
    );
  }

  /// Opens the re-upload receipt bottom sheet for rejected bookings.
  void _showReuploadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReuploadReceiptSheet(booking: booking),
    );
  }

  /// Opens the feedback bottom sheet (checks if already submitted).
  void _showFeedbackSheet(BuildContext context, BookingModel booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FeedbackSubmitSheet(booking: booking),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  FEEDBACK SUBMIT SHEET  (Customer gives feedback for a completed booking)
// ══════════════════════════════════════════════════════════════════════════════

class _FeedbackSubmitSheet extends StatefulWidget {
  final BookingModel booking;
  const _FeedbackSubmitSheet({required this.booking});

  @override
  State<_FeedbackSubmitSheet> createState() => _FeedbackSubmitSheetState();
}

class _FeedbackSubmitSheetState extends State<_FeedbackSubmitSheet> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _submitting = false;
  bool _alreadySubmitted = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkExistingFeedback();
  }

  Future<void> _checkExistingFeedback() async {
    final exists = await BookingService.hasFeedback(widget.booking.bookingId);
    if (mounted) {
      setState(() {
        _alreadySubmitted = exists;
        _checking = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a star rating'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    final user = FirebaseAuth.instance.currentUser;
    final error = await BookingService.submitFeedback(
      bookingId: widget.booking.bookingId,
      hallId: widget.booking.hallId,
      customerId: user?.uid ?? '',
      customerName: widget.booking.customerName,
      hallName: widget.booking.hallName,
      rating: _rating,
      reviewText: _reviewController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (error == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Feedback submitted successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Give Feedback',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                widget.booking.hallName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.booking.shortDateLabel,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),

              const SizedBox(height: 20),

              if (_checking)
                const CircularProgressIndicator(color: Color(0xFFF47C20))
              else if (_alreadySubmitted)
                _buildAlreadySubmitted()
              else
                _buildFeedbackForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlreadySubmitted() {
    return Column(
      children: [
        const SizedBox(height: 10),
        Icon(Icons.check_circle_outline, color: Colors.green[400], size: 60),
        const SizedBox(height: 16),
        const Text(
          'Feedback Already Submitted',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'You have already submitted feedback for this booking.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF47C20),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              'Close',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackForm() {
    return Column(
      children: [
        const Text(
          'How was your experience?',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),

        // Star rating
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () => setState(() => _rating = index + 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  index < _rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: Colors.orange,
                  size: 42,
                ),
              ),
            );
          }),
        ),

        if (_rating > 0) ...[
          const SizedBox(height: 6),
          Text(
            _ratingLabel(_rating),
            style: TextStyle(
              fontSize: 13,
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Review text
        TextField(
          controller: _reviewController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Share your experience with us... (optional)',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide(color: Colors.orange, width: 2),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Submit button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_rating > 0 && !_submitting) ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF47C20),
              disabledBackgroundColor: Colors.grey[300],
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
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
                      'Submit Feedback',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent!';
      default:
        return '';
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  RE-UPLOAD RECEIPT SHEET  (Customer resubmits after hall admin rejection)
// ══════════════════════════════════════════════════════════════════════════════

class _ReuploadReceiptSheet extends StatefulWidget {
  final BookingModel booking;
  const _ReuploadReceiptSheet({required this.booking});

  @override
  State<_ReuploadReceiptSheet> createState() => _ReuploadReceiptSheetState();
}

class _ReuploadReceiptSheetState extends State<_ReuploadReceiptSheet> {
  File? _newReceipt;
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
      setState(() => _newReceipt = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (_newReceipt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a receipt image first'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _uploading = true);
    final error = await BookingService.resubmitReceipt(
      bookingId: widget.booking.bookingId,
      newReceiptFile: _newReceipt!,
    );
    if (!mounted) return;
    setState(() => _uploading = false);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? '✅ Receipt resubmitted! Waiting for hall admin review.'
              : 'Error: $error',
        ),
        backgroundColor: error == null ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Re-upload Receipt',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),
            Text(
              widget.booking.hallName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.booking.shortDateLabel,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),

            // Rejection reason reminder
            if (widget.booking.rejectionReason.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
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
                      'Rejection Reason:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.booking.rejectionReason,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

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
                        _newReceipt != null
                            ? const Color(0xFFF47C20)
                            : Colors.grey.shade300,
                    width: _newReceipt != null ? 2 : 1,
                  ),
                ),
                child:
                    _newReceipt != null
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(_newReceipt!, fit: BoxFit.cover),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(8),
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
                              'Tap to select new receipt',
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
              child: ElevatedButton(
                onPressed:
                    (_newReceipt != null && !_uploading) ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF47C20),
                  disabledBackgroundColor: Colors.grey[300],
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                          'Resubmit Receipt',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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
//  CUSTOMER REFUND SHEET
//  Customer views the refund receipt uploaded by hall admin and accepts/rejects
// ══════════════════════════════════════════════════════════════════════════════

class _CustomerRefundSheet extends StatefulWidget {
  final BookingModel booking;
  const _CustomerRefundSheet({required this.booking});

  @override
  State<_CustomerRefundSheet> createState() => _CustomerRefundSheetState();
}

class _CustomerRefundSheetState extends State<_CustomerRefundSheet> {
  bool _accepting = false;
  bool _rejecting = false;
  final TextEditingController _rejectReasonController = TextEditingController();

  @override
  void dispose() {
    _rejectReasonController.dispose();
    super.dispose();
  }

  Future<void> _acceptRefund() async {
    setState(() => _accepting = true);
    final error = await BookingService.acceptRefund(widget.booking.bookingId);
    if (!mounted) return;
    setState(() => _accepting = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? '✅ Refund accepted! Rs. ${widget.booking.refundAmount.toStringAsFixed(0)} successfully received.'
              : 'Error: $error',
        ),
        backgroundColor: error == null ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showRejectDialog() {
    _rejectReasonController.clear();
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Column(
              children: [
                Icon(Icons.cancel_outlined, color: Colors.orange, size: 48),
                SizedBox(height: 12),
                Text(
                  'Reject Refund Receipt?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Please give a reason so the hall admin can upload a correct receipt.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _rejectReasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'e.g. Wrong amount, blurry image...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFFF47C20),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Back',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final reason = _rejectReasonController.text.trim();
                  if (reason.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a reason'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  setState(() => _rejecting = true);
                  final error = await BookingService.rejectRefund(
                    bookingId: widget.booking.bookingId,
                    reason: reason,
                  );
                  if (!mounted) return;
                  setState(() => _rejecting = false);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        error == null
                            ? 'Receipt rejected. Hall admin will re-upload.'
                            : 'Error: $error',
                      ),
                      backgroundColor:
                          error == null ? Colors.orange : Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Reject',
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BookingModel?>(
      stream: BookingService.streamBookingById(widget.booking.bookingId),
      builder: (context, snap) {
        final booking = snap.data ?? widget.booking;
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
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
                      booking.hallName,
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
                                'Refund Amount (10% of total)',
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

                    // ── Status indicator ──────────────────────────────────────
                    _buildStatusCard(booking.refundStatus),
                    const SizedBox(height: 16),

                    // ── Your original payment receipt ─────────────────────────
                    const Text(
                      'Your Original Payment Receipt',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildImageBox(booking.receiptImageUrl, context),
                    const SizedBox(height: 20),

                    // ── Refund receipt from hall admin ────────────────────────
                    if (booking.refundStatus == 'uploaded' ||
                        booking.refundStatus == 'rejected_by_customer' ||
                        booking.refundStatus == 'accepted') ...[
                      const Text(
                        'Refund Receipt (from Hall Admin)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildImageBox(booking.refundReceiptUrl, context),
                      const SizedBox(height: 20),
                    ],

                    // ── Rejection reason if hall admin re-upload pending ──────
                    if (booking.refundStatus == 'rejected_by_customer' &&
                        booking.refundRejectionReason.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your rejection reason:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              booking.refundRejectionReason,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Accept / Reject buttons (only when uploaded) ──────────
                    if (booking.refundStatus == 'uploaded') ...[
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: OutlinedButton(
                                onPressed:
                                    _rejecting ? null : _showRejectDialog,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(
                                    color: Colors.red,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Reject Receipt',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _accepting ? null : _acceptRefund,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child:
                                    _accepting
                                        ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                        : const Text(
                                          'Accept Refund',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // ── Successfully accepted banner ──────────────────────────
                    if (booking.refundStatus == 'accepted')
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
                              'Rs. ${booking.refundAmount.toStringAsFixed(0)} has been refunded to your account.',
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
                ),
              ),
        );
      },
    );
  }

  Widget _buildStatusCard(String refundStatus) {
    String title;
    String subtitle;
    Color color;
    IconData icon;

    switch (refundStatus) {
      case 'pending_upload':
        title = 'Waiting for Refund Receipt';
        subtitle = 'Hall admin will upload the refund receipt soon.';
        color = Colors.amber.shade700;
        icon = Icons.hourglass_empty_outlined;
        break;
      case 'uploaded':
        title = 'Refund Receipt Uploaded';
        subtitle = 'Please review and accept or reject below.';
        color = Colors.blue.shade700;
        icon = Icons.upload_file_outlined;
        break;
      case 'rejected_by_customer':
        title = 'Receipt Rejected';
        subtitle = 'Waiting for hall admin to upload a new receipt.';
        color = Colors.orange.shade800;
        icon = Icons.refresh_outlined;
        break;
      case 'accepted':
        title = 'Refund Complete ✅';
        subtitle = 'You have accepted the refund receipt.';
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageBox(String url, BuildContext context) {
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
              'Not uploaded yet',
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
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder:
              (_, child, progress) =>
                  progress == null
                      ? child
                      : Container(
                        height: 180,
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
