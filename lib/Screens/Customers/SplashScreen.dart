import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:venuemate_system/Screens/HallAdmin/hall_registration_intro.dart';
import 'package:venuemate_system/Screens/SystemAdmin/system_admin_home.dart';
import 'OnBoardingScreen.dart'; 
import 'HomePageVenueScreen.dart'; 


class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
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

  // --- AUTO LOGIN LOGIC ---
  void _checkLoginStatus() async {
    // Kept duration same as your logic
    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) return;

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
          String role = data?['role'] ?? 'customer';

          if (!mounted) return;

          // --- ROLE BASED REDIRECTION ---
          if (role == 'system_admin') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const SystemAdminHome()),
            );
          } else if (role == 'venue_owner') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HallRegistrationIntroScreen()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
             _navigateToOnboarding(); // Fallback for now if home isn't ready
          }
        } else {
          _navigateToOnboarding();
        }
      } catch (e) {
        debugPrint("Error fetching user data: $e");
        _navigateToOnboarding();
      }
    } else {
      _navigateToOnboarding();
    }
  }

  void _navigateToOnboarding() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Breakpoint logic: > 600 width is typically tablet/desktop
          final bool isDesktop = constraints.maxWidth > 600;

          // Responsive Sizes
          final double logoSize = isDesktop ? 200.0 : 120.0;
          final double titleSize = isDesktop ? 48.0 : 32.0;
          final double subtitleSize = isDesktop ? 24.0 : 16.0;
          final double iconSize = isDesktop ? 80.0 : 50.0;
          final double verticalSpacing = isDesktop ? 40.0 : 20.0;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // --- LOGO CONTAINER ---
                      Container(
                        width: logoSize,
                        height: logoSize,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(isDesktop ? 40 : 30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(isDesktop ? 30 : 20),
                        child: Image.asset(
                          'assets/images/venuematelogo3.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.account_balance,
                              size: iconSize,
                              color: const Color(0xFFF47C20),
                            );
                          },
                        ),
                      ),
                      
                      SizedBox(height: verticalSpacing),
                      
                      // --- TITLE ---
                      Text(
                        'VenueMate',
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: verticalSpacing / 2), // Half spacing
                      
                      // --- SUBTITLE ---
                      Text(
                        'Find Your Perfect Venue',
                        style: TextStyle(
                          fontSize: subtitleSize,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
