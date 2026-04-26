import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:venuemate_system/Models/hall_model.dart';
import 'package:venuemate_system/Models/menu_item_model.dart';
import 'package:venuemate_system/Models/package_model.dart';
import 'package:venuemate_system/Models/service_item_model.dart';
import 'package:venuemate_system/Models/user_model.dart';
import 'package:venuemate_system/Services/auth_service.dart';
import 'package:venuemate_system/Services/hall_service.dart';
import 'package:venuemate_system/Services/menu_service.dart';
import 'package:venuemate_system/Services/package_service.dart';
import 'package:venuemate_system/Services/service_item_service.dart';
import 'package:venuemate_system/Services/user_service.dart';
import 'package:venuemate_system/Utils/app_navigation.dart';
import 'BasicDetailScreen.dart';
import 'MessagingScreen.dart';
import 'PackagesDetailScreen.dart';

class VenueDetailsScreen extends StatefulWidget {
  final String hallId;
  const VenueDetailsScreen({super.key, required this.hallId});
  @override
  State<VenueDetailsScreen> createState() => _VenueDetailsScreenState();
}

class _VenueDetailsScreenState extends State<VenueDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Data
  HallModel? _hall;
  UserModel? _owner;
  List<MenuItemModel> _menu = [];
  List<ServiceItemModel> _services = [];
  List<PackageModel> _packages = [];
  List<Map<String, dynamic>> _reviews = [];
  StreamSubscription? _reviewsSub;
  bool _loading = true;

  // Favorites
  bool _isFavorite = false;
  final String _uid = AuthService.currentUid ?? '';

  // Image swipe
  int _currentImageIndex = 0;
  final PageController _pageCtrl = PageController();

  // Chat loading guard
  bool _openingChat = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    final hall = await HallService.getHallById(widget.hallId);
    if (!mounted) return;
    if (hall == null) {
      setState(() => _loading = false);
      return;
    }

    // Parallel: sub-collections + owner info + fav check
    final results = await Future.wait([
      MenuService.getMenuItems(widget.hallId),
      ServiceItemService.getServices(widget.hallId),
      PackageService.getPackages(widget.hallId),
      UserService.getUserById(hall.ownerId),
    ]);

    bool isFav = false;
    if (_uid.isNotEmpty) {
      final doc =
          await FirebaseFirestore.instance
              .collection('favorites')
              .doc(_uid)
              .collection('halls')
              .doc(widget.hallId)
              .get();
      isFav = doc.exists;
    }

    // Stream reviews live from booking_feedbacks filtered by hallId
    _reviewsSub = FirebaseFirestore.instance
        .collection('booking_feedbacks')
        .where('hallId', isEqualTo: widget.hallId)
        .snapshots()
        .listen((s) {
          if (mounted) {
            final reviews = s.docs.map((d) => d.data()).toList();
            // Sort client-side by submittedAt descending
            reviews.sort((a, b) {
              final aTs = a['submittedAt'] as Timestamp?;
              final bTs = b['submittedAt'] as Timestamp?;
              if (aTs == null && bTs == null) return 0;
              if (aTs == null) return 1;
              if (bTs == null) return -1;
              return bTs.compareTo(aTs);
            });
            setState(() => _reviews = reviews);
          }
        });

    if (!mounted) return;
    setState(() {
      _hall = hall;
      _owner = results[3] as UserModel?;
      _menu = results[0] as List<MenuItemModel>;
      _services = results[1] as List<ServiceItemModel>;
      _packages = results[2] as List<PackageModel>;
      _isFavorite = isFav;
      _loading = false;
    });
  }

  // ── Favorite toggle ────────────────────────────────────────────────────
  Future<void> _toggleFav() async {
    if (_uid.isEmpty || _hall == null) return;
    final ref = FirebaseFirestore.instance
        .collection('favorites')
        .doc(_uid)
        .collection('halls')
        .doc(widget.hallId);
    setState(() => _isFavorite = !_isFavorite);
    _isFavorite
        ? await ref.set({
          'hallId': widget.hallId,
          'savedAt': FieldValue.serverTimestamp(),
        })
        : await ref.delete();
  }

  Future _viewDirection({required LatLng hallCords}) async {
    try {
      Position userCords = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final String url =
          "https://www.google.com/maps/dir/?api=1&origin=${userCords.latitude},${userCords.longitude}&destination=${hallCords.latitude},${hallCords.longitude}&travelmode=driving";

      final Uri uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch maps';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error: Unable to open directions. Please check location permissions.",
            ),
          ),
        );
      }
    }
  }

  // ── Open chat with hall owner ──────────────────────────────────────────
  Future<void> _openChat() async {
    if (_uid.isEmpty || _owner == null || _openingChat) return;
    setState(() => _openingChat = true);

    try {
      // Get current user info for chat metadata
      final me = await UserService.getUserById(_uid);

      final chatId = await getOrCreateChat(
        currentUid: _uid,
        currentName: me?.name ?? 'Customer',
        currentPhoto: me?.profileImageUrl ?? '',
        otherId: _owner!.uid,
        otherName: _owner!.name,
        otherPhoto: _owner!.profileImageUrl,
      );

      if (!mounted) return;
      AppNavigation.push(
        context,
        ChattingScreen(
          chatId: chatId,
          currentUid: _uid,
          otherId: _owner!.uid,
          otherName: _owner!.name,
          otherPhoto: _owner!.profileImageUrl,
        ),
      );
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  @override
  void dispose() {
    _reviewsSub?.cancel();
    _tabController.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFF47C20)),
        ),
      );
    }
    if (_hall == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: const BackButton(color: Colors.black),
        ),
        body: const Center(child: Text('Venue not found.')),
      );
    }
    final h = _hall!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(h),
          _buildTitleSection(h),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(h),
                _buildMenuTab(),
                _buildServicesTab(),
                _buildPackagesTab(h),
                _buildReviewsTab(),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: _buildFooter(h),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  HEADER — swipeable images, back + heart
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildHeader(HallModel h) {
    final imgs = h.imageUrls;
    return Stack(
      children: [
        SizedBox(
          height: 240,
          width: double.infinity,
          child:
              imgs.isEmpty
                  ? Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.image,
                      size: 60,
                      color: Colors.grey,
                    ),
                  )
                  : PageView.builder(
                    controller: _pageCtrl,
                    itemCount: imgs.length,
                    onPageChanged:
                        (i) => setState(() => _currentImageIndex = i),
                    itemBuilder:
                        (_, i) => CachedNetworkImage(
                          imageUrl: imgs[i],
                          fit: BoxFit.cover,
                          placeholder:
                              (_, __) => Container(color: Colors.grey[200]),
                          errorWidget:
                              (_, __, ___) => Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                              ),
                        ),
                  ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    padding: EdgeInsets.zero,
                  ),
                ),
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    onPressed: _toggleFav,
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (imgs.isNotEmpty)
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentImageIndex + 1}/${imgs.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  TITLE SECTION — name, address, stars, REAL owner card
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildTitleSection(HallModel h) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            h.hallName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  h.address.isNotEmpty ? h.address : '—',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 14),
              const SizedBox(width: 4),
              Text(
                h.ratingCount == 0 ? '0.0' : h.ratingAvg.toStringAsFixed(1),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${h.ratingCount})',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Contact',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),

          // ── Real owner card ────────────────────────────────────────────
          _buildOwnerCard(),

          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Divider(color: Color(0xFFCCCCCC), thickness: 3, height: 0),
          ),
        ],
      ),
    );
  }

  // ── Owner card: photo left, name + phone middle, message icon right ──────
  Widget _buildOwnerCard() {
    final owner = _owner;

    // Initials fallback
    String initials() {
      final name = owner?.name ?? '';
      if (name.trim().isEmpty) return '?';
      return name
          .trim()
          .split(' ')
          .map((w) => w[0].toUpperCase())
          .take(2)
          .join();
    }

    Widget avatar() {
      final photoUrl = owner?.profileImageUrl ?? '';
      if (photoUrl.isNotEmpty) {
        return CircleAvatar(
          radius: 24,
          backgroundImage: NetworkImage(photoUrl),
        );
      }
      return CircleAvatar(
        radius: 24,
        backgroundColor: Colors.orange.shade50,
        child: Text(
          initials(),
          style: const TextStyle(
            color: Color(0xFFF47C20),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      child: Row(
        children: [
          // Owner photo
          avatar(),
          const SizedBox(width: 12),

          // Name + phone
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  owner?.name ?? '—',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  owner != null &&
                          _hall != null &&
                          _hall!.contactPhone.isNotEmpty
                      ? _hall!.contactPhone
                      : '—',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Message icon — navigates to ChattingScreen
          _openingChat
              ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFF47C20),
                ),
              )
              : IconButton(
                onPressed: _openChat,
                icon: const Icon(Icons.message_outlined, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: Colors.black87,
              ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  TAB BAR
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildTabBar() => Container(
    color: Colors.white,
    child: TabBar(
      controller: _tabController,
      isScrollable: true,
      labelColor: Colors.black,
      unselectedLabelColor: Colors.grey,
      indicatorColor: const Color(0xFFF47C20),
      indicatorWeight: 3,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      unselectedLabelStyle: const TextStyle(fontSize: 14),
      tabs: const [
        Tab(text: 'Details'),
        Tab(text: 'Menu'),
        Tab(text: 'Services'),
        Tab(text: 'Packages'),
        Tab(text: 'Reviews'),
      ],
    ),
  );

  // ══════════════════════════════════════════════════════════════════════
  //  FOOTER
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildFooter(HallModel h) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(18),
        topRight: Radius.circular(18),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 10,
          offset: const Offset(0, -3),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Starting from',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                h.priceLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF47C20),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BasicDetailsScreen(hall: h),
                    ),
                  ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF47C20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Book me',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  // ══════════════════════════════════════════════════════════════════════
  //  DETAILS TAB — real description + READ-ONLY Google Map with hall pin
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildDetailsTab(HallModel h) {
    final hasCoords = h.latitude != 0.0 || h.longitude != 0.0;
    final hallLatLng = LatLng(h.latitude, h.longitude);

    return SingleChildScrollView(
      child: Container(
        color: const Color(0xFFF0F0F0),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // About
            const Text(
              'About',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              h.description.isNotEmpty
                  ? h.description
                  : 'No description available.',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Location
            const Text(
              'Location',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Center(
              child: Text(
                "Click to view direction",
                style: TextStyle(fontSize: 8, color: Color(0xFFF47C20)),
              ),
            ),

            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 200,
                child:
                    hasCoords
                        ? GestureDetector(
                          onTap: () async {
                            await _viewDirection(hallCords: hallLatLng);
                          },
                          child: AbsorbPointer(
                            absorbing: true,
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: hallLatLng,
                                zoom: 15,
                              ),
                              markers: {
                                Marker(
                                  markerId: const MarkerId('hall'),
                                  position: hallLatLng,
                                  infoWindow: InfoWindow(title: h.hallName),
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueOrange,
                                  ),
                                ),
                              },
                              // Disable all interactive controls
                              zoomControlsEnabled: false,
                              zoomGesturesEnabled: false,
                              scrollGesturesEnabled: false,
                              rotateGesturesEnabled: false,
                              tiltGesturesEnabled: false,
                              myLocationButtonEnabled: false,
                              compassEnabled: false,
                              mapToolbarEnabled: false,
                              liteModeEnabled: false,
                              onMapCreated: (_) {}, // no controller needed
                            ),
                          ),
                        )
                        : Container(
                          color: Colors.grey[200],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.map,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                h.address.isNotEmpty
                                    ? h.address
                                    : 'No location set.',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
              ),
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  MENU TAB
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildMenuTab() => Container(
    color: const Color(0xFFF0F0F0),
    child:
        _menu.isEmpty
            ? _emptyTab('No menu items added yet.')
            : ListView(
              padding: const EdgeInsets.all(16),
              children: [..._menu.map(_menuCard)],
            ),
  );

  Widget _menuCard(MenuItemModel item) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child:
              item.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _menuFallback(),
                  )
                  : _menuFallback(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.description.isNotEmpty
                    ? item.description
                    : 'Freshly prepared.',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
        Text(
          item.isAvailable ? item.priceLabel : 'Sold Out',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: item.isAvailable ? const Color(0xFFF47C20) : Colors.grey,
          ),
        ),
      ],
    ),
  );

  Widget _menuFallback() => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(6),
    ),
    child: Image.asset(
      'assets/images/karahi.png',
      errorBuilder:
          (_, __, ___) =>
              const Icon(Icons.fastfood, color: Colors.grey, size: 30),
    ),
  );

  // ══════════════════════════════════════════════════════════════════════
  //  SERVICES TAB
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildServicesTab() => Container(
    color: const Color(0xFFF0F0F0),
    child:
        _services.isEmpty
            ? _emptyTab('No services listed.')
            : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._services.map(
                  (s) => _serviceCard(
                    s.name,
                    'Rs. ${s.price.toStringAsFixed(0)}',
                    s.description,
                  ),
                ),
              ],
            ),
  );

  Widget _serviceCard(String name, String price, String desc) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: const Icon(
            Icons.room_service,
            color: Color(0xFFF47C20),
            size: 30,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
        Text(
          "$price/Event",
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF47C20),
          ),
        ),
      ],
    ),
  );

  // ══════════════════════════════════════════════════════════════════════
  //  PACKAGES TAB
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildPackagesTab(HallModel h) => Container(
    color: const Color(0xFFF0F0F0),
    child:
        _packages.isEmpty
            ? _emptyTab('No packages available.')
            : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._packages
                    .where((p) => p.isActive)
                    .map((p) => _packageCard(p, h)),
              ],
            ),
  );

  Widget _packageCard(PackageModel p, HallModel h) => GestureDetector(
    onTap:
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Packagesdetailscreen(hall: h, package: p),
          ),
        ),
    child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 15,
            right: 8,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 16,
              child: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: Colors.red,
                size: 25,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  p.name,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                const Divider(color: Color(0xFFCCCCCC), thickness: 3),
                const Text(
                  'Includes:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _includeIcon(
                      'assets/images/guest.png',
                      '${p.capacityMax} Guests\nCapacity',
                    ),
                    _includeIcon(
                      'assets/images/menuitem.png',
                      '${p.menuItemIds.length} Menu Items',
                    ),
                    _includeIcon(
                      'assets/images/services.png',
                      '${p.serviceItemIds.length} Services',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Rs. ${p.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF47C20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _includeIcon(String img, String label) => Column(
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        child: Image.asset(
          img,
          width: 30,
          height: 30,
          color: const Color(0xFFF47C20),
          errorBuilder:
              (_, __, ___) => const Icon(
                Icons.fastfood,
                color: Color(0xFFF47C20),
                size: 20,
              ),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
      ),
    ],
  );

  // ══════════════════════════════════════════════════════════════════════
  //  REVIEWS TAB
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildReviewsTab() => Container(
    color: const Color(0xFFF0F0F0),
    child:
        _reviews.isEmpty
            ? _emptyTab('No reviews yet. Be the first!')
            : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              children: [..._reviews.map(_reviewCard)],
            ),
  );

  Widget _reviewCard(Map<String, dynamic> r) {
    final rating = (r['rating'] as num?)?.toDouble() ?? 0;
    final name = r['customerName'] as String? ?? 'Anonymous';
    final comment = r['reviewText'] as String? ?? ''; // ← correct field name
    final Timestamp? ts = r['submittedAt'] as Timestamp?;
    final dateLabel = ts != null ? _formatDate(ts.toDate()) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFF47C20),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Row(
                      children: [
                        // Star icons
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < rating.round()
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: Colors.amber,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (dateLabel.isNotEmpty)
                Text(
                  dateLabel,
                  style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comment,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    const months = [
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
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  Widget _emptyTab(String msg) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Text(
        msg,
        style: TextStyle(color: Colors.grey[500], fontSize: 14),
        textAlign: TextAlign.center,
      ),
    ),
  );
}
