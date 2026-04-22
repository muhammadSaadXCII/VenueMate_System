import 'dart:async';
import 'package:venuemate_system/Screens/Customers/MainNavigation.dart';
import 'LoginScreen.dart';
import 'package:flutter/material.dart';
import 'package:venuemate_system/Services/auth_service.dart';
import 'package:venuemate_system/Services/notification_service.dart';
import 'package:venuemate_system/Models/user_model.dart';
import 'package:venuemate_system/Screens/Customers/OnBoardingScreen.dart';
import 'package:venuemate_system/Screens/HallAdmin/hall_registration_intro.dart';
import 'package:venuemate_system/Screens/SystemAdmin/system_admin_home.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
    _checkLoginStatus();
  }

  // ── Auto-login: check Firebase Auth + Firestore role ──────────────────────
  void _checkLoginStatus() async {
    // Wait for splash animation
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isOnboarded = prefs.getBool('onboarded') ?? false;

    if (!AuthService.isLoggedIn) {
      if (isOnboarded) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) => const LoginScreen(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      } else {
        _navigateToOnboarding();
      }
      return;
    }

    // ✅ Use AuthService instead of raw Firestore calls
    final UserModel? user = await AuthService.getCurrentUser();

    if (!mounted) return;

    if (user == null) {
      // Logged in on Auth but no Firestore record — sign them out and restart
      final uid = AuthService.currentUid;
      if (uid != null) unawaited(NotificationService.removeToken(uid: uid));
      await AuthService.signOut();
      _navigateToOnboarding();
      return;
    }

    if (!user.isActive) {
      unawaited(NotificationService.removeToken(uid: user.uid));
      await AuthService.signOut();
      if (!mounted) return;
      _showDeactivatedAndGoToOnboarding();
      return;
    }

    // Init FCM token for this session
    unawaited(NotificationService.initAndSaveToken(uid: user.uid));

    // Route based on role
    Widget destination;
    if (user.isSystemAdmin) {
      destination = const SystemAdminHome();
    } else if (user.isVenueOwner) {
      destination = const HallRegistrationIntroScreen();
    } else {
      destination = const MainNavigation();
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => destination));
  }

  void _showDeactivatedAndGoToOnboarding() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Column(
              children: [
                Icon(Icons.block, color: Colors.red, size: 52),
                SizedBox(height: 12),
                Text(
                  'Account Deactivated',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your account has been deactivated by the system administrator.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700], height: 1.5),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.red.shade700,
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
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToOnboarding();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
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
          ),
    );
  }

  void _navigateToOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF47C20),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Image.asset(
                    'assets/images/venuemate.png',
                    fit: BoxFit.contain,
                    errorBuilder:
                        (_, __, ___) => const Icon(
                          Icons.account_balance,
                          size: 50,
                          color: Color(0xFFF47C20),
                        ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'VenueMate',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Find Your Perfect Venue',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
