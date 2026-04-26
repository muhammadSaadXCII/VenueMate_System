import 'package:flutter/material.dart';
import 'package:venuemate_system/Services/auth_service.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:venuemate_system/Screens/Customers/LoginScreen.dart';
import 'package:venuemate_system/Services/notification_service.dart';
import 'package:venuemate_system/Services/hall_service.dart';
import 'package:venuemate_system/Models/hall_model.dart';
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
  Stream<HallModel?>? _hallStream;
  StreamSubscription<DocumentSnapshot>? _userSub;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _hallStream = HallService.streamHallByOwnerId(uid);
      _listenForDisable(uid);
    }
  }

  void _listenForDisable(String uid) {
    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snap) {
          if (!snap.exists) return;
          final data = snap.data();
          if (data == null) return;
          final isDisabled = data['isDisabled'] as bool? ?? false;
          if (isDisabled && mounted) _forceLogout();
        });
  }

  Future<void> _forceLogout() async {
    await _userSub?.cancel();
    final uid = AuthService.currentUid;
    if (uid != null) await NotificationService.removeToken(uid: uid);
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DisabledDialog(),
    );
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }

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
    return StreamBuilder<HallModel?>(
      stream: _hallStream,
      builder: (context, snap) {
        final hallDisabled =
            snap.hasData && snap.data != null && !snap.data!.isVisible;
        final isWide = MediaQuery.of(context).size.width >= _kHallWebBreak;
        return isWide
            ? _buildWebLayout(hallDisabled: hallDisabled)
            : _buildMobileLayout(hallDisabled: hallDisabled);
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  WEB LAYOUT — sidebar + content
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout({required bool hallDisabled}) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          _WebSidebar(
            selectedIndex: _selectedIndex,
            hallDisabled: hallDisabled,
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
  Widget _buildMobileLayout({required bool hallDisabled}) {
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
                          (index) => _buildNavItem(
                            index,
                            tabWidth,
                            hallDisabled: hallDisabled,
                          ),
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

  Widget _buildNavItem(
    int index,
    double tabWidth, {
    bool hallDisabled = false,
  }) {
    final bool isSelected = _selectedIndex == index;
    const Color brandOrange = Color(0xFFF47C20);
    const Color inactiveGrey = Colors.black54;
    // index 1 = Bookings tab
    final bool isBookingsTab = index == 1;
    final bool isLocked = isBookingsTab && hallDisabled;

    final Color itemColor =
        isLocked
            ? Colors.grey.shade400
            : (isSelected ? brandOrange : inactiveGrey);

    final icon =
        isLocked
            ? Icons.block_rounded
            : (isSelected
                ? _navItems[index]['activeIcon'] as IconData
                : _navItems[index]['icon'] as IconData);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (isLocked) return; // block navigation to Bookings when disabled
          setState(() => _selectedIndex = index);
        },
        behavior: HitTestBehavior.opaque,
        child: Opacity(
          opacity: isLocked ? 0.5 : 1.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 6),
              Icon(icon, color: itemColor, size: 30),
              const SizedBox(height: 4),
              Text(
                _navItems[index]['label'] as String,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: itemColor,
                ),
              ),
            ],
          ),
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
      final uid = FirebaseAuth.instance.currentUser?.uid;
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
}

// ══════════════════════════════════════════════════════════════════════════════
//  WEB SIDEBAR
// ══════════════════════════════════════════════════════════════════════════════
class _WebSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool hallDisabled;

  const _WebSidebar({
    required this.selectedIndex,
    required this.onSelect,
    this.hallDisabled = false,
  });

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
                    // index 1 = Bookings tab
                    final isLocked = i == 1 && hallDisabled;
                    final color =
                        isLocked
                            ? Colors.grey.shade400
                            : (isActive
                                ? const Color(0xFFF47C20)
                                : Colors.grey[700]!);
                    final icon =
                        isLocked
                            ? Icons.block_rounded
                            : (isActive
                                ? _items[i]['activeIcon'] as IconData
                                : _items[i]['icon'] as IconData);
                    return Opacity(
                      opacity: isLocked ? 0.5 : 1.0,
                      child: InkWell(
                        onTap: isLocked ? null : () => onSelect(i),
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
                                isActive && !isLocked
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
                                        isActive && !isLocked
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                    color: color,
                                  ),
                                ),
                              ),
                              if (isLocked)
                                const Icon(
                                  Icons.lock_outline,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                            ],
                          ),
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

// ── Shared disabled-account dialog ────────────────────────────────────────────
class _DisabledDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Column(
        children: [
          Icon(Icons.block_rounded, color: Color(0xFFD92D20), size: 56),
          SizedBox(height: 12),
          Text(
            'Account Deactivated',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Color(0xFFD92D20),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Your account has been deactivated by the system administrator. '
            'You have been signed out automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[700],
              height: 1.6,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFD92D20).withOpacity(0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Color(0xFFD92D20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'If you believe this is a mistake, please contact VenueMate support.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD92D20),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
