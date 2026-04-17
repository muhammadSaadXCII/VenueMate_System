import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:venuemate_system/Models/hall_model.dart';
import 'package:venuemate_system/Models/package_model.dart';
import 'package:venuemate_system/Services/auth_service.dart';
import 'package:venuemate_system/Services/hall_service.dart';
import 'package:venuemate_system/Services/package_service.dart';
import 'NotificationScreen.dart';
import 'SearchingScreen.dart';
import 'VenueDetailScreen.dart';
import 'PackagesDetailScreen.dart';

// ══════════════════════════════════════════════════════════════════════════
//  RECENTLY VIEWED — persisted in SharedPreferences (up to 6 hallIds)
// ══════════════════════════════════════════════════════════════════════════
class _RecentlyViewed {
  static const _key = 'rv_halls';
  static const _max = 6;

  static Future<void> add(String hallId) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key) ?? '';
    var ids =
        raw.isEmpty
            ? <String>[]
            : raw.split(',').where((s) => s.isNotEmpty).toList();
    ids.remove(hallId);
    ids.insert(0, hallId);
    if (ids.length > _max) ids = ids.sublist(0, _max);
    await p.setString(_key, ids.join(','));
  }

  static Future<List<String>> get() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key) ?? '';
    return raw.isEmpty
        ? []
        : raw.split(',').where((s) => s.isNotEmpty).toList();
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  FAVORITES SERVICE — Firestore: favorites/{uid}/halls/{hallId}
// ══════════════════════════════════════════════════════════════════════════
class _FavService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> add(String uid, String hallId) => _db
      .collection('favorites')
      .doc(uid)
      .collection('halls')
      .doc(hallId)
      .set({'hallId': hallId, 'savedAt': FieldValue.serverTimestamp()});

  static Future<void> remove(String uid, String hallId) =>
      _db
          .collection('favorites')
          .doc(uid)
          .collection('halls')
          .doc(hallId)
          .delete();

  static Stream<Set<String>> streamIds(String uid) => _db
      .collection('favorites')
      .doc(uid)
      .collection('halls')
      .snapshots()
      .map((s) => s.docs.map((d) => d.id).toSet());
}

