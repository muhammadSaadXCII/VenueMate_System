import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:venuemate_system/Services/auth_service.dart';
import 'package:venuemate_system/Services/notification_service.dart';
import 'package:venuemate_system/Screens/Customers/LoginScreen.dart';
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
  int _currentIndex = 0;
  StreamSubscription<DocumentSnapshot>? _userSub;

  final List<Widget> _screens = [
    const HomeScreen(),
    const FavoritesScreen(),
    const MapScreen(),
    const ChatListScreen(),
    const Profilescreen(),
  ];

  @override
  void initState() {
    super.initState();
    _listenForDisable();
  }

  void _listenForDisable() {
    final uid = AuthService.currentUid;
    if (uid == null) return;
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
