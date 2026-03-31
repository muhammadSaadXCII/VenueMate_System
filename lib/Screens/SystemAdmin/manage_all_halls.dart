import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:venuemate_system/Models/hall_model.dart';
import 'package:venuemate_system/Services/hall_service.dart';
import 'package:venuemate_system/Utils/app_navigation.dart';
import 'manage_hall_details.dart';

class ManageAllHallsScreen extends StatefulWidget {
  const ManageAllHallsScreen({super.key});

  @override
  State<ManageAllHallsScreen> createState() => _ManageAllHallsScreenState();
}

class _ManageAllHallsScreenState extends State<ManageAllHallsScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  final List<String> _filters = ['All', 'Approved', 'Pending', 'Rejected'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Filter + search logic on the streamed list ─────────────────────────────
  List<HallModel> _apply(List<HallModel> all) {
    var list = all;

    // Filter by status
    if (_selectedFilter != 'All') {
      final statusMap = {
        'Approved': 'approved',
        'Pending': 'pending',
        'Rejected': 'rejected',
      };
      list = list.where((h) => h.status == statusMap[_selectedFilter]).toList();
    }

    // Search by name or address
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list =
          list
              .where(
                (h) =>
                    h.hallName.toLowerCase().contains(q) ||
                    h.address.toLowerCase().contains(q),
              )
              .toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
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
          'Manage All Halls',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Search + filters ─────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              children: [
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search halls by name or location...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                      suffixIcon:
                          _searchQuery.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                              : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        _filters
                            .map(
                              (f) => Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: _filterChip(f),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
            ),
          ),

          // ── Live list ────────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<HallModel>>(
              stream: HallService.streamAllHalls(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF47C20)),
                  );
                }
                final filtered = _apply(snap.data ?? []);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.business_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty || _selectedFilter != 'All'
                              ? 'No halls match your search.'
                              : 'No halls registered yet.',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder:
                      (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _HallCard(
                          hall: filtered[i],
                          onTap:
                              () => AppNavigation.push(
                                context,
                                ManageHallDetailsScreen(hall: filtered[i]),
                              ),
                        ),
                      ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    final isActive = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF47C20) : Colors.grey[100],
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isActive ? Colors.transparent : Colors.grey.shade300,
          ),
          boxShadow:
              isActive
                  ? [
                    BoxShadow(
                      color: const Color(0xFFF47C20).withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                  : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Hall card ─────────────────────────────────────────────────────────────
class _HallCard extends StatelessWidget {
  final HallModel hall;
  final VoidCallback onTap;
  const _HallCard({required this.hall, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final image = hall.imageUrls.isNotEmpty ? hall.imageUrls.first : '';
    final (statusLabel, statusBg, statusFg) = _statusColors(hall.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              // Image
              SizedBox(
                width: 120,
                height: double.infinity,
                child:
                    image.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: image,
                          fit: BoxFit.cover,
                          placeholder:
                              (_, __) => Container(color: Colors.grey[200]),
                          errorWidget: (_, __, ___) => _imgPlaceholder(),
                        )
                        : _imgPlaceholder(),
              ),
              // Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hall.hallName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3436),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  hall.address.isNotEmpty
                                      ? hall.address
                                      : 'No address',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusFg,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Manage button
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Manage',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 12,
                                  color: Colors.grey[700],
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _imgPlaceholder() => Container(
    color: Colors.grey[200],
    child: const Center(
      child: Icon(Icons.business, color: Colors.grey, size: 36),
    ),
  );

  (String, Color, Color) _statusColors(String status) {
    return switch (status) {
      'approved' => (
        'Approved',
        const Color(0xFFE6F7ED),
        const Color(0xFF00B85E),
      ),
      'pending' => (
        'Pending',
        const Color(0xFFFFF8E1),
        const Color(0xFFF9A825),
      ),
      'rejected' => (
        'Rejected',
        const Color(0xFFFFF0F1),
        const Color(0xFFD92D20),
      ),
      _ => ('Unknown', Colors.grey.shade100, Colors.grey),
    };
  }
}
