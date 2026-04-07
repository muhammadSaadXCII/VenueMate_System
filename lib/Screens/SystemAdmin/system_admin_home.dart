import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:venuemate_system/Utils/app_navigation.dart';
import 'package:venuemate_system/Services/auth_service.dart';
import 'package:venuemate_system/Services/user_service.dart';
import 'package:venuemate_system/Screens/Customers/LoginScreen.dart';
import 'package:venuemate_system/Screens/Shared/user_notifications.dart';
import 'package:venuemate_system/Screens/SystemAdmin/manage_all_halls.dart';
import 'package:venuemate_system/Screens/SystemAdmin/manage_all_users.dart';
import 'package:venuemate_system/Screens/SystemAdmin/handle_complaints.dart';
import 'package:venuemate_system/Screens/SystemAdmin/pending_registrations.dart';

const double _kWebBreak = 940;

class SystemAdminHome extends StatefulWidget {
  const SystemAdminHome({super.key});
  @override
  State<SystemAdminHome> createState() => _SystemAdminHomeState();
}

class _SystemAdminHomeState extends State<SystemAdminHome> {
  final _db = FirebaseFirestore.instance;
  int _sidebarIndex = 0; // Tracks which screen to show on the right side

  // ── Stream helpers ──────────────────────────────────────────────────────────
  Stream<int> get _pendingStream => _db
      .collection('halls')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((s) => s.docs.length);

  Stream<int> get _complaintsStream => _db
      .collection('complaints')
      .where('status', isEqualTo: 'Pending')
      .snapshots()
      .map((s) => s.docs.length);

