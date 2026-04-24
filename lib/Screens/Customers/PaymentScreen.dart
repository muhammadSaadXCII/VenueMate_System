import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:venuemate_system/Models/hall_model.dart';
import 'package:venuemate_system/Models/menu_item_model.dart';
import 'package:venuemate_system/Models/service_item_model.dart';
import 'package:venuemate_system/Services/booking_service.dart';
import 'CongragulationScreen.dart';

class PaymentScreen extends StatefulWidget {
  final HallModel hall;
  final String customerName;
  final String customerPhone;
  final String customerCnic;
  final String customerEmail;
  final String eventName;
  final int guestCount;
  final String timeSlot;
  final DateTime eventDate;
  final List<MenuItemModel> selectedMenuItems;
  final List<ServiceItemModel> selectedServices;

  const PaymentScreen({
    super.key,
    required this.hall,
    required this.customerName,
    required this.customerPhone,
    required this.customerCnic,
    required this.customerEmail,
    required this.eventName,
    required this.guestCount,
    required this.timeSlot,
    required this.eventDate,
    required this.selectedMenuItems,
    required this.selectedServices,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  File? _receiptImage;
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  double get _hallRent => widget.hall.pricePerEvent;
  double get _menuSubtotal =>
      widget.selectedMenuItems.fold(0.0, (s, m) => s + m.price);
  double get _servicesSubtotal =>
      widget.selectedServices.fold(0.0, (s, sv) => s + sv.price);
  double get _grandTotal => _hallRent + _menuSubtotal + _servicesSubtotal;
  double get _advancePayment => _grandTotal * 0.25;

  Future<void> _pickReceipt() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
    );
    if (image != null) setState(() => _receiptImage = File(image.path));
  }

  Future<void> _finalizeBooking() async {
    if (_receiptImage == null) {
      _showSnack('Please upload your payment receipt to continue', Colors.red);
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _showSnack('Session expired. Please log in again.', Colors.red);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await BookingService.createBooking(
        hallId: widget.hall.hallId,
        hallName: widget.hall.hallName,
        customerId: uid,
        customerName: widget.customerName,
        customerPhone: widget.customerPhone,
        customerCnic: widget.customerCnic,
        customerEmail: widget.customerEmail,
        eventName: widget.eventName,
        guestCount: widget.guestCount,
        timeSlot: widget.timeSlot,
        eventDate: widget.eventDate,
        selectedMenuItems: widget.selectedMenuItems,
        selectedServices: widget.selectedServices,
        hallRent: _hallRent,
        hallCapacityMax: widget.hall.capacityMax,
        receiptFile: _receiptImage!,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (result == 'SLOT_FULL') {
        _showSnack('Sorry! This slot just got fully booked.', Colors.red);
      } else if (result != null) {
        // ✅ SUCCESS — navigate to Congratulations screen
        // Customer will see "pending" status there, which updates in real-time
        // when the hall admin approves the booking.
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => CongratulationsScreen(bookingId: result),
          ),
          (route) => route.isFirst,
        );
      }
      // Note: createBooking now throws on error instead of returning null,
      // so this branch is unreachable — errors go to catch block below.
    } catch (e) {
      // ── FIX: Show the REAL error message, not the generic "check connection"
      //         This is how you find out the actual problem (permissions, bad
      //         API key, missing Storage rules, etc.)
      if (mounted) setState(() => _isSubmitting = false);

      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      _showDetailedError(errorMsg);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Shows a dialog with the full error — much more useful than a snackbar
  /// for debugging. In production you can replace this with _showSnack.
  void _showDetailedError(String errorMsg) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Booking Failed', style: TextStyle(fontSize: 16)),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(errorMsg, style: const TextStyle(fontSize: 13)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(4),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  _buildSummaryCard(),
                  const SizedBox(height: 20),
                  _buildBankDetails(),
                  const SizedBox(height: 24),
                  _buildUploadSection(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'Booking confirmed after admin verification.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _summaryRow('Hall Rent', 'Rs. ${_hallRent.toStringAsFixed(0)}'),
          if (widget.selectedMenuItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            _summaryRow('Menu', 'Rs. ${_menuSubtotal.toStringAsFixed(0)}'),
          ],
          const SizedBox(height: 16),
          _summaryRow(
            'Grand Total',
            'Rs. ${_grandTotal.toStringAsFixed(0)}',
            isBold: true,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Advance (25%)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Rs. ${_advancePayment.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF97316),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankDetails() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transfer Advance to:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0369A1),
            ),
          ),
          const SizedBox(height: 8),
          _bankRow('Bank', widget.hall.bankName),
          _bankRow('Account', widget.hall.bankAccountNumber),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return GestureDetector(
      onTap: _isSubmitting ? null : _pickReceipt,
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                _receiptImage != null
                    ? const Color(0xFF10B981)
                    : Colors.grey[300]!,
          ),
        ),
        child:
            _receiptImage != null
                ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_receiptImage!, fit: BoxFit.cover),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.red,
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 12,
                            color: Colors.white,
                          ),
                          onPressed: () => setState(() => _receiptImage = null),
                        ),
                      ),
                    ),
                  ],
                )
                : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload_outlined, size: 28),
                    Text('Tap to upload receipt'),
                  ],
                ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _finalizeBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF97316),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child:
            _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                  'Finalize Booking',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    );
  }

  Widget _summaryRow(String l, String v, {bool isBold = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        l,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      Text(
        v,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
        ),
      ),
    ],
  );

  Widget _bankRow(String l, String v) => Row(
    children: [
      SizedBox(width: 70, child: Text(l)),
      Text(': $v', style: const TextStyle(fontWeight: FontWeight.bold)),
    ],
  );

  Widget _buildStepIndicator(int step) => Container(
    padding: const EdgeInsets.all(16),
    child: Text("Step $step of 4: Payment"),
  );
}
