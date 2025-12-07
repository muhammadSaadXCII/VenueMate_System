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
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 750) {
            return _buildDesktopLayout(context);
          } else {
            return _buildMobileLayout(context);
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 260,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Colors.grey.shade200)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        _buildSidebarHeader(),
                        const SizedBox(height: 20),

                        _SidebarItem(
                          icon: Icons.dashboard_outlined,
                          label: "Dashboard",
                          isActive: _selectedIndex == 0,
                          onTap: () => setState(() => _selectedIndex = 0),
                        ),

                        _SidebarItem(
                          icon: Icons.account_balance_outlined,
                          label: "Manage Halls",
                          isActive: _selectedIndex == 1,
                          onTap: () => setState(() => _selectedIndex = 1),
                        ),

                        _SidebarItem(
                          icon: Icons.people_outline,
                          label: "Manage Users",
                          isActive: _selectedIndex == 2,
                          onTap: () => setState(() => _selectedIndex = 2),
                        ),

                        _SidebarItem(
                          icon: Icons.notifications_outlined,
                          label: "Notifications",
                          isActive: _selectedIndex == 3,
                          showBadge: true,
                          onTap: () => setState(() => _selectedIndex = 3),
                        ),

                        const Expanded(child: SizedBox(height: 40)),

                        _SidebarItem(
                          icon: Icons.logout,
                          label: "Logout",
                          isDestructive: true,
                          onTap: () => _handleLogout(context),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        Expanded(child: _getSelectedScreen()),
      ],
    );
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return _DashboardContent(
          onNavigateToPending: () {
            AppNavigation.push(context, const PendingRegistrationsScreen());
          },
          onNavigateToComplaints: () {
            AppNavigation.push(context, const ComplaintsScreen());
          },
        );
      case 1:
        return const ManageAllHallsScreen();
      case 2:
        return const ManageAllUsersScreen();
      case 3:
        return const UserNotificationsScreen();
      default:
        return _DashboardContent(
          onNavigateToPending: () {},
          onNavigateToComplaints: () {},
        );
    }
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AdminHeaderMobile(context: context),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ActionCard(
                  title: "4 Pending Registrations",
                  subtitle: "Review submissions",
                  icon: Icons.description_outlined,
                  iconColor: Colors.amber,
                  borderColor: Colors.amber,
                  secondaryIcon: Icons.access_time_filled,
                  isDesktop: false,
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
                  icon: Icons.assignment_late_outlined,
                  iconColor: Colors.redAccent,
                  borderColor: Colors.redAccent,
                  secondaryIcon: Icons.warning,
                  isDesktop: false,
                  onTap:
                      () => AppNavigation.push(context, const ComplaintsScreen()),
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
                      icon: Icons.store,
                      color: Colors.blue,
                      isDesktop: false,
                    ),
                    StatCard(
                      count: "500",
                      label: "Total Users",
                      icon: Icons.group,
                      color: Colors.purple,
                      isDesktop: false,
                    ),
                    StatCard(
                      count: "320",
                      label: "Bookings",
                      icon: Icons.calendar_today,
                      color: Colors.orange,
                      isDesktop: false,
                    ),
                    StatCard(
                      count: "15",
                      label: "Cancelled",
                      icon: Icons.cancel,
                      color: Colors.red,
                      isDesktop: false,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  "Quick Links",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _MobileManagementTile(
                  title: "Manage All Halls",
                  icon: Icons.account_balance,
                  onTap:
                      () => AppNavigation.push(
                        context,
                        const ManageAllHallsScreen(),
                      ),
                ),
                const SizedBox(height: 12),
                _MobileManagementTile(
                  title: "Manage All Users",
                  icon: Icons.people,
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

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: const Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFFEA845),
            child: Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "VenueMate Admin",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final VoidCallback onNavigateToPending;
  final VoidCallback onNavigateToComplaints;

  const _DashboardContent({
    required this.onNavigateToPending,
    required this.onNavigateToComplaints,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDesktopHeader(),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ActionCard(
                      title: "4 Pending",
                      subtitle: "Registrations",
                      icon: Icons.description_outlined,
                      iconColor: Colors.amber,
                      borderColor: Colors.amber,
                      secondaryIcon: Icons.access_time_filled,
                      isDesktop: true,
                      onTap: onNavigateToPending,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ActionCard(
                      title: "2 Complaints",
                      subtitle: "Need Review",
                      icon: Icons.assignment_late_outlined,
                      iconColor: Colors.redAccent,
                      borderColor: Colors.redAccent,
                      secondaryIcon: Icons.warning,
                      isDesktop: true,
                      onTap: onNavigateToComplaints,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                "Overview",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 100,
                ),
                itemBuilder: (context, index) {
                  final stats = [
                    {
                      'count': "150",
                      'label': "Total Halls",
                      'icon': Icons.store,
                      'color': Colors.blue,
                    },
                    {
                      'count': "500",
                      'label': "Active Users",
                      'icon': Icons.group,
                      'color': Colors.purple,
                    },
                    {
                      'count': "320",
                      'label': "Bookings",
                      'icon': Icons.calendar_today,
                      'color': Colors.orange,
                    },
                    {
                      'count': "12",
                      'label': "Cancelled",
                      'icon': Icons.cancel_presentation,
                      'color': Colors.red,
                    },
                  ];
                  final stat = stats[index];
                  return StatCard(
                    count: stat['count'] as String,
                    label: stat['label'] as String,
                    icon: stat['icon'] as IconData,
                    color: stat['color'] as Color,
                    isDesktop: true,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome back, Admin!",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Here is what's happening in your system today.",
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final String count;
  final String label;
  final IconData icon;
  final Color color;
  final bool isDesktop;

  const StatCard({
    super.key,
    required this.count,
    required this.label,
    required this.icon,
    required this.color,
    required this.isDesktop,
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
      child:
          isDesktop
              ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 24, color: color),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        count,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D1D1D),
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 28, color: color),
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
  final IconData icon;
  final Color iconColor;
  final Color borderColor;
  final IconData secondaryIcon;
  final bool isDesktop;
  final VoidCallback onTap;

  const ActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.borderColor,
    required this.secondaryIcon,
    required this.isDesktop,
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
              child: Icon(icon, color: iconColor, size: 28),
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
            if (isDesktop)
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDestructive;
  final bool showBadge;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.isDestructive = false,
    this.showBadge = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color:
            isDestructive
                ? Colors.red
                : (isActive ? const Color(0xFFFEA845) : Colors.grey[600]),
        size: 22,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color:
              isDestructive
                  ? Colors.red
                  : (isActive ? const Color(0xFFFEA845) : Colors.grey[800]),
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing:
          showBadge
              ? badges.Badge(
                badgeContent: const Text(
                  '3',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
                badgeStyle: const badges.BadgeStyle(badgeColor: Colors.red),
              )
              : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      selected: isActive,
      selectedTileColor: const Color(0xFFFEA845).withOpacity(0.1),
    );
  }
}

class _MobileManagementTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _MobileManagementTile({
    required this.title,
    required this.icon,
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
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Colors.grey[700]),
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

class _AdminHeaderMobile extends StatelessWidget {
  final BuildContext context;
  const _AdminHeaderMobile({required this.context});

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

// ---------------------------------------------------------------------------
// SAFE LOGOUT LOGIC (Fixed to avoid PlatformException)
// ---------------------------------------------------------------------------
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
      // 1. Always sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // 2. Try to handle Google Sign Out safely
      try {
        final googleSignIn = GoogleSignIn();
        // IMPORTANT: Check if actually signed in to avoid "Failed to disconnect"
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.disconnect();
          await googleSignIn.signOut();
        }
      } catch (e) {
        // If Google sign out fails (e.g. not logged in with Google), just ignore it
        // so the user can still leave the app.
        debugPrint("Google logout error (ignored): $e");
      }

      // 3. Navigation (Always happens)
      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      // Only show snackbar if Firebase auth fails or critical navigation error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error logging out: $e")),
        );
      }
    }
  }
}