  Future<Map<String, int>> _fetchStats() async {
    final results = await Future.wait([
      _db.collection('halls').where('status', isEqualTo: 'approved').get(),
      _db.collection('users').get(),
      _db.collection('bookings').get(),
      _db.collection('bookings').where('status', isEqualTo: 'cancelled').get(),
    ]);
    return {
      'halls': results[0].docs.length,
      'users': results[1].docs.length,
      'bookings': results[2].docs.length,
      'cancelled': results[3].docs.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= _kWebBreak;
    return isWide ? _buildWebLayout() : _buildMobileLayout();
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  MOBILE layout — remains unchanged
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMobileHeader(context),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _pendingCard(),
                  const SizedBox(height: 16),
                  _complaintsCard(),
                  const SizedBox(height: 32),
                  const Text(
                    'Statistics',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  _statsGrid(crossAxisCount: 2),
                  const SizedBox(height: 32),
                  const Text(
                    'Quick Links',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _manageTile(
                    'Manage All Halls',
                    'assets/images/hallpic.png',
                    () => AppNavigation.push(
                      context,
                      const ManageAllHallsScreen(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _manageTile(
                    'Manage All Users',
                    'assets/images/users.png',
                    () => AppNavigation.push(
                      context,
                      const ManageAllUsersScreen(),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  WEB layout — Modified to switch content area based on _sidebarIndex
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout() {
    // List of screens corresponding to sidebar indices
    final List<Widget> screens = [
      _buildDashboardContent(), // Index 0
      const PendingRegistrationsScreen(), // Index 1
      const ManageAllHallsScreen(), // Index 2
      const ManageAllUsersScreen(), // Index 3
      const ComplaintsScreen(), // Index 4
    ];

    final List<String> titles = [
      'Dashboard',
      'Pending Registrations',
      'Manage All Halls',
      'Manage All Users',
      'User Complaints',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          _Sidebar(
            selectedIndex: _sidebarIndex,
            onSelect: (i) {
              if (i == 5) {
                _handleLogout(context);
              } else {
                setState(() => _sidebarIndex = i);
              }
            },
          ),
          Expanded(
            child: Column(
              children: [
                _buildWebTopBar(titles[_sidebarIndex]),
                Expanded(
                  child: IndexedStack(index: _sidebarIndex, children: screens),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Extracted dashboard view to clean up the web layout logic
  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _pendingCard()),
              const SizedBox(width: 20),
              Expanded(child: _complaintsCard()),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Statistics',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _statsGrid(crossAxisCount: 4),
          const SizedBox(height: 32),
          const Text(
            'Quick Links',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _manageTile(
                  'Manage All Halls',
                  'assets/images/hallpic.png',
                  () => setState(
                    () => _sidebarIndex = 2,
                  ), // Update sidebar instead of pushing
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _manageTile(
                  'Manage All Users',
                  'assets/images/users.png',
                  () => setState(
                    () => _sidebarIndex = 3,
                  ), // Update sidebar instead of pushing
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Updated TopBar to accept a dynamic title
  Widget _buildWebTopBar(String title) {
    final uid = AuthService.currentUid;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          StreamBuilder<int>(
            stream:
                uid != null
                    ? UserService.streamUnreadNotificationCount(uid)
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
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  badgeStyle: const badges.BadgeStyle(
                    badgeColor: Colors.red,
                    elevation: 0,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Icon(
                      Icons.notifications_none,
                      color: Colors.black87,
                      size: 22,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Mobile header ──────────────────────────────────────────────────────────
  Widget _buildMobileHeader(BuildContext context) {
    final uid = AuthService.currentUid;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF47C20), Color(0xFFFFD166)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Welcome, Admin!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => _handleLogout(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout, color: Colors.red, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              StreamBuilder<int>(
                stream:
                    uid != null
                        ? UserService.streamUnreadNotificationCount(uid)
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
                          elevation: 0,
                        ),
                        child: const Icon(
                          Icons.notifications_none,
                          color: Colors.black87,
                          size: 24,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Shared widgets below remain identical in functionality but updated `onTap` for Web Dashboard compatibility
  Widget _pendingCard() => StreamBuilder<int>(
    stream: _pendingStream,
    builder: (context, snap) {
      final count = snap.data ?? 0;
      return ActionCard(
        title:
            count == 0
                ? 'No Pending Registrations'
                : '$count Pending Registration${count == 1 ? '' : 's'}',
        subtitle: 'Review hall submissions',
        imagePath: 'assets/images/pendingLogo.png',
        iconColor: Colors.amber,
        borderColor: Colors.amber,
        badgeCount: count,
        onTap: () {
          if (MediaQuery.of(context).size.width >= _kWebBreak) {
            setState(() => _sidebarIndex = 1);
          } else {
            AppNavigation.push(context, const PendingRegistrationsScreen());
          }
        },
      );
    },
  );

  Widget _complaintsCard() => StreamBuilder<int>(
    stream: _complaintsStream,
    builder: (context, snap) {
      final count = snap.data ?? 0;
      return ActionCard(
        title:
            count == 0
                ? 'No New Complaints'
                : '$count New Complaint${count == 1 ? '' : 's'}',
        subtitle: 'Resolve customer issues',
        imagePath: 'assets/images/complaintsLogo.png',
        iconColor: Colors.redAccent,
        borderColor: Colors.redAccent,
        badgeCount: count,
        onTap: () {
          if (MediaQuery.of(context).size.width >= _kWebBreak) {
            setState(() => _sidebarIndex = 4);
          } else {
            AppNavigation.push(context, const ComplaintsScreen());
          }
        },
      );
    },
  );

  Widget _statsGrid({required int crossAxisCount}) =>
      FutureBuilder<Map<String, int>>(
        future: _fetchStats(),
        builder: (context, snap) {
          final stats = snap.data;
          return GridView.count(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: crossAxisCount == 4 ? 1.2 : 1.1,
            children: [
              StatCard(
                count: stats == null ? '—' : '${stats['halls']}',
                label: 'Total Halls',
                imagePath: 'assets/images/hallpic.png',
                color: Colors.blue,
              ),
              StatCard(
                count: stats == null ? '—' : '${stats['users']}',
                label: 'Total Users',
                imagePath: 'assets/images/users.png',
                color: Colors.purple,
              ),
              StatCard(
                count: stats == null ? '—' : '${stats['bookings']}',
                label: 'Bookings',
                imagePath: 'assets/images/bookcalendar.png',
                color: Colors.orange,
              ),
              StatCard(
                count: stats == null ? '—' : '${stats['cancelled']}',
                label: 'Cancelled',
                imagePath: 'assets/images/cancelfile.png',
                color: Colors.red,
              ),
            ],
          );
        },
      );

  Widget _manageTile(
    String title,
    String imagePath,
    VoidCallback onTap,
  ) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Image.asset(
            imagePath,
            width: 30,
            height: 30,
            color: Colors.grey[700],
            errorBuilder:
                (_, __, ___) => Icon(Icons.business, color: Colors.grey[700]),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        ],
      ),
    ),
  );
}

// Sidebar classes (unchanged styles, just integrated via callback above)
class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _Sidebar({required this.selectedIndex, required this.onSelect});

  static const _items = [
    {'icon': Icons.dashboard_outlined, 'label': 'Dashboard'},
    {'icon': Icons.pending_actions_outlined, 'label': 'Pending Registrations'},
    {'icon': Icons.business_outlined, 'label': 'Manage Halls'},
    {'icon': Icons.people_outline, 'label': 'Manage Users'},
    {'icon': Icons.report_problem_outlined, 'label': 'Complaints'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      // We use a Column as the main container
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Logo area (Fixed at the top)
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF47C20), Color(0xFFFFD166)],
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
                SizedBox(width: 10),
                Text(
                  'VenueMate',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 2. Scrollable Navigation Items
          // Wrapping this part in Expanded + SingleChildScrollView
          // allows the menu to scroll if the screen height is small
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      'NAVIGATION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  ...List.generate(_items.length, (i) {
                    final item = _items[i];
                    return _SidebarItem(
                      icon: item['icon'] as IconData,
                      label: item['label'] as String,
                      isActive: selectedIndex == i,
                      onTap: () => onSelect(i),
                    );
                  }),
                ],
              ),
            ),
          ),

          // 3. Footer / Logout (Fixed at the bottom)
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _SidebarItem(
              icon: Icons.logout,
              label: 'Logout',
              isActive: false,
              isDestructive: true,
              onTap: () => onSelect(5),
            ),
          ),
          const SizedBox(height: 8), // Small padding at the very bottom
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive, isDestructive;
  final VoidCallback onTap;
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isDestructive
            ? Colors.red
            : isActive
            ? const Color(0xFFF47C20)
            : Colors.grey[700]!;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:
              isActive
                  ? const Color(0xFFF47C20).withOpacity(0.08)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  Original StatCard and ActionCard preserved
// ════════════════════════════════════════════════════════════════════════════
class StatCard extends StatelessWidget {
  final String count, label, imagePath;
  final Color color;
  const StatCard({
    super.key,
    required this.count,
    required this.label,
    required this.imagePath,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              imagePath,
              width: 28,
              height: 28,
              color: color,
              errorBuilder:
                  (_, __, ___) => Icon(Icons.bar_chart, color: color, size: 28),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1D1D1D),
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  final String title, subtitle, imagePath;
  final Color iconColor, borderColor;
  final int badgeCount;
  final VoidCallback onTap;
  const ActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.iconColor,
    required this.borderColor,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    imagePath,
                    width: 45,
                    height: 45,
                    fit: BoxFit.contain,
                    errorBuilder:
                        (_, __, ___) =>
                            Icon(Icons.business, color: iconColor, size: 45),
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

void _handleLogout(BuildContext context) async {
  final confirm =
      await showDialog<bool>(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Logout'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Logout',
                    style: TextStyle(color: Color(0xFFF47C20)),
                  ),
                ),
              ],
            ),
      ) ??
      false;

  if (!confirm) return;
  try {
    await FirebaseAuth.instance.signOut();
    final g = GoogleSignIn();
    if (await g.isSignedIn()) {
      await g.disconnect();
      await g.signOut();
    }
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (r) => false,
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
    }
  }
}
