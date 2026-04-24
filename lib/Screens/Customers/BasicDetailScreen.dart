import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:venuemate_system/Models/hall_model.dart';
import 'EventDetailScreen.dart';

class BasicDetailsScreen extends StatefulWidget {
  final HallModel hall;

  const BasicDetailsScreen({super.key, required this.hall});

  @override
  State<BasicDetailsScreen> createState() => _BasicDetailsScreenState();
}

class _BasicDetailsScreenState extends State<BasicDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cnicController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill email from logged-in user if available
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _navigateToNext() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => EventDetailsScreen(
                hall: widget.hall,
                customerName: _fullNameController.text.trim(),
                customerPhone: _phoneController.text.trim(),
                customerCnic: _cnicController.text.trim(),
                customerEmail: _emailController.text.trim(),
              ),
        ),
      );
    }
  }

  // ── Validators ─────────────────────────────────────────────────────────────

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Full name is required';
    if (v.trim().length < 3) return 'Name must be at least 3 characters';
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number is required';
    final digits = v.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) {
      return 'Enter a valid phone number (e.g. 03XXXXXXXXX)';
    }
    if (!v.startsWith("03")) {
      return "Phone number must start with 03";
    }
    return null;
  }

  String? _validateCnic(String? v) {
    if (v == null || v.trim().isEmpty) return 'CNIC is required';
    final clean = v.trim().replaceAll('-', '');
    if (!RegExp(r'^\d{13}$').hasMatch(clean)) {
      return 'Enter CNIC in format XXXXXXXXXXXXX';
    }
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$').hasMatch(v.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Basic Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildStepIndicator(1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Basic Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildLabel('Full Name'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _fullNameController,
                      hintText: 'Enter your full name',
                      validator: _validateName,
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Phone Number'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _phoneController,
                      hintText: '03XXXXXXXXX',
                      keyboardType: TextInputType.phone,
                      validator: _validatePhone,
                      formatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('CNIC'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _cnicController,
                      hintText: 'XXXXXXXXXXXXX',
                      keyboardType: TextInputType.phone,
                      validator: _validateCnic,
                      formatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(13),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Email'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _emailController,
                      hintText: 'Enter your email',
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _navigateToNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Next',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared Widgets ─────────────────────────────────────────────────────────

  Widget _buildStepIndicator(int currentStep) {
    final steps = [
      'Basic Details',
      'Event Details',
      'Customize event',
      'Payment',
    ];
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children:
                steps.asMap().entries.map((e) {
                  final isActive = (e.key + 1) == currentStep;
                  return Expanded(
                    child: Center(
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive ? Colors.black : Colors.grey[400],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: List.generate(steps.length, (index) {
              final stepNum = index + 1;
              final isActive = stepNum == currentStep;
              final isDone = stepNum < currentStep;
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 3,
                      margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                      decoration: BoxDecoration(
                        color:
                            (isActive || isDone)
                                ? const Color(0xFFF97316)
                                : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color:
                            isDone
                                ? const Color(0xFF10B981)
                                : isActive
                                ? const Color(0xFFF97316)
                                : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child:
                            isDone
                                ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 14,
                                )
                                : Text(
                                  '$stepNum',
                                  style: TextStyle(
                                    color:
                                        isActive
                                            ? Colors.white
                                            : Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLabel(String label) => Text(
    label,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    ),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? formatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      validator:
          validator ??
          (v) => (v == null || v.isEmpty) ? 'This field is required' : null,
    );
  }
}
