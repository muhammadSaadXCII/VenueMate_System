import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:venuemate_system/Services/notification_service.dart';

class ResolveComplaintSheet extends StatefulWidget {
  final String complaintId;
  final bool isWide;
  const ResolveComplaintSheet({
    super.key,
    required this.complaintId,
    this.isWide = false,
  });
  @override
  State<ResolveComplaintSheet> createState() => _ResolveComplaintSheetState();
}

class _ResolveComplaintSheetState extends State<ResolveComplaintSheet> {
  final _responseCtrl = TextEditingController();
  bool _isResolving = false;

  @override
  void dispose() {
    _responseCtrl.dispose();
    super.dispose();
  }

  Future<void> _resolve() async {
    final response = _responseCtrl.text.trim();
    if (response.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please type a response before resolving.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isResolving = true);

    try {
      final complaintRef = FirebaseFirestore.instance
          .collection('complaints')
          .doc(widget.complaintId);

      // Fetch userId + subject before updating (for notification)
      String complaintUserId = '';
      String complaintSubject = '';
      try {
        final snap = await complaintRef.get();
        final d = snap.data() ?? {};
        complaintUserId = (d['userId'] as String?) ?? '';
        complaintSubject = (d['subject'] as String?) ?? '';
      } catch (_) {}

      await complaintRef.update({
        'status': 'Resolved',
        'adminResponse': response,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notify the user who filed the complaint
      if (complaintUserId.isNotEmpty) {
        unawaited(
          NotificationService.sendComplaintResolved(
            userUid: complaintUserId,
            complaintId: widget.complaintId,
            subject: complaintSubject,
          ),
        );
      }

      if (!mounted) return;
      Navigator.pop(context); // close sheet
      if (!widget.isWide) {
        Navigator.pop(context); // back to list
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complaint resolved successfully.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isResolving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resolve: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Resolve Ticket',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Provide a closing response for the user before resolving.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),

              const Text(
                'Admin Response',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _responseCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Type your response here...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
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
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isResolving ? null : _resolve,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF47C20),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isResolving
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text(
                            'Confirm Resolution',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
