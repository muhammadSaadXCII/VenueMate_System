import 'package:flutter/material.dart';
<<<<<<< HEAD:lib/Customers/SplashScreen.dart
import 'dart:async';

import 'package:venuemate_system/Customers/OnBoardingScreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
=======
import 'package:venuemate_system/Screens/Customers/SelectRoleScreen.dart';
>>>>>>> 16b11b4996d776a6ad2f074cd257560bcd7534eb:lib/Screens/Customers/SplashScreen.dart

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // Scale animation
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    // Start animation
    _controller.forward();

    // Navigate to next screen after 3 seconds
    Timer(const Duration(seconds: 6), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD:lib/Customers/SplashScreen.dart
      backgroundColor: const Color(0xFFF47C20),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Icon/Logo placeholder
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
=======
      // Use a Stack to put the image behind the content
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background Image Layer (Clear, no blur overlay)
          Image.asset('assets/images/Backgroundimage.png', fit: BoxFit.cover),

          // 2. Main Content Layer
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- Top Content Section ---
                  // Add some top spacing
                  const SizedBox(height: 40),

                  // Logo from Asset
                  // TODO: 1. Add your logo file (e.g., logo.png) to an 'assets/images' folder in your project.
                  // TODO: 2. Register the asset in your pubspec.yaml file.
                  Image.asset(
                    'assets/images/venuemate.png', // Replace with your actual path
                    width: 80,
                    height: 80,
                    // If your logo is black and needs to be orange, uncomment line below:
                    // color: _themeOrange,
                    errorBuilder: (context, error, stackTrace) {
                      // Placeholder in case asset is not found yet
                      return Icon(
                        Icons.image_not_supported,
                        size: 80,
                        color: _themeOrange,
                      );
                    },
                  ),
                  const SizedBox(height: 3),

                  // App Name
                  Text(
                    'Venue Mate',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _textColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 50),

                  // Tagline
                  Text(
                    'Find_Book.\nCelebrate.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: _textColor,
                      height: 1.2,
                    ),
                  ),

                  // --- Spacer ---
                  // This pushes everything above it to the top, and everything below it to the bottom.
                  const Spacer(),

                  // --- Bottom Button Section ---
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SelectRoleScreen(),
                          ),
                        );
                        debugPrint("Next button pressed");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _themeOrange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
>>>>>>> 16b11b4996d776a6ad2f074cd257560bcd7534eb:lib/Screens/Customers/SplashScreen.dart
                      ),
                    ],
                  ),
                  child: Image.asset('assets/images/venuemate.png'),
                  //const Icon(
                  //   Icons.location_city,
                  //   size: 60,
                  //   color: Color(0xFFF47C20),
                  // ),
                ),
                const SizedBox(height: 30),
                // App Name
                const Text(
                  'VenueMate',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                // Tagline
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
