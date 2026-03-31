import 'package:flutter/material.dart';
import 'package:venuemate_system/Utils/app_navigation.dart';
import 'package:venuemate_system/Widgets/common_button.dart';
import 'package:venuemate_system/Services/auth_service.dart';
import 'package:venuemate_system/Services/hall_service.dart';
import 'package:venuemate_system/Screens/HallAdmin/hall_registration.dart';
import 'package:venuemate_system/Screens/HallAdmin/pending_review.dart';
import 'package:venuemate_system/Screens/HallAdmin/hall_admin_root.dart';

/// Smart entry point for every Venue Owner login.
///
/// Routing logic (checked on every load):
///   No hall in Firestore      → show fresh intro ("Start Hall Registration")
///   hall.status = 'approved'  → pushReplacement → HallAdminRootLayout
///   hall.status = 'pending'   → pushReplacement → PendingReviewScreen
///   hall.status = 'rejected'  → pushReplacement → PendingReviewScreen
///                                (PendingReviewScreen handles the rejected UI
///                                 and the "Start Over" delete flow)
///
/// After "Start Over" deletes the hall, the owner is navigated back here.
/// At that point Firestore has no hall doc → this screen shows the clean intro.
class HallRegistrationIntroScreen extends StatefulWidget {
  const HallRegistrationIntroScreen({super.key});

  @override
  State<HallRegistrationIntroScreen> createState() =>
      _HallRegistrationIntroScreenState();
}

class _HallRegistrationIntroScreenState
    extends State<HallRegistrationIntroScreen> {
  bool _checking = true;
  String? _ownerName; // pre-filled from Firestore user profile

  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final uid = AuthService.currentUid;
    if (uid == null) {
      setState(() => _checking = false);
      return;
    }

    // Load user name for the welcome message
    final user = await AuthService.getCurrentUser();
    final hall = await HallService.getHallByOwnerId(uid);

    if (!mounted) return;

    // ── No hall at all → show intro ──────────────────────────────────────
    if (hall == null) {
      setState(() {
        _ownerName = user?.name.split(' ').first ?? 'Owner';
        _checking = false;
      });
      return;
    }

    // ── Approved → dashboard ──────────────────────────────────────────────
    if (hall.isApproved) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HallAdminRootLayout()),
      );
      return;
    }

    // ── Pending or Rejected → PendingReviewScreen handles both ───────────
    // PendingReviewScreen streams the hall status and shows the correct UI:
    //   - pending  → spinner + "Refresh Status"
    //   - rejected → rejection card + "Start Over" (which deletes and comes back here)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PendingReviewScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Spinner while checking Firestore
    if (_checking) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFF47C20)),
        ),
      );
    }

    // ── Clean intro (no hall registered yet, or fresh after deletion) ─────
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/BGimage (1).png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.1)),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    children: [
                      Image.asset(
                        'assets/images/venuemate.png',
                        height: 65,
                        width: 65,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.business,
                          size: 65,
                          color: Color(0xFFF47C20),
                        ),
                      ),
                      const Text(
                        'VenueMate',
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

                  // Main card
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 500),
                    padding: const EdgeInsets.symmetric(
                      vertical: 40,
                      horizontal: 30,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.88),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Welcome message
                        Text(
                          _ownerName != null
                              ? 'Welcome, $_ownerName!'
                              : 'Welcome, Venue Owner!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Let's get your venue listed.\n"
                          "Please complete the following 5 steps:",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Step list
                        Flexible(
                          fit: FlexFit.loose,
                          child: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _step('1. Basic Details'),
                                _step('2. Hall Details'),
                                _step('3. Uploads & Payouts'),
                                _step('4. Menu & Services'),
                                _step('5. Review & Submit'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        SizedBox(
                          width: double.infinity,
                          child: CommonButton(
                            text: 'Start Hall Registration',
                            onTap: () => AppNavigation.push(
                              context,
                              const HallRegistrationScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: Color(0xFFF47C20),
          size: 20,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    ),
  );
}
