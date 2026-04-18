import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'resolve_complaint_sheet.dart';

const double _kWebBreak = 900;

class ComplaintDetailsScreen extends StatelessWidget {
  final String complaintId;
  final Map<String, dynamic> data;

  /// When true the screen renders as a panel (no Scaffold/AppBar),
  /// used for the web master-detail split view.
  final bool inlineMode;

  const ComplaintDetailsScreen({
    super.key,
    required this.complaintId,
    required this.data,
    this.inlineMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('complaints')
              .doc(complaintId)
              .snapshots(),
      builder: (context, snap) {
        final d =
            snap.data?.exists == true
                ? snap.data!.data() as Map<String, dynamic>
                : data;

        final status = d['status'] as String? ?? 'Pending';
        final priority = d['priority'] as String? ?? 'Medium';
        final subject = d['subject'] as String? ?? '—';
        final desc = d['description'] as String? ?? '—';
        final userName = d['userName'] as String? ?? '—';
        final userRole = d['userRole'] as String? ?? '—';
        final attachUrl = d['attachmentUrl'] as String? ?? '';
        final ts = d['createdAt'] as Timestamp?;
        final dateStr = ts != null ? _fmtFull(ts.toDate()) : '—';
        final isResolved = status == 'Resolved';
        final (statusColor, statusBg) = _statusColors(status);

        // ── Shared body content ─────────────────────────────────────────
        Widget bodyContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: statusColor, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status: $status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Priority: $priority',
                        style: TextStyle(fontSize: 13, color: statusColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Complaint details
            _SectionTitle(title: 'Complaint Details'),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Submitted $dateStr',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                  const Divider(height: 30),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Color(0xFF4A4A4A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // User info
            _SectionTitle(title: 'User Information'),
            _card(
              child: Column(
                children: [
                  _infoRow(Icons.person_outline, 'Name', userName),
                  const SizedBox(height: 14),
                  _infoRow(Icons.work_outline, 'Role', userRole),
                  const SizedBox(height: 14),
                  _infoRow(Icons.access_time, 'Submitted', dateStr),
                ],
              ),
            ),

            // Attachment
            if (attachUrl.isNotEmpty) ...[
              const SizedBox(height: 24),
              _SectionTitle(title: 'Attached Proof'),
              _card(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    attachUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder:
                        (_, __, ___) => Container(
                          height: 80,
                          color: Colors.grey[100],
                          child: const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                  ),
                ),
              ),
            ],
          ],
        );

        // ── Action button (shared) ────────────────────────────────────────
        Widget actionBtn = SizedBox(
          height: 50,
          width: double.infinity,
          child: ElevatedButton(
            onPressed:
                isResolved ? null : () => _openResolve(context, inlineMode),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isResolved ? Colors.grey[300] : const Color(0xFFF47C20),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isResolved ? 'Already Resolved' : 'Mark as Resolved',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );

        // ── Inline mode (right pane on web) ─────────────────────────────
        if (inlineMode) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: bodyContent,
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
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: actionBtn,
              ),
            ],
          );
        }

        // ── Full-screen mode (mobile / navigated) ────────────────────────
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              '#${complaintId.substring(0, 8).toUpperCase()}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: bodyContent,
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: actionBtn,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openResolve(BuildContext context, bool inlineMode) {
    final isWide = MediaQuery.of(context).size.width >= _kWebBreak;

    if (isWide || inlineMode) {
      // On web: show as dialog instead of bottom sheet
      showDialog(
        context: context,
        builder:
            (_) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: ResolveComplaintSheet(
                  complaintId: complaintId,
                  isWide: isWide,
                ),
              ),
            ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        builder: (_) => ResolveComplaintSheet(complaintId: complaintId),
      );
    }
  }

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );

  Widget _infoRow(IconData icon, String label, String value) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.blue.shade700, size: 20),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ],
  );

  (Color, Color) _statusColors(String status) => switch (status) {
    'Resolved' => (Colors.green, Colors.green.shade50),
    'In Progress' => (Colors.blue, Colors.blue.shade50),
    _ => (Colors.red, Colors.red.shade50),
  };

  String _fmtFull(DateTime d) {
    const m = [
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
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12, left: 4),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    ),
  );
}
