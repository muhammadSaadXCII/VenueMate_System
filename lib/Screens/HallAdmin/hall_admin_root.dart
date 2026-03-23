import 'package:flutter/material.dart';
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
          return _buildMobileLayout(constraints.maxWidth);
        },
      ),
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
                      color: Color(0xFFF47C20),
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
    const Color brandOrange = Color(0xFFF47C20);
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
