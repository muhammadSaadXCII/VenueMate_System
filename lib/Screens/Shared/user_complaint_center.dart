import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:venuemate_system/Services/auth_service.dart';
import 'package:venuemate_system/Widgets/common_button.dart';
import 'user_complaint_details.dart';
import 'file_complaint.dart';

class UserComplaintCenterScreen extends StatefulWidget {
  const UserComplaintCenterScreen({super.key});
  @override
  State<UserComplaintCenterScreen> createState() =>
      _UserComplaintCenterScreenState();
}

class _UserComplaintCenterScreenState extends State<UserComplaintCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _uid = AuthService.currentUid ?? '';

  // Web State
  String? _selectedId;
  Map<String, dynamic>? _selectedData;

  // Stream only THIS user's complaints, newest first
  Stream<QuerySnapshot> get _complaintsStream =>
      FirebaseFirestore.instance
          .collection('complaints')
          .where('userId', isEqualTo: _uid)
          .snapshots();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar:
          isWide
              ? null
              : AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                scrolledUnderElevation: 0,
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text(
                  'Complaints Center',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      body:
          _uid.isEmpty
              ? const Center(child: Text('Please log in to view complaints.'))
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isWide) ...[
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.arrow_back),
                    ),
                  ],

                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _complaintsStream,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFF47C20),
                            ),
                          );
                        }
                        final all = snap.data?.docs ?? [];

                        final pending =
                            all
                                .where(
                                  (d) =>
                                      (d.data() as Map)['status'] != 'Resolved',
                                )
                                .toList();
                        final resolved =
                            all
                                .where(
                                  (d) =>
                                      (d.data() as Map)['status'] == 'Resolved',
                                )
                                .toList();

                        if (isWide) {
                          return _buildWebLayout(pending, resolved);
                        }

                        return _buildMobileLayout(pending, resolved);
                      },
                    ),
                  ),
                ],
              ),

      // ── File new complaint button (Mobile only) ───────────────────────
      bottomNavigationBar:
          isWide
              ? null
              : Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
                ),
                child: CommonButton(
                  text: 'File New Complaint',
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FileComplaintScreen(),
                        ),
                      ),
                ),
              ),
    );
  }

  // ── Web Layout (Master-Detail) ──────────────────────────────────────────
  Widget _buildWebLayout(
    List<QueryDocumentSnapshot> pending,
    List<QueryDocumentSnapshot> resolved,
  ) {
    return Row(
      children: [
        // Left Sidebar List
        SizedBox(
          width: 420,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: CommonButton(
                  text: 'File New Complaint',
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FileComplaintScreen(),
                        ),
                      ),
                ),
              ),
              _pillTabs(pending.length, resolved.length),
              const SizedBox(height: 10),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _TicketList(
                      docs: pending,
                      selectedId: _selectedId,
                      onSelect:
                          (id, data) => setState(() {
                            _selectedId = id;
                            _selectedData = data;
                          }),
                    ),
                    _TicketList(
                      docs: resolved,
                      selectedId: _selectedId,
                      onSelect:
                          (id, data) => setState(() {
                            _selectedId = id;
                            _selectedData = data;
                          }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        // Right Detail Pane
        Expanded(
          child:
              _selectedId == null
                  ? const Center(child: Text('Select a ticket to view details'))
                  : UserComplaintDetailsScreen(
                    key: ValueKey(
                      _selectedId,
                    ), // Force refresh when selection changes
                    complaintId: _selectedId!,
                    data: _selectedData!,
                    inlineMode: true,
                  ),
        ),
      ],
    );
  }

  // ── Mobile Layout ───────────────────────────────────────────────────────
  Widget _buildMobileLayout(
    List<QueryDocumentSnapshot> pending,
    List<QueryDocumentSnapshot> resolved,
  ) {
    return Column(
      children: [
        const SizedBox(height: 20),
        _pillTabs(pending.length, resolved.length),
        const SizedBox(height: 20),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_TicketList(docs: pending), _TicketList(docs: resolved)],
          ),
        ),
      ],
    );
  }

  Widget _pillTabs(int pendingLength, int resolvedLength) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: const Color(0xFFF47C20),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF47C20).withOpacity(0.3),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: [
          Tab(text: 'Pending ($pendingLength)'),
          Tab(text: 'Resolved ($resolvedLength)'),
        ],
      ),
    );
  }
}

class _TicketList extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final String? selectedId;
  final Function(String, Map<String, dynamic>)? onSelect;

  const _TicketList({required this.docs, this.selectedId, this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_turned_in_outlined,
              size: 60,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 10),
            Text('No tickets found', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: docs.length,
      itemBuilder: (_, i) {
        final data = docs[i].data() as Map<String, dynamic>;
        final id = docs[i].id;
        final isSelected = selectedId == id;

        return _TicketCard(
          complaintId: id,
          data: data,
          isSelected: isSelected,
          onTap: () {
            if (onSelect != null) {
              onSelect!(id, data);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => UserComplaintDetailsScreen(
                        complaintId: id,
                        data: data,
                      ),
                ),
              );
            }
          },
        );
      },
    );
  }
}

class _TicketCard extends StatelessWidget {
  final String complaintId;
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final bool isSelected;

  const _TicketCard({
    required this.complaintId,
    required this.data,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? 'Pending';
    final priority = data['priority'] as String? ?? 'Medium';
    final ts = data['createdAt'] as Timestamp?;
    final dateStr = ts != null ? _fmt(ts.toDate()) : '—';

    final (statusColor, statusBg) = _statusColors(status);
    final shortId = '#TKT-${complaintId.substring(0, 6).toUpperCase()}';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF4EC) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isSelected ? const Color(0xFFF47C20) : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    shortId,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data['subject'] ?? '—',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Category: ${data['category'] ?? '—'}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.grey[200]),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      _priorityLabel(priority),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _priorityColor(priority),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  (Color, Color) _statusColors(String status) => switch (status) {
    'Resolved' => (Colors.green, Colors.green.shade50),
    'In Progress' => (Colors.blue, Colors.blue.shade50),
    _ => (const Color(0xFFF47C20), const Color(0xFFFFF3E0)),
  };

  Color _priorityColor(String p) => switch (p) {
    'High' => Colors.redAccent,
    'Medium' => Colors.orange,
    _ => Colors.green,
  };

  String _priorityLabel(String p) => '$p Priority';

  String _fmt(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.day}/${d.month}/${d.year}';
  }
}
