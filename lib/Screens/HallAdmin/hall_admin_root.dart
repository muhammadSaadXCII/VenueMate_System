import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:venuemate_system/Screens/HallAdmin/hall_admin_bookings.dart';
import 'package:venuemate_system/Screens/HallAdmin/hall_admin_home.dart';
import 'package:venuemate_system/Screens/HallAdmin/hall_admin_messaging.dart';
import 'package:venuemate_system/Screens/HallAdmin/hall_admin_profile.dart';

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

  @override
  Widget build(BuildContext context) {
    final double tabWidth = MediaQuery.of(context).size.width / 4;

    return Scaffold(
      backgroundColor: Colors.white,
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 300),
        reverse: false,
        transitionBuilder: (child, animation, secondaryAnimation) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Container(
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
              children: [
                _buildNavItem(0, Icons.home_outlined, "Home"),
                _buildNavItem(1, Icons.calendar_today_outlined, "Bookings"),
                _buildNavItem(2, Icons.chat_bubble_outline, "Messages"),
                _buildNavItem(3, Icons.person_outline, "Profile"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
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

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}
