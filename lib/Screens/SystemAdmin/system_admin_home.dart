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

class SystemAdminHome extends StatefulWidget {
  const SystemAdminHome({super.key});

  @override
  State<SystemAdminHome> createState() => _SystemAdminHomeState();
}

class _SystemAdminHomeState extends State<SystemAdminHome> {
  final _db = FirebaseFirestore.instance;

  // ── Stream helpers ─────────────────────────────────────────────────────────
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

  // One-time stat fetches (cached in FutureBuilder)
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Pending Registrations action card ──────────────────
                  StreamBuilder<int>(
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
                        onTap:
                            () => AppNavigation.push(
                              context,
                              const PendingRegistrationsScreen(),
                            ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Complaints action card ─────────────────────────────
                  StreamBuilder<int>(
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
                        onTap:
                            () => AppNavigation.push(
                              context,
                              const ComplaintsScreen(),
                            ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // ── Statistics ────────────────────────────────────────
                  const Text(
                    'Statistics',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  // const SizedBox(height: 16),
                  FutureBuilder<Map<String, int>>(
                    future: _fetchStats(),
                    builder: (context, snap) {
                      final stats = snap.data;
                      return GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.1,
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
                            count:
                                stats == null ? '—' : '${stats['cancelled']}',
                            label: 'Cancelled',
                            imagePath: 'assets/images/cancelfile.png',
                            color: Colors.red,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // ── Quick Links ──────────────────────────────────────
                  const Text(
                    'Quick Links',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _ManagementTile(
                    title: 'Manage All Halls',
                    imagePath: 'assets/images/hallpic.png',
                    onTap:
                        () => AppNavigation.push(
                          context,
                          const ManageAllHallsScreen(),
                        ),
                  ),
                  const SizedBox(height: 12),
                  _ManagementTile(
                    title: 'Manage All Users',
                    imagePath: 'assets/images/users.png',
                    onTap:
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

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
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
              // Logout
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
              // Notifications
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
}

// ══════════════════════════════════════════════════════════════════════════════
//  SHARED WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class StatCard extends StatelessWidget {
  final String count;
  final String label;
  final String imagePath;
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1D1D1D),
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final Color iconColor;
  final Color borderColor;
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
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
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

class _ManagementTile extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback onTap;

  const _ManagementTile({
    required this.title,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
}

// ── Logout ─────────────────────────────────────────────────────────────────
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
    try {
      final g = GoogleSignIn();
      if (await g.isSignedIn()) {
        await g.disconnect();
        await g.signOut();
      }
    } catch (_) {}
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
