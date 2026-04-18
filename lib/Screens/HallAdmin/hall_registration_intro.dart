import 'package:flutter/material.dart';
import 'package:venuemate_system/Utils/app_navigation.dart';
import 'package:venuemate_system/Widgets/common_button.dart';
import 'package:venuemate_system/Services/auth_service.dart';
import 'package:venuemate_system/Services/hall_service.dart';
import 'package:venuemate_system/Screens/HallAdmin/hall_registration.dart';
import 'package:venuemate_system/Screens/HallAdmin/pending_review.dart';
import 'package:venuemate_system/Screens/HallAdmin/hall_admin_root.dart';

const double _kWebBreak = 900;

class HallRegistrationIntroScreen extends StatefulWidget {
  const HallRegistrationIntroScreen({super.key});

  @override
  State<HallRegistrationIntroScreen> createState() =>
      _HallRegistrationIntroScreenState();
}

class _HallRegistrationIntroScreenState
    extends State<HallRegistrationIntroScreen> {
  bool _checking = true;
  String? _ownerName;

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
    final user = await AuthService.getCurrentUser();
    final hall = await HallService.getHallByOwnerId(uid);
    if (!mounted) return;
    if (hall == null) {
      setState(() {
        _ownerName = user?.name.split(' ').first ?? 'Owner';
        _checking = false;
      });
      return;
    }
    if (hall.isApproved) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HallAdminRootLayout()),
      );
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PendingReviewScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFF47C20)),
        ),
      );
    }
    final isWide = MediaQuery.of(context).size.width >= _kWebBreak;
    return isWide ? _buildWebLayout() : _buildMobileLayout();
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      body: Stack(
        children: [
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
                  _logoRow(),
                  const SizedBox(height: 40),
                  _registrationCard(maxWidth: 500),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Left branding panel
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF47C20), Color(0xFFFFD166)],
                ),
                image: DecorationImage(
                  image: AssetImage('assets/images/BGimage (1).png'),
                  fit: BoxFit.cover,
                  // Increased opacity to 0.15 so it's actually visible
                  opacity: 0.55,
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/venuemate.png',
                            height: 52,
                            width: 52,
                            errorBuilder:
                                (_, __, ___) => const Icon(
                                  Icons.business,
                                  size: 52,
                                  color: Colors.white,
                                ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'VenueMate',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      const Text(
                        'List Your Venue On\nVenueMate',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Join hundreds of venue owners already earning\nwith VenueMate.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.88),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 40),
                      ...[
                        'Reach thousands of event planners',
                        'Manage bookings with ease',
                        'Secure and transparent payouts',
                        'Full control over your listing',
                      ].map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                t,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white.withOpacity(0.92),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Right card panel
          Expanded(
            flex: 4,
            child: Container(
              color: const Color(0xFFF8F9FA),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 32,
                  ),
                  child: _registrationCard(maxWidth: 480),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoRow() => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 10,
    children: [
      Image.asset(
        'assets/images/venuemate.png',
        height: 65,
        width: 65,
        errorBuilder:
            (_, __, ___) =>
                const Icon(Icons.business, size: 65, color: Color(0xFFF47C20)),
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
  );

  Widget _registrationCard({required double maxWidth}) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
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
            "Let's get your venue listed.\nPlease complete the following 5 steps:",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[800],
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 30),
          Container(
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
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: CommonButton(
              text: 'Start Hall Registration',
              onTap:
                  () => AppNavigation.push(
                    context,
                    const HallRegistrationScreen(),
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
