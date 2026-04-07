import 'package:flutter/material.dart';
import 'package:venuemate_system/Services/auth_service.dart';
import 'package:venuemate_system/Screens/Customers/LoginScreen.dart';
import 'package:venuemate_system/Screens/HallAdmin/hall_admin_home.dart';
import 'package:venuemate_system/Screens/HallAdmin/hall_admin_profile.dart';
import 'package:venuemate_system/Screens/HallAdmin/hall_admin_bookings.dart';
import 'package:venuemate_system/Screens/HallAdmin/hall_admin_messaging.dart';

const double _kHallWebBreak = 950;

class HallAdminRootLayout extends StatefulWidget {
  const HallAdminRootLayout({super.key});

  @override
  State<HallAdminRootLayout> createState() => _HallAdminRootLayoutState();
}

class _HallAdminRootLayoutState extends State<HallAdminRootLayout> {
  int _selectedIndex = 0;

  static const _navItems = [
    {
      'icon': Icons.home_outlined,
      'activeIcon': Icons.home_rounded,
      'label': 'Home',
    },
    {
      'icon': Icons.calendar_today_outlined,
      'activeIcon': Icons.calendar_today_rounded,
      'label': 'Bookings',
    },
    {
      'icon': Icons.chat_bubble_outline,
      'activeIcon': Icons.chat_bubble_rounded,
      'label': 'Messages',
    },
    {
      'icon': Icons.person_outline,
      'activeIcon': Icons.person_rounded,
      'label': 'Profile',
    },
  ];

  List<Widget> get _screens => [
    const HallAdminHomeScreen(),
    const HallAdminBookingsScreen(),
    const HallAdminMessagingScreen(),
    const HallAdminProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= _kHallWebBreak;
    return isWide ? _buildWebLayout() : _buildMobileLayout();
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  WEB LAYOUT — sidebar + content
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          _WebSidebar(
            selectedIndex: _selectedIndex,
            onSelect: (i) {
              if (i == 4) {
                _handleLogout(context);
              } else {
                setState(() => _selectedIndex = i);
              }
            },
          ),
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: _screens),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  MOBILE LAYOUT — unchanged bottom nav
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double tabWidth = constraints.maxWidth / 4;
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
                        children: List.generate(
                          _navItems.length,
                          (index) => _buildNavItem(index, tabWidth),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavItem(int index, double tabWidth) {
    final bool isSelected = _selectedIndex == index;
    const Color brandOrange = Color(0xFFF47C20);
    const Color inactiveGrey = Colors.black54;
    final icon =
        isSelected
            ? _navItems[index]['activeIcon'] as IconData
            : _navItems[index]['icon'] as IconData;

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
              _navItems[index]['label'] as String,
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
}

// ══════════════════════════════════════════════════════════════════════════════
//  WEB SIDEBAR
// ══════════════════════════════════════════════════════════════════════════════
class _WebSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _WebSidebar({required this.selectedIndex, required this.onSelect});

  static const _items = [
    {
      'icon': Icons.home_outlined,
      'activeIcon': Icons.home_rounded,
      'label': 'Home',
    },
    {
      'icon': Icons.calendar_today_outlined,
      'activeIcon': Icons.calendar_today_rounded,
      'label': 'Bookings',
    },
    {
      'icon': Icons.chat_bubble_outline,
      'activeIcon': Icons.chat_bubble_rounded,
      'label': 'Messages',
    },
    {
      'icon': Icons.person_outline,
      'activeIcon': Icons.person_rounded,
      'label': 'Profile',
    },
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo / brand header
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF47C20), Color(0xFFFFD166)],
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.store_rounded, color: Colors.white, size: 26),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Hall Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Nav items
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
                    final isActive = selectedIndex == i;
                    final color =
                        isActive ? const Color(0xFFF47C20) : Colors.grey[700]!;
                    final icon =
                        isActive
                            ? _items[i]['activeIcon'] as IconData
                            : _items[i]['icon'] as IconData;
                    return InkWell(
                      onTap: () => onSelect(i),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
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
                                _items[i]['label'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      isActive
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Logout footer
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: InkWell(
              onTap: () => onSelect(4),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.logout, size: 20, color: Colors.red),
                    const SizedBox(width: 12),
                    const Text(
                      'Logout',
                      style: TextStyle(fontSize: 14, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
