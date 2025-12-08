import 'package:flutter/material.dart';
import 'package:venuemate_system/Screens/SystemAdmin/resolve_complaint_sheet.dart';

class ComplaintDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> complaint;
  const ComplaintDetailsScreen({super.key, required this.complaint});

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          "Ticket #CMP-001",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 900) {
            return _buildDesktopLayout(context);
          } else {
            return _buildMobileLayout(context);
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(right: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(title: "Complaint Details"),
                      _buildDetailCard(isDesktop: true),
                      const SizedBox(height: 32),
                      _SectionHeader(title: "Attached Proof"),
                      _buildProofSection(isDesktop: true),
                    ],
                  ),
                ),
              ),

              Expanded(
                flex: 4,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildStatusBanner(isDesktop: true),
                      const SizedBox(height: 24),
                      _buildUserInfoCard(isDesktop: true),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => _openResolveSheet(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF47C20),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            "Mark as Resolved",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusBanner(isDesktop: false),
              const SizedBox(height: 24),
              _SectionHeader(title: "Complaint Details"),
              _buildDetailCard(isDesktop: false),
              const SizedBox(height: 24),
              _SectionHeader(title: "User Information"),
              _buildUserInfoCard(isDesktop: false),
              const SizedBox(height: 24),
              _SectionHeader(title: "Attached Proof"),
              _buildProofSection(isDesktop: false),
            ],
          ),
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
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () => _openResolveSheet(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF47C20),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Mark as Resolved",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openResolveSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const ResolveComplaintSheet(),
    );
  }

  Widget _buildStatusBanner({required bool isDesktop}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Status: Pending Review",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[800],
                    fontSize: 15,
                  ),
                ),
                Text(
                  "Priority: High",
                  style: TextStyle(fontSize: 13, color: Colors.red[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({required bool isDesktop}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Booking Cancelled without Refund",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Submitted 2 hours ago",
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          const Divider(height: 30),
          const Text(
            "I booked the hall for 25th Oct, but the owner cancelled it last minute saying they have another event. I have already paid the advance via bank transfer and he is refusing to refund me.",
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Color(0xFF4A4A4A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard({required bool isDesktop}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: "User Information", padding: EdgeInsets.zero),
          const SizedBox(height: 16),
          _InfoItem(
            icon: Icons.person_outline,
            label: "Name",
            value: complaint['user'] ?? "Zulhaq Hussain",
          ),
          const SizedBox(height: 16),
          _InfoItem(
            icon: Icons.work_outline,
            label: "Role",
            value: complaint['role'] ?? "Customer",
          ),
          const SizedBox(height: 16),
          _InfoItem(
            icon: Icons.access_time,
            label: "Submitted",
            value: complaint['date'] ?? "Oct 24, 2025",
          ),
        ],
      ),
    );
  }

  Widget _buildProofSection({required bool isDesktop}) {
    final proofs = "receipt.png";

    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image, color: Colors.grey, size: 32),
          const SizedBox(height: 8),
          Text(
            proofs,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
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
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final EdgeInsetsGeometry padding;

  const _SectionHeader({
    required this.title,
    this.padding = const EdgeInsets.only(bottom: 12, left: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
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
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
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
  }
}
