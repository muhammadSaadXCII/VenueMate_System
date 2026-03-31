import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:venuemate_system/Models/hall_model.dart';
import 'package:venuemate_system/Services/hall_service.dart';
import 'package:venuemate_system/Services/service_item_service.dart';
import 'package:venuemate_system/Utils/app_navigation.dart';
import 'VenueDetailScreen.dart';

class FilterSearchScreen extends StatefulWidget {
  const FilterSearchScreen({super.key});
  @override
  State<FilterSearchScreen> createState() => _FilterSearchScreenState();
}

class _FilterSearchScreenState extends State<FilterSearchScreen> {
  // ── Filter state (identical to original) ──────────────────────────────
  int guestCount = 50;
  RangeValues priceRange = const RangeValues(5000, 50000);
  final double minPrice = 0;
  final double maxPrice = 100000;
  String selectedLocation = 'nearby';

  final List<ServiceItem> services = [
    ServiceItem(id: '1', name: 'Photography', icon: Icons.camera_alt),
    ServiceItem(id: '2', name: 'Catering', icon: Icons.restaurant),
    ServiceItem(id: '3', name: 'Decoration', icon: Icons.celebration),
    ServiceItem(id: '4', name: 'Music & DJ', icon: Icons.music_note),
    ServiceItem(id: '5', name: 'Lighting', icon: Icons.light_mode),
    ServiceItem(id: '6', name: 'Transportation', icon: Icons.directions_car),
    ServiceItem(id: '7', name: 'Makeup', icon: Icons.face),
    ServiceItem(id: '8', name: 'Video', icon: Icons.videocam),
  ];

  // ── Search results ─────────────────────────────────────────────────────
  List<HallModel> _results = [];
  bool _hasSearched = false;
  bool _isSearching = false;

