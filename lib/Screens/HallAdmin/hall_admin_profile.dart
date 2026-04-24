import 'dart:async';
import 'package:flutter/material.dart';
import 'package:venuemate_system/Services/auth_service.dart';
import 'package:venuemate_system/Services/notification_service.dart';
import 'package:venuemate_system/Services/user_service.dart';
import 'package:venuemate_system/Models/user_model.dart';
import 'package:venuemate_system/Utils/app_navigation.dart';
import 'package:venuemate_system/Screens/Shared/settings.dart';
import 'package:venuemate_system/Screens/Customers/LoginScreen.dart';
import 'package:venuemate_system/Screens/HallAdmin/hall_feedbacks.dart';
import 'package:venuemate_system/Screens/Shared/user_notifications.dart';
import 'package:venuemate_system/Screens/Shared/user_complaint_center.dart';
import 'edit_profile.dart';

const double _kProfileWebBreak = 950;

class HallAdminProfileScreen extends StatelessWidget {
  const HallAdminProfileScreen({super.key});

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
    final isWide = MediaQuery.of(context).size.width >= _kProfileWebBreak;

    return StreamBuilder<UserModel?>(
      stream: UserService.streamUser(uid),
      builder: (context, snap) {
        final user = snap.data;
        return isWide
            ? _buildWebLayout(context, user, snap)
            : _buildMobileLayout(context, user, snap);
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  WEB LAYOUT
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout(
    BuildContext context,
    UserModel? user,
    AsyncSnapshot snap,
  ) {
    return Container(
      color: const Color(0xFFF5F7FA),
      child: Column(
        children: [
          // Top bar
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            color: Colors.white,
            child: const Row(
              children: [
                Text(
                  'Profile',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left — profile card
                  SizedBox(
                    width: 300,
                    child: Column(
                      children: [
                        // Profile card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: _cardDec(),
                          child: Column(
                            children: [
                              // Avatar
                              _buildAvatar(user, radius: 50),
                              const SizedBox(height: 16),
                              snap.connectionState == ConnectionState.waiting
                                  ? const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFF47C20),
                                  )
                                  : Text(
                                    user?.name ?? 'Hall Admin',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              const SizedBox(height: 6),
                              Text(
                                user?.email ??
                                    AuthService.currentFirebaseUser?.email ??
                                    '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFF47C20,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Hall Admin',
                                  style: TextStyle(
                                    color: Color(0xFFF47C20),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (user != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _memberSince(user.createdAt),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Quick links card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: _cardDec(),
                          child: Column(
                            children: [
                              _webQuickLink(
                                context,
                                Icons.feedback_outlined,
                                'Hall Feedbacks',
                                () => AppNavigation.push(
                                  context,
                                  const HallFeedbacksScreen(),
                                ),
                              ),
                              const Divider(height: 1),
                              _webQuickLink(
                                context,
                                Icons.notifications_outlined,
                                'Notifications',
                                () => AppNavigation.push(
                                  context,
                                  const UserNotificationsScreen(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Right — account settings
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: _cardDec(),
                          child: Column(
                            children: [
                              _webMenuTile(
                                icon: Icons.person_outline,
                                title: 'Edit Profile',
                                subtitle: 'Update your name, phone and photo',
                                onTap:
                                    () => AppNavigation.push(
                                      context,
                                      HallAdminEditProfileScreen(),
                                    ),
                              ),
                              const Divider(
                                height: 1,
                                indent: 20,
                                endIndent: 20,
                              ),
                              _webMenuTile(
                                icon: Icons.settings_outlined,
                                title: 'Settings',
                                subtitle: 'App preferences and notifications',
                                onTap:
                                    () => AppNavigation.push(
                                      context,
                                      const SettingsScreen(),
                                    ),
                              ),
                              const Divider(
                                height: 1,
                                indent: 20,
                                endIndent: 20,
                              ),
                              _webMenuTile(
                                icon: Icons.report_problem_outlined,
                                title: 'Complaint Center',
                                subtitle: 'File and track your complaints',
                                onTap:
                                    () => AppNavigation.push(
                                      context,
                                      const UserComplaintCenterScreen(),
                                    ),
                              ),
                              const Divider(
                                height: 1,
                                indent: 20,
                                endIndent: 20,
                              ),
                              _webMenuTile(
                                icon: Icons.logout_outlined,
                                title: 'Logout',
                                subtitle: 'Sign out of your account',
                                onTap: () => _handleLogout(context),
                                isDestructive: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _webMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : Colors.black87;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color:
              isDestructive
                  ? Colors.red.shade50
                  : const Color(0xFFF47C20).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : const Color(0xFFF47C20),
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _webQuickLink(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: const Color(0xFFF47C20), size: 22),
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 12,
        color: Colors.grey[400],
      ),
      dense: true,
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  MOBILE LAYOUT (unchanged)
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout(
    BuildContext context,
    UserModel? user,
    AsyncSnapshot snap,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
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
                                snap.connectionState == ConnectionState.waiting
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
                                Text(
                                  user?.email ??
                                      AuthService.currentFirebaseUser?.email ??
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
                          icon: Icons.feedback_outlined,
                          label: 'Hall Feedbacks',
                          onTap:
                              () => AppNavigation.push(
                                context,
                                const HallFeedbacksScreen(),
                              ),
                        ),
                        _DashboardButton(
                          icon: Icons.notifications_outlined,
                          label: 'Notifications',
                          onTap:
                              () => AppNavigation.push(
                                context,
                                const UserNotificationsScreen(),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 55),

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
                          HallAdminEditProfileScreen(),
                        ),
                  ),
                  _divider(),
                  _ProfileMenuTile(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap:
                        () =>
                            AppNavigation.push(context, const SettingsScreen()),
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
              user != null ? _memberSince(user.createdAt) : 'Member Since —',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Shared helpers ──────────────────────────────────────────────────────────
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

  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 20),
    child: Divider(height: 1, color: Color(0xFFEEEEEE)),
  );
}

// ── Logout ─────────────────────────────────────────────────────────────────────
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
    final uid = AuthService.currentUid;
    if (uid != null) await NotificationService.removeToken(uid: uid);
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

// ── Custom clipper ──────────────────────────────────────────────────────────────
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

// ── Dashboard button ────────────────────────────────────────────────────────────
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

// ── Profile menu tile ───────────────────────────────────────────────────────────
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
