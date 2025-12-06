import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:venuemate_system/Screens/HallAdmin/hall_admin_home.dart';

// Screens Imports
import 'OnBoardingScreen.dart'; 
import 'HomePageVenueScreen.dart'; // Admin Home
// import 'HomeScreen.dart'; // Customer Home (Ensure this file exists)

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

    // 1. Initialize Animation Controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // 2. Define Fade Animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // 3. Define Scale Animation
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    // 4. Start the animation
    _controller.forward();

    // 5. Check Login Status instead of simple Timer
    _checkLoginStatus();
  }

  // --- AUTO LOGIN LOGIC ---
  void _checkLoginStatus() async {
    // Wait for animations to complete (at least 3-4 seconds)
    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) return;

    // Get Current User
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User is Logged In -> Check Role from Firestore
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          // Get Data safely
          Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
          String role = data?['role'] ?? 'customer'; // Default to customer

          if (!mounted) return;

          // Navigate based on Role
          if (role == 'venue_owner') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HallAdminHomeScreen()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        } else {
          // User exists in Auth but not DB (Edge case) -> Go to Onboarding
          _navigateToOnboarding();
        }
      } catch (e) {
        // If internet error or other issue -> Go to Onboarding (or show error)
        print("Error fetching user data: $e");
        _navigateToOnboarding();
      }
    } else {
      // User Not Logged In -> Go to Onboarding
      _navigateToOnboarding();
    }
  }

  void _navigateToOnboarding() {
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
      // Matches the orange color from your screenshot
      backgroundColor: const Color(0xFFF47C20),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- Logo Section ---
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
                  // Using padding to make the icon smaller inside the white box
                  padding: const EdgeInsets.all(20),
                  child: Image.asset(
                    'assets/images/venuemate.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback icon if image is missing
                      return const Icon(
                        Icons.account_balance,
                        size: 50,
                        color: Color(0xFFF47C20),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 20),

                // --- App Name ---
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

                // --- Tagline ---
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