import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:venuemate_system/Utils/app_navigation.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _buildMobileLayout(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AdminHeader(context: context),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ActionCard(
                  title: "4 Pending Registrations",
                  subtitle: "Review submissions",
                  imagePath: 'assets/images/pendingLogo.png',
                  iconColor: Colors.amber,
                  borderColor: Colors.amber,
                  secondaryIcon: Icons.access_time_filled,
                  onTap:
                      () => AppNavigation.push(
                        context,
                        const PendingRegistrationsScreen(),
                      ),
                ),
                const SizedBox(height: 16),
                ActionCard(
                  title: "2 New Complaints",
                  subtitle: "Resolve issues",
                  imagePath: 'assets/images/complaintsLogo.png',
                  iconColor: Colors.redAccent,
                  borderColor: Colors.redAccent,
                  secondaryIcon: Icons.warning,
                  onTap:
                      () =>
                          AppNavigation.push(context, const ComplaintsScreen()),
                ),
                const SizedBox(height: 32),
                const Text(
                  "Statistics",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.1,
                  children: const [
                    StatCard(
                      count: "150",
                      label: "Total Halls",
                      imagePath: 'assets/images/hallpic.png',
                      color: Colors.blue,
                    ),
                    StatCard(
                      count: "500",
                      label: "Total Users",
                      imagePath: 'assets/images/users.png',
                      color: Colors.purple,
                    ),
                    StatCard(
                      count: "320",
                      label: "Bookings",
                      imagePath: 'assets/images/bookcalendar.png',
                      color: Colors.orange,
                    ),
                    StatCard(
                      count: "15",
                      label: "Cancelled",
                      imagePath: 'assets/images/cancelfile.png',
                      color: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  "Quick Links",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                _ManagementTile(
                  title: "Manage All Halls",
                  imagePath: 'assets/images/hallpic.png',
                  onTap:
                      () => AppNavigation.push(
                        context,
                        const ManageAllHallsScreen(),
                      ),
                ),

                const SizedBox(height: 12),

                _ManagementTile(
                  title: "Manage All Users",
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
    );
  }
}

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
            child: Image.asset(imagePath, width: 28, height: 28, color: color),
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
  final IconData secondaryIcon;
  final VoidCallback onTap;

  const ActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.iconColor,
    required this.borderColor,
    required this.secondaryIcon,
    required this.onTap,
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
              ),
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

class _AdminHeader extends StatelessWidget {
  final BuildContext context;
  const _AdminHeader({required this.context});

  @override
  Widget build(BuildContext context) {
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
            "Welcome, Admin!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Row(
            children: [
              _buildHeaderIcon(
                Icons.logout,
                Colors.red,
                () => _handleLogout(context),
              ),
              const SizedBox(width: 12),
              GestureDetector(
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
                    position: badges.BadgePosition.topEnd(top: -2, end: -2),
                    showBadge: true,
                    badgeStyle: const badges.BadgeStyle(badgeColor: Colors.red),
                    child: const Icon(
                      Icons.notifications_none,
                      color: Colors.black87,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

void _handleLogout(BuildContext context) async {
  bool confirm =
      await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text("Logout"),
              content: const Text("Are you sure you want to logout?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    "Logout",
                    style: TextStyle(color: Color(0xFFF47C20)),
                  ),
                ),
              ],
            ),
      ) ??
      false;

  if (confirm) {
    try {
      await FirebaseAuth.instance.signOut();

      try {
        final googleSignIn = GoogleSignIn();

        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.disconnect();
          await googleSignIn.signOut();
        }
      } catch (e) {
        debugPrint("Google logout error (ignored): $e");
      }

      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error logging out: $e")));
      }
    }
  }
}
