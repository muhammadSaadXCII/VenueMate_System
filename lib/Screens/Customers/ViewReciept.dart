import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:venuemate_system/Models/booking_model.dart';
import 'package:venuemate_system/Services/booking_service.dart';

class ViewReceiptScreen extends StatelessWidget {
  final String bookingId;

  const ViewReceiptScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'View Receipt',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<BookingModel?>(
        stream: BookingService.streamBookingById(bookingId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFF97316)),
            );
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 60,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Receipt not found.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            );
          }
          return _ReceiptContent(booking: snapshot.data!);
        },
      ),
    );
  }
}

class _ReceiptContent extends StatefulWidget {
  final BookingModel booking;
  const _ReceiptContent({required this.booking});

  @override
  State<_ReceiptContent> createState() => _ReceiptContentState();
}

class _ReceiptContentState extends State<_ReceiptContent> {
  final GlobalKey _receiptKey = GlobalKey();
  bool _isDownloading = false;

  Future<void> _downloadReceipt() async {
    setState(() => _isDownloading = true);
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final boundary =
          _receiptKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/receipt_${widget.booking.invoiceId}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'VenueMate Receipt ${widget.booking.invoiceId}',
          text: 'My booking receipt for ${widget.booking.eventName}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to download receipt. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    return Column(
      children: [
        // ── Scrollable Receipt ───────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                RepaintBoundary(
                  key: _receiptKey,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDF6),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // ── Header ───────────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFCACACA),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'VenueMate',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFF47C20),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color:
                                          booking.isConfirmed
                                              ? const Color(
                                                0xFF10B981,
                                              ).withOpacity(0.15)
                                              : const Color(0xFFFEF3C7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      booking.isConfirmed
                                          ? Icons.check_circle_rounded
                                          : Icons.hourglass_top_rounded,
                                      color:
                                          booking.isConfirmed
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFD97706),
                                      size: 50,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: Text(
                                  booking.isConfirmed
                                      ? 'Booking Confirmed'
                                      : 'Booking Pending',
                                  style: TextStyle(
                                    color:
                                        booking.isConfirmed
                                            ? const Color(0xFF059669)
                                            : const Color(0xFFD97706),
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Center(
                                child: Text(
                                  booking.invoiceId,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Customer Info ────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Customer Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _infoRow(
                                'Customer Name',
                                booking.customerName,
                                'Phone',
                                booking.customerPhone,
                              ),
                              const SizedBox(height: 10),
                              _infoRow(
                                'Email',
                                booking.customerEmail,
                                'CNIC',
                                booking.customerCnic,
                              ),
                            ],
                          ),
                        ),

                        _DashedDivider(color: Colors.grey.shade400),

                        // ── Event Details ────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Event Details',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _infoRow(
                                'Hall Name',
                                booking.hallName,
                                'Event',
                                booking.eventName,
                              ),
                              const SizedBox(height: 10),
                              _infoRow(
                                'Date',
                                booking.eventDateLabel,
                                'Guests',
                                '${booking.guestCount} guests',
                              ),
                              const SizedBox(height: 10),
                              _infoRow(
                                'Time Slot',
                                booking.timeSlot,
                                'Booked On',
                                _formatDate(booking.createdAt),
                              ),
                            ],
                          ),
                        ),

                        _DashedDivider(color: Colors.grey.shade400),

                        // ── Menu Items ───────────────────────────────────
                        if (booking.selectedMenuItems.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Selected Menu Items',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ...booking.selectedMenuItems.map(
                                  (item) => _summaryRow(
                                    item.name,
                                    'Rs. ${item.price.toStringAsFixed(0)}${item.priceUnit}',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _DashedDivider(color: Colors.grey.shade400),
                        ],

                        // ── Services ─────────────────────────────────────
                        if (booking.selectedServices.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Selected Services',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ...booking.selectedServices.map(
                                  (sv) => _summaryRow(
                                    sv.name,
                                    'Rs. ${sv.price.toStringAsFixed(0)}',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _DashedDivider(color: Colors.grey.shade400),
                        ],

                        // ── Bill Summary ─────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bill Summary',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _summaryRow(
                                'Hall Rent',
                                'Rs. ${booking.hallRent.toStringAsFixed(0)}',
                              ),
                              if (booking.menuSubtotal > 0)
                                _summaryRow(
                                  'Menu Subtotal',
                                  'Rs. ${booking.menuSubtotal.toStringAsFixed(0)}',
                                ),
                              if (booking.servicesSubtotal > 0)
                                _summaryRow(
                                  'Services Subtotal',
                                  'Rs. ${booking.servicesSubtotal.toStringAsFixed(0)}',
                                ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Divider(
                                  thickness: 1,
                                  color: Colors.black12,
                                ),
                              ),
                              _summaryRow(
                                'Grand Total',
                                'Rs. ${booking.grandTotal.toStringAsFixed(0)}',
                                isBold: true,
                              ),
                              _summaryRow(
                                'Advance Paid (25%)',
                                'Rs. ${booking.advancePayment.toStringAsFixed(0)}',
                                isHighlight: true,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFF47C20,
                                    ).withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Remaining Payment',
                                      style: TextStyle(
                                        color: Color(0xFFF47C20),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Rs. ${booking.remainingPayment.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: Color(0xFFF47C20),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Footer ───────────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(20),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Thank you for choosing VenueMate!',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // ── Download Button ──────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isDownloading ? null : _downloadReceipt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF47C20),
                  disabledBackgroundColor: const Color(
                    0xFFF47C20,
                  ).withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                icon:
                    _isDownloading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                        : const Icon(
                          Icons.download_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                label: Text(
                  _isDownloading ? 'Preparing...' : 'Download Receipt',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
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
    return '${dt.day} ${months[dt.month - 1]}, ${dt.year}';
  }

  Widget _infoRow(
    String label1,
    String value1,
    String? label2,
    String? value2,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label1,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                value1,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        if (label2 != null && value2 != null)
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  label2,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value2,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.end,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _summaryRow(
    String title,
    String amount, {
    bool isBold = false,
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isBold ? 15 : 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isBold ? 15 : 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isHighlight ? Colors.green[700] : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  final Color color;

  const _DashedDivider({this.color = Colors.grey});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          direction: Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color.withOpacity(0.3)),
              ),
            );
          }),
        );
      },
    );
  }
}
