import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:badges/badges.dart' as badges;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:venuemate_system/Utils/app_navigation.dart';
import 'package:venuemate_system/Services/auth_service.dart';
import 'package:venuemate_system/Services/hall_service.dart';
import 'package:venuemate_system/Services/user_service.dart';
import 'package:venuemate_system/Models/hall_model.dart';
import 'package:venuemate_system/Models/user_model.dart';
import 'package:venuemate_system/Screens/HallAdmin/manage_hall.dart';
import 'package:venuemate_system/Screens/HallAdmin/manage_menu.dart';
import 'package:venuemate_system/Screens/HallAdmin/manage_packages.dart';
import 'package:venuemate_system/Screens/Shared/user_notifications.dart';
import 'package:venuemate_system/Screens/HallAdmin/hall_admin_bookings.dart';
import 'package:venuemate_system/Screens/HallAdmin/manage_vendor_services.dart';

const double _kHallHomeWebBreak = 950;

class HallAdminHomeScreen extends StatefulWidget {
  const HallAdminHomeScreen({super.key});

  @override
  State<HallAdminHomeScreen> createState() => _HallAdminHomeScreenState();
}

class _HallAdminHomeScreenState extends State<HallAdminHomeScreen> {
  UserModel? _user;
  HallModel? _hall;
  bool _loading = true;

  int _upcoming = 0;
  int _pending = 0;
  int _completed = 0;
  int _cancelled = 0;
  int get _total => _upcoming + _pending + _completed + _cancelled;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = AuthService.currentUid;
    if (uid == null) return;

    final results = await Future.wait([
      AuthService.getCurrentUser(),
      HallService.getHallByOwnerId(uid),
    ]);

    final user = results[0] as UserModel?;
    final hall = results[1] as HallModel?;

    if (hall != null) {
      final snap =
          await FirebaseFirestore.instance
              .collection('bookings')
              .where('hallId', isEqualTo: hall.hallId)
              .get();

      int upcoming = 0, pending = 0, completed = 0, cancelled = 0;
      for (final doc in snap.docs) {
        final status = doc.data()['status'] as String? ?? '';
        if (status == 'confirmed') upcoming++;
        if (status == 'pending') pending++;
        if (status == 'completed') completed++;
        if (status == 'cancelled') cancelled++;
      }

      if (mounted) {
        setState(() {
          _upcoming = upcoming;
          _pending = pending;
          _completed = completed;
          _cancelled = cancelled;
        });
      }
    }

