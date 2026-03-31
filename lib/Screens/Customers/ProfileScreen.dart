import 'package:flutter/material.dart';
import 'package:venuemate_system/Services/auth_service.dart';
import 'package:venuemate_system/Services/user_service.dart';
import 'package:venuemate_system/Models/user_model.dart';
import 'package:venuemate_system/Utils/app_navigation.dart';
import 'package:venuemate_system/Screens/Shared/settings.dart';
import 'package:venuemate_system/Screens/Customers/LoginScreen.dart';
import 'package:venuemate_system/Screens/Shared/user_complaint_center.dart';
import 'AllEventsScreen.dart';
import 'NotificationScreen.dart';
import 'EditProfileScreen.dart';

class Profilescreen extends StatelessWidget {
  const Profilescreen({super.key});

  String _memberSince(DateTime dt) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return 'Member Since ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.currentUid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: StreamBuilder<UserModel?>(
        stream: UserService.streamUser(uid),
        builder: (context, snap) {
          final user = snap.data;

          return SingleChildScrollView(
            child: Column(
              children: [
                // ── Curved orange header ──────────────────────────────────
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    ClipPath(
                      clipper: _BottomCurveClipper(),
                      child: Container(
                        height: 320,
                        width: double.infinity,
                        padding: const EdgeInsets.only(
                          top: 60,
                          left: 20,
                          right: 20,
                        ),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFF47C20), Color(0xFFFFD166)],
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Avatar
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: _buildAvatar(user, radius: 40),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Real name
                                    snap.connectionState ==
                                            ConnectionState.waiting
                                        ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                        : Text(
                                          user?.name ?? 'Hall Admin',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    const SizedBox(height: 4),
                                    // Real email
                                    Text(
                                      user?.email ??
                                          AuthService
                                              .currentFirebaseUser
                                              ?.email ??
                                          '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        decoration: TextDecoration.underline,
                                        decorationColor: Colors.white,
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

                    // Dashboard buttons card
                    Positioned(
                      bottom: -30,
                      left: 20,
                      right: 20,
                      child: Container(
                        height: 100,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _DashboardButton(
                              icon: Icons.calendar_month_outlined,
                              label: 'All Bookings',
                              onTap:
                                  () => AppNavigation.push(
                                    context,
                                    const AllEventsScreen(),
                                  ),
                            ),
                            _DashboardButton(
                              icon: Icons.notifications_outlined,
                              label: 'Notifications',
                              onTap:
                                  () => AppNavigation.push(
                                    context,
                                    const NotificationScreen(),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 55),

                // ── Menu list ─────────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _ProfileMenuTile(
                        icon: Icons.person_outline,
                        title: 'Edit Profile',
                        onTap:
                            () => AppNavigation.push(
                              context,
                              EditProfileScreen(),
                            ),
                      ),
                      _divider(),
                      _ProfileMenuTile(
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                        onTap:
                            () => AppNavigation.push(
                              context,
                              const SettingsScreen(),
                            ),
                      ),
                      _divider(),
                      _ProfileMenuTile(
                        icon: Icons.report_problem_outlined,
                        title: 'Complaint Center',
                        onTap:
                            () => AppNavigation.push(
                              context,
                              const UserComplaintCenterScreen(),
                            ),
                      ),
                      _divider(),
                      _ProfileMenuTile(
                        icon: Icons.logout_outlined,
                        title: 'Logout',
                        onTap: () => _handleLogout(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Text(
                  user != null
                      ? _memberSince(user.createdAt)
                      : 'Member Since —',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar(UserModel? user, {double radius = 40}) {
    final url = user?.profileImageUrl ?? '';
    if (url.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white,
        backgroundImage: NetworkImage(url),
      );
    }
    final name = user?.name ?? '';
    final initials =
        name.trim().isNotEmpty
            ? name
                .trim()
                .split(' ')
                .map((w) => w[0].toUpperCase())
                .take(2)
                .join()
            : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      child: Text(
        initials,
        style: TextStyle(
          color: const Color(0xFFF47C20),
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.5,
        ),
      ),
    );
  }

  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 20),
    child: Divider(height: 1, color: Color(0xFFEEEEEE)),
  );
}

// ── Logout ─────────────────────────────────────────────────────────────────
Future<void> _handleLogout(BuildContext context) async {
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
    await AuthService.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
    }
  }
}

// ── Custom clipper ─────────────────────────────────────────────────────────
class _BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 30,
      size.width,
      size.height - 50,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> _) => false;
}

// ── Dashboard button ───────────────────────────────────────────────────────
class _DashboardButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DashboardButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 32, color: const Color(0xFF1D1D1D)),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    ),
  );
}

// ── Profile menu tile ──────────────────────────────────────────────────────
class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
    leading: Icon(icon, color: Colors.black87, size: 28),
    title: Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black54,
      ),
    ),
    trailing: const Icon(
      Icons.arrow_forward_ios,
      size: 16,
      color: Colors.black87,
    ),
  );
}
