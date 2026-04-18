import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:venuemate_system/Services/auth_service.dart';
import 'package:venuemate_system/Services/user_service.dart';
import 'package:venuemate_system/Services/storage_service.dart';
import 'package:venuemate_system/Widgets/common_button.dart';

class FileComplaintScreen extends StatefulWidget {
  const FileComplaintScreen({super.key});
  @override
  State<FileComplaintScreen> createState() => _FileComplaintScreenState();
}

class _FileComplaintScreenState extends State<FileComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  String? _selectedCategory;
  String? _selectedPriority;

  // Cross-platform: XFile + bytes instead of dart:io File
  XFile? _attachmentXFile;
  Uint8List? _attachmentBytes;

  bool _isSubmitting = false;

  final List<String> _categories = [
    'Payment Dispute',
    'Technical Issue',
    'Account Verification',
    'Feature Request',
    'Other',
  ];

  final List<String> _priorities = ['High', 'Medium', 'Low'];

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  // ── Pick screenshot ─────────────────────────────────────────────────────
  Future<void> _pickAttachment() async {
    final xf = await StorageService.pickImageXFile();
    if (xf == null || !mounted) return;
    final bytes = await xf.readAsBytes();
    setState(() {
      _attachmentXFile = xf;
      _attachmentBytes = bytes;
    });
  }

  // ── Submit complaint to Firestore ────────────────────────────────────────
  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _snack('Please select a category.', isError: true);
      return;
    }
    if (_selectedPriority == null) {
      _snack('Please select a priority level.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final uid = AuthService.currentUid ?? '';
      final user = await UserService.getUserById(uid);
      final userName = user?.name ?? 'User';
      final userRole = user?.isVenueOwner == true ? 'Hall Admin' : 'Customer';

      String attachmentUrl = '';
      if (_attachmentBytes != null) {
        final complaintId = const Uuid().v4();
        attachmentUrl = await _uploadAttachment(complaintId) ?? '';
      }

      await FirebaseFirestore.instance.collection('complaints').add({
        'userId': uid,
        'userName': userName,
        'userRole': userRole,
        'subject': _subjectCtrl.text.trim(),
        'category': _selectedCategory,
        'priority': _selectedPriority,
        'description': _descriptionCtrl.text.trim(),
        'attachmentUrl': attachmentUrl,
        'status': 'Pending',
        'adminResponse': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await _showSuccessDialog();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _snack('Failed to submit complaint. Please try again.', isError: true);
    }
  }

  // ── Upload using putData(bytes) — works on web + mobile ─────────────────
  Future<String?> _uploadAttachment(String complaintId) async {
    try {
      if (_attachmentBytes == null) return null;
      final ref = FirebaseStorage.instance.ref().child(
        'complaints/$complaintId/attachment.jpg',
      );
      await ref.putData(
        _attachmentBytes!,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  Future<void> _showSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Column(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 52),
                SizedBox(height: 12),
                Text(
                  'Complaint Submitted!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
            content: Text(
              'Your complaint has been filed successfully.\nOur team will review it and get back to you shortly.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], height: 1.5),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
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
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor:
          isWide ? const Color(0xFFF5F7FA) : const Color(0xFFF9FAFB),
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
          'New Ticket',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(
              margin: EdgeInsets.all(isWide ? 24 : 0),
              padding: EdgeInsets.all(isWide ? 32 : 20),
              decoration: BoxDecoration(
                color: isWide ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: isWide ? Border.all(color: Colors.grey.shade200) : null,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ticket Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Describe the issue you are facing with the platform.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 25),

                    _label('Subject'),
                    _textField(
                      controller: _subjectCtrl,
                      hint: 'e.g. Payout not received',
                      validator:
                          (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Subject is required'
                                  : null,
                    ),
                    const SizedBox(height: 20),

                    _label('Category'),
                    _dropdown(
                      hint: 'Select Category',
                      value: _selectedCategory,
                      items: _categories,
                      onChanged: (v) => setState(() => _selectedCategory = v),
                    ),
                    const SizedBox(height: 20),

                    _label('Priority Level'),
                    _dropdown(
                      hint: 'Select Priority',
                      value: _selectedPriority,
                      items: _priorities,
                      onChanged: (v) => setState(() => _selectedPriority = v),
                    ),
                    const SizedBox(height: 20),

                    _label('Description'),
                    _textField(
                      controller: _descriptionCtrl,
                      hint: 'Describe your issue in detail...',
                      maxLines: 5,
                      validator:
                          (v) =>
                              (v == null || v.trim().length < 10)
                                  ? 'Please provide more details (at least 10 chars)'
                                  : null,
                    ),
                    const SizedBox(height: 20),

                    _label('Attachments (Optional)'),
                    _attachmentBox(),

                    if (isWide) ...[
                      const SizedBox(height: 40),
                      _isSubmitting
                          ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFF47C20),
                            ),
                          )
                          : CommonButton(
                            text: 'Submit Complaint',
                            onTap: _submitComplaint,
                          ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar:
          isWide
              ? null
              : Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
                ),
                child:
                    _isSubmitting
                        ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFF47C20),
                          ),
                        )
                        : CommonButton(
                          text: 'Submit Complaint',
                          onTap: _submitComplaint,
                        ),
              ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    ),
  );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF47C20)),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          isExpanded: true,
          items:
              items
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _attachmentBox() {
    return GestureDetector(
      onTap: _pickAttachment,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                _attachmentBytes != null
                    ? const Color(0xFFF47C20)
                    : Colors.grey.shade300,
            width: _attachmentBytes != null ? 2 : 1,
          ),
        ),
        child:
            _attachmentBytes != null
                ? Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      // ✅ Image.memory — works on web + mobile
                      child: Image.memory(_attachmentBytes!, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap:
                            () => setState(() {
                              _attachmentXFile = null;
                              _attachmentBytes = null;
                            }),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
                : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 32,
                      color: Colors.grey,
                    ),
                    Text(
                      'Tap to upload screenshot',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
