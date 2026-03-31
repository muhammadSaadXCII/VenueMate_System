import 'package:flutter/material.dart';
import 'package:venuemate_system/Services/auth_service.dart';
import 'package:venuemate_system/Services/hall_service.dart';
import 'package:venuemate_system/Models/hall_model.dart';
import 'package:venuemate_system/Screens/HallAdmin/hall_admin_root.dart';
import 'package:venuemate_system/Screens/HallAdmin/hall_registration_intro.dart';
import 'package:venuemate_system/Widgets/common_button.dart';

class PendingReviewScreen extends StatefulWidget {
  const PendingReviewScreen({super.key});

  @override
  State<PendingReviewScreen> createState() => _PendingReviewScreenState();
}

class _PendingReviewScreenState extends State<PendingReviewScreen> {
  bool _isDeleting = false;
  bool _isChecking = false;

  // ── Manual refresh (for pending state) ────────────────────────────────────
  Future<void> _refreshStatus() async {
    setState(() => _isChecking = true);
    final uid = AuthService.currentUid;
    if (uid == null) {
      setState(() => _isChecking = false);
      return;
    }

    final hall = await HallService.getHallByOwnerId(uid);
    if (!mounted) return;
    setState(() => _isChecking = false);

    if (hall == null) return;

    if (hall.isApproved) {
      _goToDashboard();
    } else if (hall.isRejected) {
      // Stream will already show the rejected UI — no need for a dialog
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Still under review. Please check back later.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── "Start Over" — called after rejection confirmation ────────────────────
  Future<void> _startOver(String hallId) async {
    setState(() => _isDeleting = true);

    // Delete all hall data: Firestore docs + Storage files
    final error = await HallService.deleteHall(hallId);

    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Navigate back to intro — all hall data is gone, fresh start
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HallRegistrationIntroScreen()),
      (route) => false,
    );
  }

  // ── Confirmation dialog before deleting ───────────────────────────────────
  Future<void> _confirmStartOver(HallModel hall) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Column(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFF47C20),
                  size: 52,
                ),
                SizedBox(height: 12),
                Text(
                  'Start Over?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'This will permanently delete all data you submitted '
                  'for this hall (photos, documents, menu items, services).',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
                if (hall.rejectionReason.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Rejection reason: ${hall.rejectionReason}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              // Cancel — keep the rejected hall data visible
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Confirm delete + re-register
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF47C20),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Yes, Delete & Start Over',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      _startOver(hall.hallId);
    }
  }

  void _goToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HallAdminRootLayout()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.currentUid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body:
          uid == null
              ? const Center(child: Text('Please log in.'))
              : StreamBuilder<HallModel?>(
                stream: HallService.streamHallByOwnerId(uid),
                builder: (context, snap) {
                  final hall = snap.data;

                  // ── Auto-navigate when approved ──────────────────────────
                  if (hall != null && hall.isApproved) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _goToDashboard();
                    });
                  }

                  // ── Rejected state ───────────────────────────────────────
                  if (hall != null && hall.isRejected) {
                    return _buildRejectedUI(hall);
                  }

                  // ── Pending state (default) ──────────────────────────────
                  return _buildPendingUI(hall);
                },
              ),
    );
  }

  // ── PENDING UI ─────────────────────────────────────────────────────────────
  Widget _buildPendingUI(HallModel? hall) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated pending icon
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.orange.shade100,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.pending_actions,
                      size: 70,
                      color: Color(0xFFF47C20),
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    'Status: PENDING REVIEW',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Your hall "${hall?.hallName ?? 'your hall'}"\nis under review by the admin team.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "We'll notify you as soon as it's approved.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey[500]),
                  ),

                  const SizedBox(height: 40),

                  // Timeline indicator
                  Center(child: _buildTimeline()),
                ],
              ),
            ),
          ),
        ),

        // Bottom refresh button
        Padding(
          padding: const EdgeInsets.fromLTRB(30, 0, 30, 40),
          child:
              (_isChecking || _isDeleting)
                  ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF47C20)),
                  )
                  : CommonButton(
                    onTap: _refreshStatus,
                    text: 'Refresh Status',
                    icon: Icons.refresh_outlined,
                  ),
        ),
      ],
    );
  }

  // ── REJECTED UI ────────────────────────────────────────────────────────────
  Widget _buildRejectedUI(HallModel hall) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Big rejection icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red.shade100, width: 3),
                  ),
                  child: Icon(
                    Icons.cancel_outlined,
                    size: 65,
                    color: Colors.red.shade600,
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Registration Rejected',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  'Unfortunately, your hall registration was not approved.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Rejection reason card
                if (hall.rejectionReason.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.red.shade700,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Reason for Rejection',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hall.rejectionReason,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red.shade800,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // What happens next card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.blue.shade700,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'What to do next',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _tip('Review the rejection reason above carefully.'),
                      _tip('Tap "Start Over" to delete this submission.'),
                      _tip(
                        'Re-register your hall with the corrected information.',
                      ),
                      _tip('Re-submit for admin review.'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Hall info summary
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.store_outlined,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hall.hallName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hall.address.isNotEmpty
                                  ? hall.address
                                  : 'No address',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom action button
        Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            MediaQuery.of(context).padding.bottom + 24,
          ),
          child:
              _isDeleting
                  ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFFF47C20)),
                      const SizedBox(height: 12),
                      Text(
                        'Deleting hall data...',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  )
                  : SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmStartOver(hall),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF47C20),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Start Over & Re-register',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
        ),
      ],
    );
  }

  // ── Helper widgets ─────────────────────────────────────────────────────────
  Widget _tip(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ',
          style: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.blue.shade800,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildTimeline() {
    final steps = [
      ('You submitted your registration', true),
      ('Admin is reviewing your hall', true),
      ('Admin decision (pending…)', false),
      ('Hall goes live on VenueMate', false),
    ];
    return Column(
      children:
          steps.asMap().entries.map((e) {
            final i = e.key;
            final (label, done) = e.value;
            final isLast = i == steps.length - 1;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            done ? const Color(0xFFF47C20) : Colors.grey[300],
                        border: Border.all(
                          color:
                              done
                                  ? const Color(0xFFF47C20)
                                  : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child:
                          done
                              ? const Icon(
                                Icons.check,
                                size: 12,
                                color: Colors.white,
                              )
                              : null,
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 28,
                        color:
                            done ? const Color(0xFFF47C20) : Colors.grey[300],
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        color: done ? Colors.black87 : Colors.grey[400],
                        fontWeight: done ? FontWeight.w600 : FontWeight.normal,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
    );
  }
}