// ══════════════════════════════════════════════════════════════════════════
//  HOME SCREEN
// ══════════════════════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedCategory = 0; // 0=Venues 1=Packages

  // ── Location ──────────────────────────────────────────────────────────
  String _locationText = 'Fetching location...';
  bool _locationLoading = true;

  // ── Favorites ─────────────────────────────────────────────────────────
  Set<String> _favIds = {};
  final String _uid = AuthService.currentUid ?? '';

  // ── Recently Viewed halls (loaded on init + refresh after nav back) ────
  List<HallModel> _recentHalls = [];

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _loadRecentlyViewed();
  }

  // ── GPS location ───────────────────────────────────────────────────────
  Future<void> _fetchLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationText = 'Location unavailable';
            _locationLoading = false;
          });
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (marks.isNotEmpty && mounted) {
        final m = marks.first;
        final parts =
            [
              m.subLocality,
              m.locality,
            ].where((s) => s != null && s.isNotEmpty).toList();
        setState(() {
          _locationText = parts.take(2).join(', ');
          _locationLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationText = 'No Location';
          _locationLoading = false;
        });
      }
    }
  }

  // ── Recently viewed ────────────────────────────────────────────────────
  Future<void> _loadRecentlyViewed() async {
    final ids = await _RecentlyViewed.get();
    if (ids.isEmpty || !mounted) return;
    final halls = await Future.wait(
      ids.map((id) => HallService.getHallById(id)),
    );
    if (mounted) {
      setState(() => _recentHalls = halls.whereType<HallModel>().toList());
    }
  }

  // ── Navigate to hall + record recently viewed ──────────────────────────
  Future<void> _openHall(HallModel h) async {
    await _RecentlyViewed.add(h.hallId);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VenueDetailsScreen(hallId: h.hallId)),
    );
    _loadRecentlyViewed(); // refresh strip on return
  }

  // ── Toggle favorite ────────────────────────────────────────────────────
  void _toggleFav(String hallId) {
    if (_uid.isEmpty) return;
    final isFav = _favIds.contains(hallId);
    setState(() {
      isFav ? _favIds.remove(hallId) : _favIds.add(hallId);
    });
    isFav ? _FavService.remove(_uid, hallId) : _FavService.add(_uid, hallId);
  }

  bool _isFav(String id) => _favIds.contains(id);

  @override
  Widget build(BuildContext context) {
    // Stream favorites ids live
    return StreamBuilder<Set<String>>(
      stream:
          _uid.isNotEmpty ? _FavService.streamIds(_uid) : const Stream.empty(),
      builder: (context, favSnap) {
        if (favSnap.hasData) _favIds = favSnap.data!;
        return _buildScaffold();
      },
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Category toggle ────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildCategoryItem(
                          'assets/images/venuses logo1 1.png',
                          'Venues',
                          0,
                        ),
                        _buildCategoryItem(
                          'assets/images/pacakgeslogo1 1.png',
                          'Packages',
                          1,
                        ),
                      ],
                    ),
                    Divider(color: Colors.grey[600]),
                    const SizedBox(height: 4),
                    _selectedCategory == 0
                        ? _buildVenuesContent()
                        : _buildPackagesContent(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  HEADER
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF47C20), Color.fromARGB(255, 233, 184, 69)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Location',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 4),
                      _locationLoading
                          ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                          : Text(
                            _locationText,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                            ),
                          ),
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => NotificationScreen()),
                    ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FilterSearchScreen()),
                ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const AbsorbPointer(
                child: TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    icon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    hintText: 'Search...',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  CATEGORY ITEM
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildCategoryItem(String img, String label, int index) {
    final isActive = _selectedCategory == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = index),
      child: Column(
        children: [
          Image.asset(
            img,
            width: 40,
            height: 40,
            fit: BoxFit.contain,
            errorBuilder:
                (_, __, ___) => Icon(
                  Icons.business,
                  size: 40,
                  color: isActive ? Colors.black : Colors.grey,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? Colors.black : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 3,
            width: isActive ? 50 : 0,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  VENUES CONTENT
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildVenuesContent() {
    return StreamBuilder<List<HallModel>>(
      stream: HallService.streamApprovedHalls(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: Color(0xFFF47C20)),
            ),
          );
        }
        final halls = snap.data ?? [];
        if (halls.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Text(
                'No venues available yet.',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recently Viewed — only if user has visited halls before
            if (_recentHalls.isNotEmpty) ...[
              const Text(
                'Recently Viewed',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 185,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recentHalls.length,
                  itemBuilder:
                      (_, i) =>
                          _buildRecentlyViewedCard(_recentHalls[i], false),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Featured Venues
            const Text(
              'Featured Venues',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...halls.map((h) => _buildFeaturedVenueCard(h)),
          ],
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  PACKAGES CONTENT
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildPackagesContent() {
    return StreamBuilder<List<HallModel>>(
      stream: HallService.streamApprovedHalls(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: Color(0xFFF47C20)),
            ),
          );
        }
        final halls = snap.data ?? [];
        return FutureBuilder<List<_HallPackage>>(
          future: _loadAllPackages(halls),
          builder: (context, pSnap) {
            final packages = pSnap.data ?? [];
            if (packages.isEmpty &&
                pSnap.connectionState != ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    'No packages available yet.',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              );
            }
            if (pSnap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: Color(0xFFF47C20)),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recently Viewed strip (package tab also shows recently viewed halls)
                if (_recentHalls.isNotEmpty) ...[
                  const Text(
                    'Recently Viewed',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 185,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _recentHalls.length,
                      itemBuilder:
                          (_, i) =>
                              _buildRecentlyViewedCard(_recentHalls[i], true),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                const Text(
                  'Featured Packages',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...packages.map((p) => _buildFeaturedPackageCard(p)),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<_HallPackage>> _loadAllPackages(List<HallModel> halls) async {
    final result = <_HallPackage>[];
    for (final h in halls) {
      final pkgs = await PackageService.getPackages(h.hallId);
      for (final p in pkgs) {
        if (p.isActive) result.add(_HallPackage(h, p));
      }
    }
    return result;
  }

  // ══════════════════════════════════════════════════════════════════════
  //  RECENTLY VIEWED CARD  (same design as original small card)
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildRecentlyViewedCard(HallModel h, bool isPackage) {
    final img = h.imageUrls.isNotEmpty ? h.imageUrls.first : '';
    final isFav = _isFav(h.hallId);
    return GestureDetector(
      onTap: () => _openHall(h),
      child: Container(
        width: 165,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.12),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: _netImg(img, 120, double.infinity),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _favBtn(h.hallId, isFav, small: true),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    h.hallName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${h.capacityMin}–${h.capacityMax}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.star, size: 13, color: Colors.amber),
                      const SizedBox(width: 3),
                      Text(
                        h.ratingCount == 0
                            ? '—'
                            : h.ratingAvg.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
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

  // ══════════════════════════════════════════════════════════════════════
  //  FEATURED VENUE CARD  (same design as original big card)
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildFeaturedVenueCard(HallModel h) {
    final img = h.imageUrls.isNotEmpty ? h.imageUrls.first : '';
    final isFav = _isFav(h.hallId);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: InkWell(
                  onTap: () => _openHall(h),
                  child: _netImg(img, 200, double.infinity),
                ),
              ),
              // Heart — top right
              Positioned(top: 12, right: 12, child: _favBtn(h.hallId, isFav)),
              // Rating badge — top left
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 3),
                      Text(
                        h.ratingCount == 0
                            ? 'New'
                            : h.ratingAvg.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h.hallName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${h.address} • ${h.ratingCount} Reviews',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '${h.capacityMin}–${h.capacityMax} Capacity',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  h.priceLabel,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  FEATURED PACKAGE CARD  (same design as original)
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildFeaturedPackageCard(_HallPackage hp) {
    final img = hp.hall.imageUrls.isNotEmpty ? hp.hall.imageUrls.first : '';
    final isFav = _isFav(hp.hall.hallId);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: InkWell(
                  onTap: () async {
                    await _RecentlyViewed.add(hp.hall.hallId);
                    if (!mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => Packagesdetailscreen(
                              hall: hp.hall,
                              package: hp.package,
                            ),
                      ),
                    );
                    _loadRecentlyViewed();
                  },
                  child: _netImg(img, 200, double.infinity),
                ),
              ),
              // Heart — top left (original design)
              Positioned(
                top: 8,
                left: 8,
                child: _favBtn(hp.hall.hallId, isFav),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Package name
                Text(
                  hp.package.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                // Hall name with logo
                Row(
                  children: [
                    Image.asset(
                      'assets/images/hallpic.png',
                      width: 25,
                      height: 25,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (_, __, ___) => const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey,
                          ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hp.hall.hallName,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(
                  color: Color(0xFFCCCCCC),
                  thickness: 5,
                  indent: 16,
                  endIndent: 16,
                ),
                // Includes
                const Text(
                  'Includes:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildIncludeItemWithImage(
                      'assets/images/guest.png',
                      '${hp.package.capacityMax} Guests\nCapacity',
                    ),
                    _buildIncludeItemWithImage(
                      'assets/images/menuitem.png',
                      '${hp.package.menuItemIds.length} Menu Items',
                    ),
                    _buildIncludeItemWithImage(
                      'assets/images/services.png',
                      '${hp.package.serviceItemIds.length} Services',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Rs. ${hp.package.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFFF47C20),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Include item widget (original design) ────────────────────────────────
  Widget _buildIncludeItemWithImage(String imagePath, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          child: Image.asset(
            imagePath,
            width: 35,
            height: 35,
            fit: BoxFit.contain,
            color: const Color(0xFFF47C20),
            errorBuilder: (_, __, ___) {
              IconData icon = Icons.fastfood;
              if (label.contains('Guest')) icon = Icons.people;
              if (label.contains('Menu')) icon = Icons.restaurant_menu;
              if (label.contains('Serv')) icon = Icons.business_center;
              return Icon(icon, color: const Color(0xFFF47C20), size: 24);
            },
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────
  Widget _favBtn(String hallId, bool isFav, {bool small = false}) =>
      GestureDetector(
        onTap: () => _toggleFav(hallId),
        child: Container(
          padding: EdgeInsets.all(small ? 4 : 5),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            color: Colors.red,
            size: small ? 18 : 20,
          ),
        ),
      );

  Widget _netImg(String url, double height, double width) {
    if (url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        height: height,
        width: width,
        fit: BoxFit.cover,
        placeholder:
            (_, __) => Container(height: height, color: Colors.grey[200]),
        errorWidget: (_, __, ___) => _placeholder(height),
      );
    }
    return _placeholder(height);
  }

  Widget _placeholder(double h) => Container(
    height: h,
    color: Colors.grey[200],
    child: const Center(
      child: Icon(Icons.business, color: Colors.grey, size: 40),
    ),
  );
}

// Helper data class
class _HallPackage {
  final HallModel hall;
  final PackageModel package;
  _HallPackage(this.hall, this.package);
}