    if (mounted) {
      setState(() {
        _user = user;
        _hall = hall;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF47C20)),
      );
    }

    final isWide = MediaQuery.of(context).size.width >= _kHallHomeWebBreak;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: isWide ? _buildWebLayout() : _buildMobileLayout(),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  WEB LAYOUT
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout() {
    return Column(
      children: [
        // Top bar
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          color: Colors.white,
          child: Row(
            children: [
              Text(
                'Welcome back, ${_user?.name.split(' ').first ?? 'Owner'}! 👋',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              StreamBuilder<int>(
                stream:
                    _user != null
                        ? UserService.streamUnreadNotificationCount(_user!.uid)
                        : Stream.value(0),
                builder: (context, snap) {
                  final count = snap.data ?? 0;
                  return GestureDetector(
                    onTap:
                        () => AppNavigation.push(
                          context,
                          const UserNotificationsScreen(),
                        ),
                    child: badges.Badge(
                      showBadge: count > 0,
                      badgeContent: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                      badgeStyle: const badges.BadgeStyle(
                        badgeColor: Colors.red,
                        padding: EdgeInsets.all(4),
                        elevation: 0,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          size: 22,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // Body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hall status banner
                if (_hall != null && !_hall!.isApproved) ...[
                  _statusBanner(),
                  const SizedBox(height: 24),
                ],

                // Stats row — 4 cards
                Row(
                  children: [
                    _webStatCard(
                      'Upcoming',
                      _upcoming,
                      Colors.green.shade400,
                      Icons.event_available_outlined,
                    ),
                    const SizedBox(width: 16),
                    _webStatCard(
                      'Pending',
                      _pending,
                      const Color(0xFFFEDA77),
                      Icons.pending_outlined,
                    ),
                    const SizedBox(width: 16),
                    _webStatCard(
                      'Completed',
                      _completed,
                      Colors.orange,
                      Icons.check_circle_outline,
                    ),
                    const SizedBox(width: 16),
                    _webStatCard(
                      'Cancelled',
                      _cancelled,
                      Colors.redAccent,
                      Icons.cancel_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Two column: chart + quick actions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Booking chart card
                    Expanded(
                      flex: 5,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: _cardDec(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bookings Overview',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 160,
                                  width: 160,
                                  child:
                                      _total == 0
                                          ? Center(
                                            child: Text(
                                              'No bookings yet',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 13,
                                              ),
                                            ),
                                          )
                                          : PieChart(
                                            PieChartData(
                                              sectionsSpace: 0,
                                              centerSpaceRadius: 50,
                                              sections: [
                                                _section(
                                                  Colors.greenAccent.shade400,
                                                  _upcoming.toDouble(),
                                                ),
                                                _section(
                                                  const Color(0xFFFEDA77),
                                                  _pending.toDouble(),
                                                ),
                                                _section(
                                                  Colors.orange,
                                                  _completed.toDouble(),
                                                ),
                                                _section(
                                                  Colors.redAccent,
                                                  _cancelled.toDouble(),
                                                ),
                                              ],
                                            ),
                                          ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$_total Total',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _legend(
                                      Colors.greenAccent.shade400,
                                      'Upcoming: $_upcoming',
                                    ),
                                    _legend(
                                      const Color(0xFFFEDA77),
                                      'Pending: $_pending',
                                    ),
                                    _legend(
                                      Colors.orange,
                                      'Completed: $_completed',
                                    ),
                                    _legend(
                                      Colors.redAccent,
                                      'Cancelled: $_cancelled',
                                    ),
                                    const SizedBox(height: 12),
                                    GestureDetector(
                                      onTap:
                                          () => AppNavigation.push(
                                            context,
                                            const HallAdminBookingsScreen(),
                                          ),
                                      child: const Text(
                                        'View Bookings →',
                                        style: TextStyle(
                                          color: Color(0xFFF47C20),
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
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
                    const SizedBox(width: 20),

                    // Quick actions
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: _cardDec(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quick Actions',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio:
                                  1.2, // Changed to 1.5 to fix overflow
                              children: [
                                _actionCard(
                                  'Manage Hall',
                                  Icons.storefront_outlined,
                                  () => AppNavigation.push(
                                    context,
                                    const ManageHallScreen(),
                                  ),
                                ),
                                _actionCard(
                                  'Manage Menu',
                                  Icons.restaurant_menu_outlined,
                                  () => AppNavigation.push(
                                    context,
                                    const ManageMenuScreen(),
                                  ),
                                ),
                                _actionCard(
                                  'Manage Services',
                                  Icons.room_service_outlined,
                                  () => AppNavigation.push(
                                    context,
                                    const ManageServicesScreen(),
                                  ),
                                ),
                                _actionCard(
                                  'Manage Packages',
                                  Icons.card_giftcard_outlined,
                                  () => AppNavigation.push(
                                    context,
                                    const ManagePackagesScreen(),
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _webStatCard(String label, int value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDec(),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  MOBILE LAYOUT
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 60,
            bottom: 30,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF47C20), Color(0xFFFFD166)],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Welcome, ${_user?.name.split(' ').first ?? 'Owner'}!',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              StreamBuilder<int>(
                stream:
                    _user != null
                        ? UserService.streamUnreadNotificationCount(_user!.uid)
                        : Stream.value(0),
                builder: (context, snap) {
                  final count = snap.data ?? 0;
                  return GestureDetector(
                    onTap:
                        () => AppNavigation.push(
                          context,
                          const UserNotificationsScreen(),
                        ),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: badges.Badge(
                        showBadge: count > 0,
                        badgeContent: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                        badgeStyle: const badges.BadgeStyle(
                          badgeColor: Colors.red,
                          padding: EdgeInsets.all(4),
                          elevation: 0,
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          size: 25,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_hall != null && !_hall!.isApproved) ...[
                  _statusBanner(),
                  const SizedBox(height: 20),
                ],

                const Text(
                  'Bookings Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 130,
                        width: 130,
                        child:
                            _total == 0
                                ? Center(
                                  child: Text(
                                    'No bookings yet',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                                : PieChart(
                                  PieChartData(
                                    sectionsSpace: 0,
                                    centerSpaceRadius: 40,
                                    sections: [
                                      _section(
                                        Colors.greenAccent.shade400,
                                        _upcoming.toDouble(),
                                      ),
                                      _section(
                                        const Color(0xFFFEDA77),
                                        _pending.toDouble(),
                                      ),
                                      _section(
                                        Colors.orange,
                                        _completed.toDouble(),
                                      ),
                                      _section(
                                        Colors.redAccent,
                                        _cancelled.toDouble(),
                                      ),
                                    ],
                                  ),
                                ),
                      ),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Booking Data',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '$_total Total Bookings',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _legend(
                              Colors.greenAccent.shade400,
                              'Upcoming: $_upcoming',
                            ),
                            _legend(
                              const Color(0xFFFEDA77),
                              'Pending: $_pending',
                            ),
                            _legend(Colors.orange, 'Completed: $_completed'),
                            _legend(Colors.redAccent, 'Cancelled: $_cancelled'),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) =>
                                              const HallAdminBookingsScreen(),
                                    ),
                                  ),
                              child: const Text(
                                'View Bookings >',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _actionCard(
                            'Manage Hall',
                            Icons.storefront_outlined,
                            () => AppNavigation.push(
                              context,
                              const ManageHallScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _actionCard(
                            'Manage Menu',
                            Icons.restaurant_menu_outlined,
                            () => AppNavigation.push(
                              context,
                              const ManageMenuScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _actionCard(
                            'Manage Services',
                            Icons.room_service_outlined,
                            () => AppNavigation.push(
                              context,
                              const ManageServicesScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _actionCard(
                            'Manage Packages',
                            Icons.card_giftcard_outlined,
                            () => AppNavigation.push(
                              context,
                              const ManagePackagesScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Shared helpers ──────────────────────────────────────────────────────────
  Widget _statusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _hall!.isPending ? Colors.amber.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hall!.isPending ? Colors.amber.shade300 : Colors.red.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _hall!.isPending ? Icons.pending_actions : Icons.cancel,
            color:
                _hall!.isPending ? Colors.amber.shade700 : Colors.red.shade700,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _hall!.isPending
                  ? 'Your hall is pending admin approval.'
                  : 'Your hall was rejected: ${_hall!.rejectionReason}',
              style: TextStyle(
                color:
                    _hall!.isPending
                        ? Colors.amber.shade800
                        : Colors.red.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  PieChartSectionData _section(Color color, double value) =>
      PieChartSectionData(
        color: color,
        value: value == 0 ? 0.001 : value,
        radius: 30,
        showTitle: false,
      );

  Widget _legend(Color color, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    ),
  );

  Widget _actionCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // height: 110, // REMOVED fixed height to allow flexibility
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF47C20), Color(0xFFFFD166)],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF47C20).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: const Color(0xFF1D1D1D),
            ), // Slightly smaller icon
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600, // Semi-bold looks better for web
                  color: Color(0xFF1D1D1D),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDec() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
