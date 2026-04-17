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
import 'package:venuemate_system/Services/menu_service.dart';
import 'package:venuemate_system/Services/service_item_service.dart';
import 'package:venuemate_system/Services/user_service.dart';
import 'package:venuemate_system/Utils/app_navigation.dart';
import 'BasicDetailScreen.dart';
import 'MessagingScreen.dart';

class Packagesdetailscreen extends StatefulWidget {
  final HallModel hall;
  final PackageModel package;
  const Packagesdetailscreen({
    super.key,
    required this.hall,
    required this.package,
  });
  @override
  State<Packagesdetailscreen> createState() => _PackagesDetailState();
}

class _PackagesDetailState extends State<Packagesdetailscreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isFavorite = false;
  int _currentImageIndex = 0;
  final PageController _pageCtrl = PageController();
  final String _uid = AuthService.currentUid ?? '';

  // Owner info (loaded once)
  UserModel? _owner;

  // Filtered sub-lists
  List<MenuItemModel> _menuItems = [];
  List<ServiceItemModel> _services = [];
  bool _loadingItems = true;

  // Chat guard
  bool _openingChat = false;

  HallModel get h => widget.hall;
  PackageModel get p => widget.package;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadItems();
    _checkFav();
    _loadOwner();
  }

  Future<void> _loadOwner() async {
    final owner = await UserService.getUserById(h.ownerId);
    if (mounted) setState(() => _owner = owner);
  }

  Future<void> _loadItems() async {
    final results = await Future.wait([
      MenuService.getMenuItems(h.hallId),
      ServiceItemService.getServices(h.hallId),
    ]);
    if (!mounted) return;
    setState(() {
      _menuItems =
          (results[0] as List<MenuItemModel>)
              .where((m) => p.menuItemIds.contains(m.itemId))
              .toList();
      _services =
          (results[1] as List<ServiceItemModel>)
              .where((s) => p.serviceItemIds.contains(s.serviceId))
              .toList();
      _loadingItems = false;
    });
  }

  Future<void> _checkFav() async {
    if (_uid.isEmpty) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('favorites')
            .doc(_uid)
            .collection('halls')
            .doc(h.hallId)
            .get();
    if (mounted) setState(() => _isFavorite = doc.exists);
  }

  Future<void> _toggleFav() async {
    if (_uid.isEmpty) return;
    setState(() => _isFavorite = !_isFavorite);
    final ref = FirebaseFirestore.instance
        .collection('favorites')
        .doc(_uid)
        .collection('halls')
        .doc(h.hallId);
    _isFavorite
        ? await ref.set({
          'hallId': h.hallId,
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
    _tabController.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(),
          _buildTitleSection(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildMenuTab(),
                _buildServicesTab(),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: _buildFooter(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  HEADER — real hall images, swipeable
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildHeader() {
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
              '${_currentImageIndex + 1}/${imgs.isEmpty ? 1 : imgs.length}',
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
  //  TITLE SECTION — package name, hall address, rating, REAL owner card
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildTitleSection() => Container(
    color: Colors.white,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          p.name,
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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

        // ── Real owner card ────────────────────────────────────────────────
        _buildOwnerCard(),

        const Padding(
          padding: EdgeInsets.only(top: 10),
          child: Divider(color: Color(0xFFCCCCCC), thickness: 3, height: 0),
        ),
      ],
    ),
  );

  // ── Owner card: photo left, name + phone middle, message icon right ──────
  Widget _buildOwnerCard() {
    final owner = _owner;

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
      final url = owner?.profileImageUrl ?? '';
      if (url.isNotEmpty) {
        return CircleAvatar(radius: 24, backgroundImage: NetworkImage(url));
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

    return Row(
      children: [
        avatar(),
        const SizedBox(width: 12),
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
                h.contactPhone.isNotEmpty ? h.contactPhone : '—',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
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
      tabs: const [
        Tab(text: 'Details'),
        Tab(text: 'Menu'),
        Tab(text: 'Services'),
      ],
    ),
  );

  // ══════════════════════════════════════════════════════════════════════
  //  FOOTER
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildFooter() => Container(
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
                'Rs. ${p.price.toStringAsFixed(0)}',
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
                      builder: (_) => BasicDetailsScreen(hall: widget.hall),
                    ),
                  ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF47C20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Select Package',
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
  //  DETAILS TAB — description + READ-ONLY Google Map with hall pin
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildDetailsTab() {
    final hasCoords = h.latitude != 0.0 || h.longitude != 0.0;
    final hallLatLng = LatLng(h.latitude, h.longitude);

    return SingleChildScrollView(
      child: Container(
        color: const Color(0xFFF0F0F0),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              p.description.isNotEmpty
                  ? p.description
                  : 'No description provided.',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

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
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 200,
                child:
                    hasCoords
                        ? GestureDetector(
                          onTap: () async {
                            await _viewDirection(hallCords: hallLatLng);
                          },
                          child: AbsorbPointer(
                            absorbing:
                                true, // user cannot tap/pan/zoom — read-only
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
                                ),
                              },
                              zoomControlsEnabled: false,
                              zoomGesturesEnabled: false,
                              scrollGesturesEnabled: false,
                              rotateGesturesEnabled: false,
                              tiltGesturesEnabled: false,
                              myLocationButtonEnabled: false,
                              compassEnabled: false,
                              mapToolbarEnabled: false,
                              onMapCreated: (_) {},
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
        _loadingItems
            ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF47C20)),
            )
            : _menuItems.isEmpty
            ? _emptyTab('No menu items in this package.')
            : ListView(
              padding: const EdgeInsets.all(16),
              children: [..._menuItems.map(_menuCard)],
            ),
  );

  Widget _menuCard(MenuItemModel item) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.grey[400]!),
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
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.description.isNotEmpty
                    ? item.description
                    : 'Freshly prepared.',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        Text(
          item.isAvailable ? item.priceLabel : 'Sold Out',
          style: TextStyle(
            fontSize: 11,
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
              const Icon(Icons.fastfood, color: Colors.grey, size: 22),
    ),
  );

  // ══════════════════════════════════════════════════════════════════════
  //  SERVICES TAB
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildServicesTab() => Container(
    color: const Color(0xFFF0F0F0),
    child:
        _loadingItems
            ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF47C20)),
            )
            : _services.isEmpty
            ? _emptyTab('No services in this package.')
            : ListView(
              padding: const EdgeInsets.all(16),
              children: [..._services.map(_serviceCard)],
            ),
  );

  Widget _serviceCard(ServiceItemModel s) => Container(
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
        const Icon(Icons.room_service, color: Color(0xFFF47C20), size: 30),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                s.description.isNotEmpty ? s.description : '',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        Text(
          'Rs. ${s.price.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF47C20),
          ),
        ),
      ],
    ),
  );

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
