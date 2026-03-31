import 'package:flutter/material.dart';
import 'HomePageVenueScreen.dart';
import 'FavoritesScreen.dart';
import 'MapScreen.dart';
import 'MessagingScreen.dart';
import 'ProfileScreen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // Keeps track of the currently selected tab
  int _currentIndex = 0;

  // The list of screens to be displayed
  // IndexedStack will keep these in memory to prevent reloading
  final List<Widget> _screens = [
    const HomeScreen(),
    const FavoritesScreen(),
    const MapScreen(),
    const ChatListScreen(),
    const Profilescreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack preserves the state of all tabs (scroll position, map zoom, etc.)
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFF47C20),
        unselectedItemColor: Colors.black,
        backgroundColor: Colors.white,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        // Removes the default shifting animation for a cleaner look
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          _navItem(Icons.home_outlined, "Home", 0),
          _navItem(Icons.favorite_border, "Favorites", 1),
          _navItem(Icons.map_outlined, "Map", 2),
          _navItem(Icons.message_outlined, "Messages", 3),
          _navItem(Icons.person_outline, "Profile", 4),
        ],
      ),
    );
  }

  /// Helper method to build custom Navigation Items with an animated indicator bar
  BottomNavigationBarItem _navItem(IconData icon, String label, int index) {
    bool isActive = _currentIndex == index;

    return BottomNavigationBarItem(
      label: label,
      icon: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFFF47C20) : Colors.black,
              size: 26,
            ),
            const SizedBox(height: 4),
            // Animated indicator bar underneath the active icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 3,
              width: isActive ? 24 : 0,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFF47C20) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
