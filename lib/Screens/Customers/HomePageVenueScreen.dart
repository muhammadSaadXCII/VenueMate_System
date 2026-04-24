import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:venuemate_system/Models/hall_model.dart';
import 'package:venuemate_system/Models/package_model.dart';
import 'package:venuemate_system/Services/auth_service.dart';
import 'package:venuemate_system/Services/user_service.dart';
import 'package:venuemate_system/Services/hall_service.dart';
import 'package:venuemate_system/Services/package_service.dart';
import 'package:venuemate_system/Screens/Shared/user_notifications.dart';
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
//  FAVORITES SERVICE
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
  int _selectedCategory = 0;

  String _locationText = 'Fetching location...';
  bool _locationLoading = true;

  Set<String> _favIds = {};
  final String _uid = AuthService.currentUid ?? '';

  List<HallModel> _recentHalls = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLocation();
    });
    _loadRecentlyViewed();
  }

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
      if (!mounted) return;
      if (marks.isNotEmpty) {
        final m = marks.first;
        final parts =
            [
              m.subLocality,
              m.locality,
            ].where((s) => s != null && s.isNotEmpty).toList();
        final label =
            parts.isNotEmpty
                ? parts.take(2).join(', ')
                : '${pos.latitude.toStringAsFixed(2)}, ${pos.longitude.toStringAsFixed(2)}';
        setState(() {
          _locationText = label;
          _locationLoading = false;
        });
      } else {
        setState(() {
          _locationText = 'Location found';
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

  Future<void> _openHall(HallModel h) async {
    await _RecentlyViewed.add(h.hallId);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VenueDetailsScreen(hallId: h.hallId)),
    );
    _loadRecentlyViewed();
  }

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
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategoryToggle(),
                    const SizedBox(height: 16),
                    _selectedCategory == 0
                        ? _buildVenuesContent()
                        : _buildPackagesContent(),
                    const SizedBox(height: 24),
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
  //  HEADER — richer gradient, taller, cleaner search bar
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8650A), Color(0xFFF47C20), Color(0xFFFAA94E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33F47C20),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: location + notification
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'YOUR LOCATION',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      _locationLoading
                          ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : GestureDetector(
                            onTap: () {
                              _fetchLocation();
                            },
                            child: Text(
                              _locationText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                    ],
                  ),
                ],
              ),
              StreamBuilder<int>(
                stream:
                    _uid.isNotEmpty
                        ? UserService.streamUnreadNotificationCount(_uid)
                        : Stream.value(0),
                builder: (context, snap) {
                  final count = snap.data ?? 0;
                  return GestureDetector(
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserNotificationsScreen(),
                          ),
                        ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        if (count > 0)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                count > 9 ? '9+' : '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Search bar
          GestureDetector(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FilterSearchScreen()),
                ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: Color(0xFFF47C20),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Filter halls...',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  CATEGORY TOGGLE — pill style
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildCategoryToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _categoryPill('assets/images/venuses logo1 1.png', 'Venues', 0),
          _categoryPill('assets/images/pacakgeslogo1 1.png', 'Packages', 1),
        ],
      ),
    );
  }

  Widget _categoryPill(String img, String label, int index) {
    final isActive = _selectedCategory == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFF47C20) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                img,
                width: 22,
                height: 22,
                fit: BoxFit.contain,
                color: isActive ? Colors.white : Colors.grey[500],
                errorBuilder:
                    (_, __, ___) => Icon(
                      Icons.business,
                      size: 22,
                      color: isActive ? Colors.white : Colors.grey[500],
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.white : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
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
            if (_recentHalls.isNotEmpty) ...[
              _sectionHeader('Recently Viewed'),
              const SizedBox(height: 10),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recentHalls.length,
                  itemBuilder:
                      (_, i) =>
                          _buildRecentlyViewedCard(_recentHalls[i], false),
                ),
              ),
              const SizedBox(height: 20),
            ],
            _sectionHeader('Featured Venues'),
            const SizedBox(height: 10),
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
                if (_recentHalls.isNotEmpty) ...[
                  _sectionHeader('Recently Viewed'),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _recentHalls.length,
                      itemBuilder:
                          (_, i) =>
                              _buildRecentlyViewedCard(_recentHalls[i], true),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                _sectionHeader('Featured Packages'),
                const SizedBox(height: 10),
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
  //  SECTION HEADER
  // ══════════════════════════════════════════════════════════════════════
  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1A1A1A),
        letterSpacing: -0.3,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  RECENTLY VIEWED CARD — taller image, cleaner info
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildRecentlyViewedCard(HallModel h, bool isPackage) {
    final img = h.imageUrls.isNotEmpty ? h.imageUrls.first : '';
    final isFav = _isFav(h.hallId);
    return GestureDetector(
      onTap: () => _openHall(h),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
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
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: _netImg(img, 125, double.infinity),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _favBtn(h.hallId, isFav, small: true),
                ),
                // Rating badge
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 11,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          h.ratingCount == 0
                              ? 'New'
                              : h.ratingAvg.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    h.hallName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.people_alt_outlined,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${h.capacityMin}–${h.capacityMax}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
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
  //  FEATURED VENUE CARD — polished with cleaner info section
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildFeaturedVenueCard(HallModel h) {
    final img = h.imageUrls.isNotEmpty ? h.imageUrls.first : '';
    final isFav = _isFav(h.hallId);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
                child: InkWell(
                  onTap: () => _openHall(h),
                  child: _netImg(img, 210, double.infinity),
                ),
              ),
              Positioned(top: 12, right: 12, child: _favBtn(h.hallId, isFav)),
              // Rating badge top-left
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        h.ratingCount == 0
                            ? 'New'
                            : h.ratingAvg.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + review count
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        h.hallName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0E0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${h.ratingCount} reviews',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFF47C20),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Address row
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        h.address.isNotEmpty ? h.address : '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Capacity row
                Row(
                  children: [
                    const Icon(
                      Icons.people_alt_outlined,
                      size: 13,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${h.capacityMin}–${h.capacityMax} Guests',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Divider + price
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Starting from',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        Text(
                          h.priceLabel,
                          style: const TextStyle(
                            color: Color(0xFFF47C20),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _openHall(h),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF47C20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'View Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  FEATURED PACKAGE CARD — tighter, badge-style price
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildFeaturedPackageCard(_HallPackage hp) {
    final img = hp.hall.imageUrls.isNotEmpty ? hp.hall.imageUrls.first : '';
    final isFav = _isFav(hp.hall.hallId);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
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
                  child: _netImg(img, 210, double.infinity),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: _favBtn(hp.hall.hallId, isFav),
              ),
              // Package name overlay at bottom of image
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 24, 14, 12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black54],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(0),
                      bottomRight: Radius.circular(0),
                    ),
                  ),
                  child: Text(
                    hp.package.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hall name
                Row(
                  children: [
                    const Icon(
                      Icons.business_outlined,
                      size: 13,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        hp.hall.hallName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Includes strip
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5EC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _includeChip(
                        Icons.people_alt_outlined,
                        '${hp.package.capacityMax}',
                        'Guests',
                      ),
                      _vertDivider(),
                      _includeChip(
                        Icons.restaurant_menu_outlined,
                        '${hp.package.menuItemIds.length}',
                        'Menu',
                      ),
                      _vertDivider(),
                      _includeChip(
                        Icons.room_service_outlined,
                        '${hp.package.serviceItemIds.length}',
                        'Services',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Package price',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        Text(
                          'Rs. ${hp.package.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Color(0xFFF47C20),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF47C20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'View Package',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _includeChip(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFF47C20)),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _vertDivider() =>
      Container(width: 1, height: 36, color: const Color(0xFFE0D0C0));

  // ── Shared helpers ────────────────────────────────────────────────────────
  Widget _favBtn(String hallId, bool isFav, {bool small = false}) =>
      GestureDetector(
        onTap: () => _toggleFav(hallId),
        child: Container(
          padding: EdgeInsets.all(small ? 5 : 6),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6),
            ],
          ),
          child: Icon(
            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFav ? Colors.red : Colors.grey[400],
            size: small ? 16 : 18,
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

class _HallPackage {
  final HallModel hall;
  final PackageModel package;
  _HallPackage(this.hall, this.package);
}
