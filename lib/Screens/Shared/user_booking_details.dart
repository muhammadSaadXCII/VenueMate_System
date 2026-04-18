import 'package:flutter/material.dart';
import 'package:venuemate_system/Models/booking_model.dart';

class UserBookingDetailsScreen extends StatelessWidget {
  final BookingModel booking;

  const UserBookingDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
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
          'Booking Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHallHeader(),
            const SizedBox(height: 20),

            // ── Cancellation Reason (shown above booking summary) ────────────
            if ((booking.isCancelled || booking.isRejected) &&
                _getCancellationReason().isNotEmpty) ...[
              _buildCancellationReasonCard(),
              const SizedBox(height: 20),
            ],

            _buildEventDetailsCard(),
            const SizedBox(height: 24),

            const Text(
              'Booking Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildPaymentSummaryCard(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _getCancellationReason() {
    if (booking.isCancelled && booking.cancellationReason.isNotEmpty) {
      return booking.cancellationReason;
    }
    if (booking.isRejected && booking.rejectionReason.isNotEmpty) {
      return booking.rejectionReason;
    }
    return '';
  }

  Widget _buildCancellationReasonCard() {
    final isRejected = booking.isRejected;
    final reason = _getCancellationReason();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isRejected ? Icons.cancel_outlined : Icons.info_outline,
                  color: Colors.red.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isRejected ? 'Rejection Reason' : 'Cancellation Reason',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Text(
              reason,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHallHeader() {
    const Color primaryOrange = Color(0xFFF47C20);
    const Color textDark = Color(0xFF1F2937);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.orange.shade100,
            ),
            child: Icon(
              Icons.business_outlined,
              color: Colors.orange.shade700,
              size: 32,
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.event_outlined,
                      size: 16,
                      color: primaryOrange,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        booking.eventDateLabel,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(booking.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel(booking.status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(booking.status),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.amber.shade800;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Upcoming';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'rejected':
        return 'Rejected';
      case 'pending':
        return 'Pending Approval';
      default:
        return status;
    }
  }

  Widget _buildEventDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.event,
            label: 'Event Name',
            value: booking.eventName,
          ),
          const Divider(height: 32),
          _DetailRow(
            icon: Icons.calendar_today,
            label: 'Date',
            value: booking.shortDateLabel,
          ),
          const Divider(height: 32),
          _DetailRow(
            icon: Icons.access_time,
            label: 'Time Slot',
            value: booking.timeSlot,
          ),
          const Divider(height: 32),
          _DetailRow(
            icon: Icons.groups,
            label: 'Guests',
            value: '${booking.guestCount} People',
          ),
          if (booking.customerName.isNotEmpty) ...[
            const Divider(height: 32),
            _DetailRow(
              icon: Icons.person_outline,
              label: 'Customer',
              value: booking.customerName,
            ),
          ],
          if (booking.customerPhone.isNotEmpty) ...[
            const Divider(height: 32),
            _DetailRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: booking.customerPhone,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard() {
    const Color primaryOrange = Color(0xFFF47C20);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _PriceRow(
            label: 'Hall Rent',
            price: 'Rs. ${booking.hallRent.toStringAsFixed(0)}',
            isBold: true,
          ),

          // Menu items
          if (booking.selectedMenuItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Menu Items',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            ...booking.selectedMenuItems.map(
              (item) => _PriceRow(
                label: item.name,
                price: 'Rs. ${item.price.toStringAsFixed(0)}${item.priceUnit}',
              ),
            ),
          ],

          // Services
          if (booking.selectedServices.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Services',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            ...booking.selectedServices.map(
              (sv) => _PriceRow(
                label: sv.name,
                price: 'Rs. ${sv.price.toStringAsFixed(0)}',
              ),
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(thickness: 1, color: Colors.black12),
          ),

          _PriceRow(
            label: 'Grand Total',
            price: 'Rs. ${booking.grandTotal.toStringAsFixed(0)}',
            isTotal: true,
          ),
          const SizedBox(height: 8),
          _PriceRow(
            label: 'Paid (25% Advance)',
            price: '- Rs. ${booking.advancePayment.toStringAsFixed(0)}',
            color: Colors.green,
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryOrange.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Remaining Payment',
                  style: TextStyle(
                    color: Color(0xFFF47C20),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Rs. ${booking.remainingPayment.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFFF47C20),
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: Colors.grey[700]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String price;
  final bool isBold;
  final bool isTotal;
  final Color? color;

  const _PriceRow({
    required this.label,
    required this.price,
    this.isBold = false,
    this.isTotal = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isTotal ? Colors.black : Colors.grey[700],
                fontSize: isTotal ? 16 : 14,
                fontWeight:
                    isBold || isTotal ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          Text(
            price,
            style: TextStyle(
              color: color ?? (isTotal ? Colors.black : Colors.black87),
              fontSize: isTotal ? 18 : 14,
              fontWeight: isBold || isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
