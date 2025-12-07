import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:venuemate_system/Screens/Customers/LoginScreen.dart';
import 'package:venuemate_system/Screens/HallAdmin/hall_admin_home.dart';
import 'package:venuemate_system/Screens/HallAdmin/hall_admin_profile.dart';
import 'package:venuemate_system/Screens/HallAdmin/hall_admin_bookings.dart';
import 'package:venuemate_system/Screens/HallAdmin/hall_admin_messaging.dart';

class HallAdminRootLayout extends StatefulWidget {
  const HallAdminRootLayout({super.key});

  @override
  State<HallAdminRootLayout> createState() => _HallAdminRootLayoutState();
}

class _HallAdminRootLayoutState extends State<HallAdminRootLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HallAdminHomeScreen(),
    const HallAdminBookingsScreen(),
    const HallAdminMessagingScreen(),
    const HallAdminProfileScreen(),
  ];

  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.home_outlined, 'label': 'Home'},
    {'icon': Icons.calendar_today_outlined, 'label': 'Bookings'},
    {'icon': Icons.chat_bubble_outline, 'label': 'Messages'},
    {'icon': Icons.person_outline, 'label': 'Profile'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 700) {
            return _buildDesktopLayout();
          } else {
            return _buildMobileLayout(constraints.maxWidth);
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Container(
          width: 280,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              right: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 100,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: const Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      color: Color(0xFFF58529),
                      size: 32,
                    ),
                    SizedBox(width: 12),
                    Text(
                      "VenueMate",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
              const SizedBox(height: 24),

              Expanded(
                child: ListView.builder(
                  itemCount: _navItems.length,
                  itemBuilder: (context, index) {
                    final item = _navItems[index];
                    final isSelected = _selectedIndex == index;
                    return _SidebarItem(
                      icon: item['icon'],
                      label: item['label'],
                      isSelected: isSelected,
                      onTap: () => setState(() => _selectedIndex = index),
                    );
                  },
                ),
              ),

              const Divider(height: 1),
              _SidebarItem(
                icon: Icons.logout,
                label: "Logout",
                isSelected: false,
                isDestructive: true,
                onTap: () => _handleLogout(context),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),

        Expanded(
          child: Container(
            color: const Color(0xFFF9FAFB),
            child: _screens[_selectedIndex],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(double screenWidth) {
    final double tabWidth = screenWidth / 4;

    return Stack(
      children: [
        Positioned.fill(bottom: 80, child: _screens[_selectedIndex]),

        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  top: 0,

                  left: (_selectedIndex * tabWidth) + (tabWidth / 2) - 24,
                  child: Container(
                    alignment: Alignment.center,
                    width: 48,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF58529),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(4),
                      ),
                    ),
                  ),
                ),

                Row(
                  children: List.generate(_navItems.length, (index) {
                    return _buildMobileNavItem(
                      index,
                      _navItems[index]['icon'],
                      _navItems[index]['label'],
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    const Color brandOrange = Color(0xFFF58529);
    const Color inactiveGrey = Colors.black54;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 6),
            Icon(
              icon,
              color: isSelected ? brandOrange : inactiveGrey,
              size: 30,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? brandOrange : inactiveGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = const Color(0xFFF58529);
    final Color textColor =
        isDestructive
            ? Colors.red
            : (isSelected ? activeColor : Colors.grey[700]!);
    final Color iconColor =
        isDestructive
            ? Colors.red
            : (isSelected ? activeColor : Colors.grey[500]!);
    final Color bgColor =
        isSelected ? activeColor.withOpacity(0.1) : Colors.transparent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isSelected
                        ? activeColor.withOpacity(0.2)
                        : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SAFE LOGOUT LOGIC (FIXED)
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
                  // FIX 1: Use Navigator.pop(true) instead of calling recursive function
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
      // FIX 2: Added try-catch and isSignedIn check
      try {
        final googleSignIn = GoogleSignIn();
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.disconnect();
          await googleSignIn.signOut();
        }
      } catch (e) {
        // Just ignore google errors, so user can still logout from app
        debugPrint("Google logout error (ignored): $e");
      }

      if (!context.mounted) return;

      // 3. Navigate to Login
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