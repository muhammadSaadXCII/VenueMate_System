import 'package:flutter/material.dart';
import 'package:venuemate_system/Models/booking_model.dart';
import 'package:venuemate_system/Services/booking_service.dart';

class CancelBookingScreen extends StatefulWidget {
  final BookingModel booking;

  const CancelBookingScreen({Key? key, required this.booking})
    : super(key: key);

  @override
  State<CancelBookingScreen> createState() => _CancelBookingScreenState();
}

class _CancelBookingScreenState extends State<CancelBookingScreen> {
  String? selectedReason;
  final TextEditingController otherReasonController = TextEditingController();
  bool _isCancelling = false;

  final List<String> cancellationReasons = [
    'I have better deal',
    'Some other work, can\'t come',
    'I want to book another event',
    'Venue location is too far from my location',
    'Another reason',
  ];

  // ── Refund calculation ────────────────────────────────────────────────────
  int get _daysUntilEvent => widget.booking.daysUntilEvent;

  /// 10% of grandTotal = 40% of advancePayment
  double get _refundAmount => widget.booking.advancePayment * 0.4;

  bool get _isRefundApplicable => _daysUntilEvent > 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: _isCancelling ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          'Cancel Booking',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Refund Policy Banner ──────────────────────────────
                  _buildRefundPolicyBanner(),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Please select a reason for cancellation',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ...cancellationReasons.map((reason) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  selectedReason = reason;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      selectedReason == reason
                                          ? Colors.orange.withOpacity(0.1)
                                          : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        selectedReason == reason
                                            ? Colors.orange
                                            : Colors.grey[300]!,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color:
                                              selectedReason == reason
                                                  ? Colors.orange
                                                  : Colors.grey[400]!,
                                          width: 2,
                                        ),
                                        color:
                                            selectedReason == reason
                                                ? Colors.orange
                                                : Colors.transparent,
                                      ),
                                      child:
                                          selectedReason == reason
                                              ? const Icon(
                                                Icons.circle,
                                                size: 10,
                                                color: Colors.white,
                                              )
                                              : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        reason,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color:
                                              selectedReason == reason
                                                  ? Colors.orange[800]
                                                  : Colors.black87,
                                          fontWeight:
                                              selectedReason == reason
                                                  ? FontWeight.w500
                                                  : FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        if (selectedReason == 'Another reason') ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: otherReasonController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Tell us your reason...',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.orange,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed:
                      (selectedReason != null && !_isCancelling)
                          ? () => _showCancellationDialog(context)
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    disabledBackgroundColor: Colors.grey[300],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isCancelling
                          ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                          : const Text(
                            'Cancel Booking',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundPolicyBanner() {
    if (_isRefundApplicable) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.green.shade700,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Refund Policy',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _policyRow(
              'Event is in $_daysUntilEvent days (> 2 days)',
              Colors.green.shade700,
            ),
            const SizedBox(height: 6),
            _policyRow(
              'Refund applicable: Rs. ${_refundAmount.toStringAsFixed(0)} (10% of total)',
              Colors.green.shade700,
            ),
            const SizedBox(height: 6),
            _policyRow(
              'Hall admin keeps 15% (Rs. ${(widget.booking.advancePayment - _refundAmount).toStringAsFixed(0)})',
              Colors.green.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              'After cancellation, hall admin will upload a refund receipt. You can verify it in your Cancelled tab.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_outlined,
                  color: Colors.red.shade700,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'No Refund Policy',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _policyRow(
              _daysUntilEvent <= 0
                  ? 'Event is today or already passed'
                  : 'Only $_daysUntilEvent day${_daysUntilEvent == 1 ? '' : 's'} left (≤ 2 days)',
              Colors.red.shade700,
            ),
            const SizedBox(height: 6),
            _policyRow(
              'No advance amount will be refunded',
              Colors.red.shade700,
            ),
            const SizedBox(height: 6),
            _policyRow(
              'Hall admin keeps full advance: Rs. ${widget.booking.advancePayment.toStringAsFixed(0)}',
              Colors.red.shade600,
            ),
          ],
        ),
      );
    }
  }

  Widget _policyRow(String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.circle, size: 6, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: color, height: 1.3),
          ),
        ),
      ],
    );
  }

  void _showCancellationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Column(
              children: [
                Icon(Icons.cancel_outlined, color: Colors.orange, size: 50),
                SizedBox(height: 16),
                Text(
                  'Cancel Booking?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            content: Text(
              _isRefundApplicable
                  ? 'You will receive a refund of Rs. ${_refundAmount.toStringAsFixed(0)} (10% of total). Hall admin keeps 15%.\n\nThis action cannot be undone.'
                  : 'No refund will be issued as the event is within 2 days.\n\nThis action cannot be undone.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'No, Keep it',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);

                  Navigator.pop(dialogContext);
                  setState(() => _isCancelling = true);

                  final String finalReason =
                      selectedReason == 'Another reason'
                          ? otherReasonController.text.trim().isEmpty
                              ? 'Another reason'
                              : otherReasonController.text.trim()
                          : selectedReason!;

                  final error = await BookingService.cancelBookingWithRefund(
                    widget.booking.bookingId,
                    reason: finalReason,
                    advancePayment: widget.booking.advancePayment,
                    eventDate: widget.booking.eventDate,
                  );

                  if (!mounted) return;
                  setState(() => _isCancelling = false);

                  if (error == null) {
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          _isRefundApplicable
                              ? 'Booking cancelled. Refund of Rs. ${_refundAmount.toStringAsFixed(0)} will be processed by hall admin.'
                              : 'Booking cancelled successfully.',
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Error: $error'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Yes, Cancel',
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
  void dispose() {
    otherReasonController.dispose();
    super.dispose();
  }
}
