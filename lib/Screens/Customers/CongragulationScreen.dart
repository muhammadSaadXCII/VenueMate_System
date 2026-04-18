import 'package:flutter/material.dart';
import 'package:venuemate_system/Models/booking_model.dart';
import 'package:venuemate_system/Screens/Customers/MainNavigation.dart';
import 'package:venuemate_system/Services/booking_service.dart';
import 'ViewReciept.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  CONGRATULATIONS SCREEN
//
//  Shown immediately after PaymentScreen.  Streams the booking in real-time:
//    • status == 'pending'   → shows a "Waiting for verification" state
//    • status == 'confirmed' → upgrades the UI to a full "Booking Confirmed!"
//    • status == 'rejected'  → shows rejection notice with reason
// ══════════════════════════════════════════════════════════════════════════════

class CongratulationsScreen extends StatelessWidget {
  final String bookingId;
  const CongratulationsScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<BookingModel?>(
        stream: BookingService.streamBookingById(bookingId),
        builder: (context, snapshot) {
          final booking = snapshot.data;

          // Determine which state to show
          final isConfirmed = booking?.isConfirmed ?? false;
          final isRejected = booking?.isRejected ?? false;

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 60),

                        // ── Animated graphic (changes with status) ─────────
                        _StatusGraphic(
                          isConfirmed: isConfirmed,
                          isRejected: isRejected,
                        ),
                        const SizedBox(height: 40),

                        // ── Title ──────────────────────────────────────────
                        Text(
                          isConfirmed
                              ? '🎉 Booking Confirmed!'
                              : isRejected
                              ? 'Payment Rejected'
                              : 'Request Submitted!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color:
                                isRejected ? Colors.red[700] : Colors.black87,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),

                        Text(
                          isConfirmed
                              ? 'Your hall is officially booked!\nThe hall admin has verified your payment.'
                              : isRejected
                              ? 'Your payment receipt was rejected.\nPlease contact the hall or re-upload a valid receipt.'
                              : 'Your booking request has been submitted.\nThe hall admin will verify your receipt shortly.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Status notice box ──────────────────────────────
                        _StatusNoticeBox(
                          booking: booking,
                          isConfirmed: isConfirmed,
                          isRejected: isRejected,
                        ),
                        const SizedBox(height: 32),

                        // ── Booking details card ───────────────────────────
                        if (booking != null)
                          _BookingDetailsCard(booking: booking)
                        else
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: CircularProgressIndicator(
                              color: Color(0xFFF97316),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // ── Bottom buttons ─────────────────────────────────────────
                _BottomButtons(
                  bookingId: bookingId,
                  isConfirmed: isConfirmed,
                  isRejected: isRejected,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  STATUS GRAPHIC
// ══════════════════════════════════════════════════════════════════════════════

class _StatusGraphic extends StatefulWidget {
  final bool isConfirmed;
  final bool isRejected;
  const _StatusGraphic({required this.isConfirmed, required this.isRejected});

  @override
  State<_StatusGraphic> createState() => _StatusGraphicState();
}

class _StatusGraphicState extends State<_StatusGraphic>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor =
        widget.isRejected
            ? Colors.red.withOpacity(0.1)
            : widget.isConfirmed
            ? const Color(0xFF10B981).withOpacity(0.12)
            : const Color(0xFFF47C20).withOpacity(0.10);
    final Color iconColor =
        widget.isRejected
            ? Colors.red
            : widget.isConfirmed
            ? const Color(0xFF10B981)
            : const Color(0xFFF97316);
    final IconData icon =
        widget.isRejected
            ? Icons.cancel_rounded
            : widget.isConfirmed
            ? Icons.check_circle_rounded
            : Icons.hourglass_top_rounded;

    return ScaleTransition(
      scale: _scale,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 180,
            width: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF47C20).withOpacity(0.07),
            ),
          ),
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor),
            child: Icon(icon, color: iconColor, size: 80),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  STATUS NOTICE BOX
// ══════════════════════════════════════════════════════════════════════════════

class _StatusNoticeBox extends StatelessWidget {
  final BookingModel? booking;
  final bool isConfirmed;
  final bool isRejected;

  const _StatusNoticeBox({
    required this.booking,
    required this.isConfirmed,
    required this.isRejected,
  });

  @override
  Widget build(BuildContext context) {
    if (isConfirmed) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE4F9ED),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Color(0xFF10B981),
              size: 18,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Status: Confirmed ✅ — Your hall is booked! Check your receipt for full details.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF065F46),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (isRejected) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE4E4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
                SizedBox(width: 8),
                Text(
                  'Status: Rejected ❌',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (booking?.rejectionReason.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Text(
                'Reason: ${booking!.rejectionReason}',
                style: TextStyle(fontSize: 12, color: Colors.red[700]),
              ),
            ],
          ],
        ),
      );
    }

    // Pending
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        children: [
          Icon(Icons.access_time, color: Color(0xFFD97706), size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Status: Pending ⏳ — Waiting for hall admin to verify your receipt. This page updates automatically.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  BOOKING DETAILS CARD
// ══════════════════════════════════════════════════════════════════════════════

class _BookingDetailsCard extends StatelessWidget {
  final BookingModel booking;
  const _BookingDetailsCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _row('Booking ID', booking.invoiceId),
          const Divider(height: 24),
          _row('Hall', booking.hallName),
          const Divider(height: 24),
          _row('Event', booking.eventName),
          const Divider(height: 24),
          _row('Date', booking.eventDateLabel),
          const Divider(height: 24),
          _row('Guests', '${booking.guestCount}'),
          const Divider(height: 24),
          _row(
            'Grand Total',
            'Rs. ${booking.grandTotal.toStringAsFixed(0)}',
            bold: true,
          ),
          const Divider(height: 24),
          _row(
            'Advance Paid (25%)',
            'Rs. ${booking.advancePayment.toStringAsFixed(0)}',
            valueColor: const Color(0xFF16A34A),
          ),
          const Divider(height: 24),
          _row(
            'Remaining',
            'Rs. ${booking.remainingPayment.toStringAsFixed(0)}',
            valueColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: valueColor ?? Colors.black87,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  BOTTOM BUTTONS
// ══════════════════════════════════════════════════════════════════════════════

class _BottomButtons extends StatelessWidget {
  final String bookingId;
  final bool isConfirmed;
  final bool isRejected;

  const _BottomButtons({
    required this.bookingId,
    required this.isConfirmed,
    required this.isRejected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed:
                  () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainNavigation()),
                    (r) => false,
                  ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF47C20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Back to Home',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ViewReceiptScreen(bookingId: bookingId),
                  ),
                ),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            child: Text(
              isConfirmed ? 'View & Download Receipt' : 'View E-Receipt',
            ),
          ),
        ],
      ),
    );
  }
}