  // ──────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Filter & Search',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: Text(
              'Reset',
              style: TextStyle(
                color: Colors.orange.shade600,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. Number of Guests ─────────────────────────────────────
                  _buildSectionCard(
                    title: 'Number of Guests',
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildCounterButton(
                              icon: Icons.remove,
                              onPressed: () {
                                if (guestCount > 10) {
                                  setState(() => guestCount -= 10);
                                }
                              },
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.orange.shade400,
                                    Colors.orange.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '$guestCount',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Guests',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildCounterButton(
                              icon: Icons.add,
                              onPressed: () {
                                if (guestCount < 1000) {
                                  setState(() => guestCount += 10);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Slider(
                          value: guestCount.toDouble(),
                          min: 10,
                          max: 1000,
                          divisions: 99,
                          activeColor: Colors.orange,
                          inactiveColor: Colors.orange.shade100,
                          onChanged:
                              (v) => setState(() => guestCount = v.toInt()),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '10',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '1000',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── 2. Price Range ──────────────────────────────────────────
                  _buildSectionCard(
                    title: 'Price Range',
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildPriceChip(
                              'Min',
                              'PKR ${_formatPrice(priceRange.start)}',
                              Colors.orange.shade50,
                              Colors.orange.shade700,
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Icon(
                                Icons.arrow_forward,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                            ),
                            _buildPriceChip(
                              'Max',
                              'PKR ${_formatPrice(priceRange.end)}',
                              Colors.green.shade50,
                              Colors.green.shade700,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        RangeSlider(
                          values: priceRange,
                          min: minPrice,
                          max: maxPrice,
                          divisions: 100,
                          activeColor: Colors.orange,
                          inactiveColor: Colors.orange.shade100,
                          labels: RangeLabels(
                            'PKR ${_formatPrice(priceRange.start)}',
                            'PKR ${_formatPrice(priceRange.end)}',
                          ),
                          onChanged: (v) => setState(() => priceRange = v),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PKR ${_formatPrice(minPrice)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'PKR ${_formatPrice(maxPrice)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── 3. Search Location ──────────────────────────────────────
                  _buildSectionCard(
                    title: 'Search Location',
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildLocationOption(
                                'Nearby',
                                Icons.filter_list_rounded,
                                'nearby',
                                'Filters only, no location used',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildLocationOption(
                                'My Location',
                                Icons.my_location_rounded,
                                'current',
                                'Halls within 2 km of you',
                              ),
                            ),
                          ],
                        ),
                        if (selectedLocation == 'current') ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Only halls within 2 km of your current GPS position will be shown.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue.shade900,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── 4. Additional Services ──────────────────────────────────
                  _buildSectionCard(
                    title: 'Additional Services',
                    subtitle: 'Select services you need',
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children:
                              services
                                  .map((s) => _buildServiceItem(s))
                                  .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── 5. Results (shown after search) ────────────────────────
                  if (_isSearching)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                          color: Color(0xFFF47C20),
                        ),
                      ),
                    ),

                  if (_hasSearched && !_isSearching) ...[
                    Text(
                      _results.isEmpty
                          ? 'No venues match your filters.'
                          : '${_results.length} venue${_results.length == 1 ? '' : 's'} found',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_results.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Try adjusting your filters.',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._results.map((h) => _buildResultCard(h)),
                  ],
                ],
              ),
            ),
          ),

          // ── Search button ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade400,
                            Colors.orange.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSearching ? null : _applyFilters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Search Venues',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
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
    );
  }

  // ── Result card ────────────────────────────────────────────────────────
  Widget _buildResultCard(HallModel h) {
    final img = h.imageUrls.isNotEmpty ? h.imageUrls.first : '';
    return GestureDetector(
      onTap:
          () =>
              AppNavigation.push(context, VenueDetailsScreen(hallId: h.hallId)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
              child:
                  img.isNotEmpty
                      ? CachedNetworkImage(
                        imageUrl: img,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        placeholder:
                            (_, __) => Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[200],
                            ),
                        errorWidget:
                            (_, __, ___) => Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.business,
                                color: Colors.grey,
                              ),
                            ),
                      )
                      : Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[200],
                        child: const Icon(Icons.business, color: Colors.grey),
                      ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h.hallName,
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
                            h.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 12,
                          color: Color(0xFFF47C20),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${h.capacityMin}–${h.capacityMax} Guests',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          h.priceLabel,
                          style: const TextStyle(
                            color: Color(0xFFF47C20),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              h.ratingCount == 0
                                  ? 'New'
                                  : h.ratingAvg.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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

  // ── Apply filters ──────────────────────────────────────────────────────
  Future<void> _applyFilters() async {
    final selectedServiceNames =
        services.where((s) => s.isSelected).map((s) => s.name).toList();

    // ── Summary dialog (same as original) ─────────────────────────────
    final shouldSearch =
        await showDialog<bool>(
          context: context,
          builder:
              (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.orange,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Filters Applied',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryItem(
                      Icons.people,
                      'Guests',
                      '$guestCount people',
                    ),
                    _buildSummaryItem(
                      Icons.attach_money,
                      'Budget',
                      'PKR ${_formatPrice(priceRange.start)} - PKR ${_formatPrice(priceRange.end)}',
                    ),
                    _buildSummaryItem(
                      selectedLocation == 'nearby'
                          ? Icons.filter_list
                          : Icons.my_location,
                      'Location',
                      selectedLocation == 'nearby'
                          ? 'Filters only (no location)'
                          : 'Within 2 km of me',
                    ),
                    if (selectedServiceNames.isNotEmpty)
                      _buildSummaryItem(
                        Icons.miscellaneous_services,
                        'Services',
                        '${selectedServiceNames.length} selected',
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'Modify',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Search Now',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (!shouldSearch) return;

    setState(() {
      _isSearching = true;
      _hasSearched = false;
    });

    try {
      // ── Step 1: get user GPS if "Current Location" selected ──────────
      double? userLat, userLng;
      if (selectedLocation == 'current') {
        // Ask for permission if needed
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.deniedForever ||
            perm == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Location permission denied. '
                  'Showing results without distance filter.',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          // Fall back to filters-only mode
        } else {
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          userLat = pos.latitude;
          userLng = pos.longitude;
        }
      }

      // ── Step 2: fetch all approved halls ────────────────────────────
      final all = await HallService.searchHalls(''); // all approved halls

      // ── Step 3: apply price + capacity filters ───────────────────────
      var filtered =
          all
              .where(
                (h) =>
                    h.capacityMax >= guestCount &&
                    h.pricePerEvent >= priceRange.start &&
                    h.pricePerEvent <= priceRange.end,
              )
              .toList();

      // ── Step 4: 2 km radius filter (only if Current Location + got GPS)
      if (userLat != null && userLng != null) {
        filtered =
            filtered.where((h) {
              if (h.latitude == 0.0 && h.longitude == 0.0) return false;
              final double distance = Geolocator.distanceBetween(
                userLat!,
                userLng!,
                h.latitude,
                h.longitude,
              );
              return distance <= 2000; // 2 km
            }).toList();
      }

      // ── Step 5: services filter ──────────────────────────────────────
      // For each selected service name, check that at least one of the
      // hall's ServiceItemModel entries has a matching name (case-insensitive).
      if (selectedServiceNames.isNotEmpty) {
        final List<HallModel> withServices = [];
        for (final hall in filtered) {
          final hallServices = await ServiceItemService.getServices(
            hall.hallId,
          );
          final hallServiceNames =
              hallServices.map((s) => s.name.toLowerCase()).toList();

          // ALL selected service chips must be matched in this hall
          final allMatch = selectedServiceNames.every(
            (selected) => hallServiceNames.any(
              (hs) => hs.contains(selected.toLowerCase()),
            ),
          );

          if (allMatch) withServices.add(hall);
        }
        filtered = withServices;
      }

      if (mounted) {
        setState(() {
          _results = filtered;
          _hasSearched = true;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _hasSearched = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Reset (identical to original) ─────────────────────────────────────
  void _resetFilters() {
    setState(() {
      guestCount = 50;
      priceRange = const RangeValues(5000, 50000);
      selectedLocation = 'nearby';
      _results = [];
      _hasSearched = false;
      for (final s in services) {
        s.isSelected = false;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.refresh, color: Colors.white),
            SizedBox(width: 12),
            Text('Filters reset successfully'),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Widget helpers (identical to original) ─────────────────────────────
  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildCounterButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.orange.shade700),
        iconSize: 24,
      ),
    );
  }

  Widget _buildPriceChip(
    String label,
    String value,
    Color bgColor,
    Color textColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textColor.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: textColor.withOpacity(0.7),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationOption(
    String title,
    IconData icon,
    String value,
    String subtitle,
  ) {
    final isSelected = selectedLocation == value;
    return GestureDetector(
      onTap: () => setState(() => selectedLocation = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey.shade300,
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.orange : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.orange.shade800 : Colors.black87,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem(ServiceItem service) {
    return GestureDetector(
      onTap: () => setState(() => service.isSelected = !service.isSelected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient:
              service.isSelected
                  ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.orange.shade400, Colors.orange.shade600],
                  )
                  : null,
          color: service.isSelected ? null : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                service.isSelected
                    ? Colors.orange.shade700
                    : Colors.grey.shade300,
            width: service.isSelected ? 2 : 1.5,
          ),
          boxShadow:
              service.isSelected
                  ? [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    service.isSelected
                        ? Colors.white.withOpacity(0.2)
                        : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:
                        service.isSelected
                            ? Colors.white.withOpacity(0.3)
                            : Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                service.icon,
                size: 20,
                color:
                    service.isSelected
                        ? Colors.orange.shade700
                        : Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              service.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: service.isSelected ? Colors.white : Colors.black87,
                letterSpacing: -0.2,
              ),
            ),
            if (service.isSelected) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  size: 14,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) =>
      price >= 1000
          ? '${(price / 1000).toStringAsFixed(0)}K'
          : price.toStringAsFixed(0);
}

// Service model (same as original)
class ServiceItem {
  final String id, name;
  final IconData icon;
  bool isSelected;
  ServiceItem({
    required this.id,
    required this.name,
    required this.icon,
    this.isSelected = false,
  });
}
