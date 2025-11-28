import 'package:flutter/material.dart';
import 'package:venuemate_system/Customers/SelectRoleScreen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  // The specific orange color from the design
  final Color _themeOrange = const Color(0xFFF47C20);
  final Color _textColor = const Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      ),
                      child: const Text('Next'),
                    ),
                  ),
                  // Add some bottom spacing if needed, though padding handles most of it
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
