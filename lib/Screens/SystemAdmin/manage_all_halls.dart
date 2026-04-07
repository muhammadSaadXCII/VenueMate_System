import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:venuemate_system/Models/hall_model.dart';
import 'package:venuemate_system/Services/hall_service.dart';
import 'package:venuemate_system/Utils/app_navigation.dart';
import 'manage_hall_details.dart';

const double _kWebBreak = 900;

// ── Debouncer Utility ────────────────────────────────────────────────────────
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

class ManageAllHallsScreen extends StatefulWidget {
  const ManageAllHallsScreen({super.key});
  @override
  State<ManageAllHallsScreen> createState() => _ManageAllHallsScreenState();
}

class _ManageAllHallsScreenState extends State<ManageAllHallsScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 400); // 400ms delay for search

  late Stream<List<HallModel>> _hallsStream;
  HallModel? _selectedHall;

  final List<String> _filters = ['All', 'Approved', 'Pending', 'Rejected'];

  @override
  void initState() {
    super.initState();
    // Initialize stream once to prevent re-subscriptions on every rebuild
    _hallsStream = HallService.streamAllHalls();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<HallModel> _applyFilters(List<HallModel> all) {
    var list = all;
    if (_selectedFilter != 'All') {
      final map = {
        'Approved': 'approved',
        'Pending': 'pending',
        'Rejected': 'rejected',
      };
      list = list.where((h) => h.status == map[_selectedFilter]).toList();
    }
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
                  'Manage All Halls',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      body: StreamBuilder<List<HallModel>>(
        stream: _hallsStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFF47C20)),
            );
          }
          final filtered = _applyFilters(snap.data ?? []);
          return isWide
              ? _buildWebLayout(filtered)
              : _buildMobileLayout(filtered);
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  MOBILE layout
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout(List<HallModel> filtered) => Column(
    children: [
      _searchAndFilters(false),
      Expanded(
        child:
            filtered.isEmpty
                ? _emptyState()
                : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder:
                      (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _HallCard(
                          hall: filtered[i],
                          isSelected: false,
                          onTap:
                              () => AppNavigation.push(
                                context,
                                ManageHallDetailsScreen(hall: filtered[i]),
                              ),
                        ),
                      ),
                ),
      ),
    ],
  );

  // ══════════════════════════════════════════════════════════════════════════
  //  WEB layout — Left List + Right Detail
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout(List<HallModel> filtered) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 440,
        child: Column(
          children: [
            _searchAndFilters(true),
            Expanded(
              child:
                  filtered.isEmpty
                      ? _emptyState()
                      : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        itemBuilder:
                            (_, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _HallCard(
                                hall: filtered[i],
                                isSelected:
                                    _selectedHall?.hallId == filtered[i].hallId,
                                onTap:
                                    () => setState(
                                      () => _selectedHall = filtered[i],
                                    ),
                              ),
                            ),
                      ),
            ),
          ],
        ),
      ),
      Container(width: 1, color: Colors.grey.shade200),
      Expanded(
        child:
            _selectedHall == null
                ? _buildNoSelection()
                : ManageHallDetailsScreen(
                  // ValueKey resets the detail screen state when a different hall is selected
                  key: ValueKey(_selectedHall!.hallId),
                  hall: _selectedHall!,
                  inlineMode: true,
                  onHallUpdated: (h) {
                    // Only update if visibility or status changed to avoid redundant rebuilds
                    if (_selectedHall?.isVisible != h.isVisible ||
                        _selectedHall?.status != h.status) {
                      setState(() => _selectedHall = h);
                    }
                  },
                ),
      ),
    ],
  );

  Widget _buildNoSelection() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.business_outlined, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text(
          'Select a hall to view details',
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
        ),
      ],
    ),
  );

  Widget _searchAndFilters(bool isWide) => Container(
    color: isWide ? null : Colors.white,
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
    child: Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) {
              // Run debouncer: only rebuild list 400ms after user stops typing
              _debouncer.run(() {
                setState(() => _searchQuery = v.trim());
              });
            },
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
  );

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

  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.business_outlined, size: 64, color: Colors.grey[300]),
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

class _HallCard extends StatelessWidget {
  final HallModel hall;
  final VoidCallback onTap;
  final bool isSelected;
  const _HallCard({
    required this.hall,
    required this.onTap,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final image = hall.imageUrls.isNotEmpty ? hall.imageUrls.first : '';
    final (statusLabel, statusBg, statusFg) = _statusColors(hall.status);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 120,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF4EC) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFF47C20) : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              height: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
                child:
                    image.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: image,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _imgPh(),
                        )
                        : _imgPh(),
              ),
            ),
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
                                hall.address.isEmpty
                                    ? 'No address'
                                    : hall.address,
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
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Colors.grey[400],
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
    );
  }

  Widget _imgPh() => Container(
    color: Colors.grey[200],
    child: const Center(
      child: Icon(Icons.business, color: Colors.grey, size: 36),
    ),
  );

  (String, Color, Color) _statusColors(String status) => switch (status) {
    'approved' => (
      'Approved',
      const Color(0xFFE6F7ED),
      const Color(0xFF00B85E),
    ),
    'pending' => ('Pending', const Color(0xFFFFF8E1), const Color(0xFFF9A825)),
    'rejected' => (
      'Rejected',
      const Color(0xFFFFF0F1),
      const Color(0xFFD92D20),
    ),
    _ => ('Unknown', Colors.grey.shade100, Colors.grey),
  };
}
