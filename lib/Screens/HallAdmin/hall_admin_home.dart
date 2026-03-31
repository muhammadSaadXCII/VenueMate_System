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

class HallAdminHomeScreen extends StatefulWidget {
  const HallAdminHomeScreen({super.key});

  @override
  State<HallAdminHomeScreen> createState() => _HallAdminHomeScreenState();
}

class _HallAdminHomeScreenState extends State<HallAdminHomeScreen> {
  UserModel? _user;
  HallModel? _hall;
  bool _loading = true;

  // Booking counts (fetched once on load)
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

    // Load user + hall in parallel
    final results = await Future.wait([
      AuthService.getCurrentUser(),
      HallService.getHallByOwnerId(uid),
    ]);

    final user = results[0] as UserModel?;
    final hall = results[1] as HallModel?;

    // Load booking stats if hall exists
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

    return Column(
      children: [
        // ── Header ─────────────────────────────────────────────────────────────
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
                // ✅ Show real owner name from Firestore
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
                          UserNotificationsScreen(),
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

        // ── Body ───────────────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hall status banner (show if not approved yet)
                if (_hall != null && !_hall!.isApproved) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          _hall!.isPending
                              ? Colors.amber.shade50
                              : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            _hall!.isPending
                                ? Colors.amber.shade300
                                : Colors.red.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _hall!.isPending
                              ? Icons.pending_actions
                              : Icons.cancel,
                          color:
                              _hall!.isPending
                                  ? Colors.amber.shade700
                                  : Colors.red.shade700,
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
                  ),
                  const SizedBox(height: 20),
                ],

                // Booking chart
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
                            Text(
                              'Booking Data',
                              style: const TextStyle(
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
                                      builder: (_) => HallAdminBookingsScreen(),
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

                // Quick Actions
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
                            () =>
                                AppNavigation.push(context, ManageHallScreen()),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _actionCard(
                            'Manage Menu',
                            Icons.restaurant_menu_outlined,
                            () =>
                                AppNavigation.push(context, ManageMenuScreen()),
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
                              ManageServicesScreen(),
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
                              ManagePackagesScreen(),
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
        height: 110,
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
            Icon(icon, size: 40, color: const Color(0xFF1D1D1D)),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Color(0xFF1D1D1D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
