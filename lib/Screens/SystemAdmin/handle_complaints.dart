import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:venuemate_system/Utils/app_navigation.dart';
import 'complaint_details.dart';

const double _kWebBreak = 900;

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});
  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  String _selectedFilter = 'New';

  // Web: selected complaint shown inline in right pane
  String? _selectedId;
  Map<String, dynamic>? _selectedData;

  Stream<QuerySnapshot> get _stream =>
      FirebaseFirestore.instance
          .collection('complaints')
          .orderBy('createdAt', descending: true)
          .snapshots();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= _kWebBreak;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
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
                  'User Complaints',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF47C20)),
                  );
                }
                final all = snap.data?.docs ?? [];

                final filtered =
                    _selectedFilter == 'All'
                        ? all
                        : all.where((d) {
                          final s =
                              (d.data() as Map)['status'] as String? ?? '';
                          if (_selectedFilter == 'New') {
                            return s == 'Pending' || s == 'In Progress';
                          }
                          return s == _selectedFilter;
                        }).toList();

                final newCount =
                    all.where((d) {
                      final s = (d.data() as Map)['status'] as String? ?? '';
                      return s == 'Pending';
                    }).length;

                return isWide
                    ? _buildWebLayout(filtered, newCount, all)
                    : _buildMobileLayout(filtered, newCount);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  MOBILE layout — original single-column list
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout(
    List<QueryDocumentSnapshot> filtered,
    int newCount,
  ) {
    return Column(
      children: [
        _filterBar(newCount, false),
        Expanded(
          child:
              filtered.isEmpty
                  ? _emptyState()
                  : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (_, i) {
                      final doc = filtered[i];
                      final data = doc.data() as Map<String, dynamic>;
                      return _ComplaintCard(
                        data: data,
                        isSelected: false,
                        onTap:
                            () => AppNavigation.push(
                              context,
                              ComplaintDetailsScreen(
                                complaintId: doc.id,
                                data: data,
                              ),
                            ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  WEB layout — left list + right detail pane
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout(
    List<QueryDocumentSnapshot> filtered,
    int newCount,
    List<QueryDocumentSnapshot> all,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left list (fixed width 420px) ─────────────────────────────────
        SizedBox(
          width: 420,
          child: Column(
            children: [
              _filterBar(newCount, true),
              Expanded(
                child:
                    filtered.isEmpty
                        ? _emptyState()
                        : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final doc = filtered[i];
                            final data = doc.data() as Map<String, dynamic>;
                            return _ComplaintCard(
                              data: data,
                              isSelected: _selectedId == doc.id,
                              onTap:
                                  () => setState(() {
                                    _selectedId = doc.id;
                                    _selectedData = data;
                                  }),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),

        // Vertical divider
        Container(width: 1, color: Colors.grey.shade200),

        // ── Right detail pane ──────────────────────────────────────────────
        Expanded(
          child:
              _selectedId == null
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select a complaint to view details',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                  : ComplaintDetailsScreen(
                    complaintId: _selectedId!,
                    data: _selectedData!,
                    inlineMode: true,
                  ),
        ),
      ],
    );
  }

  // ── Shared filter bar ─────────────────────────────────────────────────────
  Widget _filterBar(int newCount, bool isWide) => Container(
    color: isWide ? null : Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip('New', count: newCount),
          const SizedBox(width: 12),
          _chip('Resolved'),
          const SizedBox(width: 12),
          _chip('All'),
        ],
      ),
    ),
  );

  Widget _chip(String label, {int count = 0}) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap:
          () => setState(() {
            _selectedFilter = label;
            // Clear detail pane when filter changes
            _selectedId = null;
            _selectedData = null;
          }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF47C20) : Colors.grey[100],
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? const Color(0xFFF47C20) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.redAccent : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 12),
        Text('No complaints found.', style: TextStyle(color: Colors.grey[500])),
      ],
    ),
  );
}

// ── Complaint card ─────────────────────────────────────────────────────────
class _ComplaintCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final bool isSelected;

  const _ComplaintCard({
    required this.data,
    required this.onTap,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final priority = data['priority'] as String? ?? 'Medium';
    final ts = data['createdAt'] as Timestamp?;
    final dateStr = ts != null ? _fmt(ts.toDate()) : '—';

    final priorityColor = switch (priority) {
      'High' => Colors.redAccent,
      'Medium' => Colors.orange,
      _ => Colors.green,
    };

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF4EC) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isSelected ? const Color(0xFFF47C20) : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4F8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#${(data['userId'] as String? ?? '').substring(0, 6).toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
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
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: Color(0xFFF1F5F9),
                    child: Icon(Icons.person, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['subject'] ?? '—',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${data['userName'] ?? '—'} (${data['userRole'] ?? '—'})',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.flag, size: 16, color: priorityColor),
                      const SizedBox(width: 6),
                      Text(
                        '$priority Priority',
                        style: TextStyle(
                          color: priorityColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Review Details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.day}/${d.month}/${d.year}';
  }
}
