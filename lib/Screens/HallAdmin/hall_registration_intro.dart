import 'package:flutter/material.dart';
import 'package:venuemate_system/Screens/HallAdmin/hall_registration.dart';
import 'package:venuemate_system/Utils/navigation.dart';
import 'package:venuemate_system/Widgets/gradient_button.dart';

class HallRegistrationIntroScreen extends StatelessWidget {
  const HallRegistrationIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: size.height,
            width: size.width,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Backgroundimage.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          Container(
            height: size.height,
            width: size.width,
            color: Colors.white.withOpacity(0.1),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/venuemate.png',
                            height: 65,
                            width: 65,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "VenueMate",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      Container(
                        width: double.infinity,

                        constraints: const BoxConstraints(maxWidth: 500),
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.symmetric(
                          vertical: 30,
                          horizontal: 24,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Welcome, Rehman!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 10),

                            Text(
                              "Let's get your venue listed.\nPlease complete the following\n5 steps:",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[700],
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 20),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStepText("Step 1: Basic Details"),
                                _buildStepText("Step 2: Hall Details"),
                                _buildStepText("Step 3: Uploads & Payouts"),
                                _buildStepText("Step 4: Menu & Services"),
                                _buildStepText("Step 5: Review & Submit"),
                              ],
                            ),

                            const SizedBox(height: 30),

                            GradientButton(
                              text: "Start Hall Registration",
                              onTap: () {
                                Navigation.push(
                                  context,
                                  HallRegistrationScreen(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }
}
