import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const double _kWebBreak = 900;

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch $urlString');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= _kWebBreak;
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'About Us',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isWide ? _buildWebLayout() : _buildMobileLayout(),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  WEB — two column layout
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left col ───────────────────────────────────────────────────
              SizedBox(
                width: 300,
                child: Column(
                  children: [
                    // Brand card
                    _webCard(
                      child: Column(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF47C20), Color(0xFFFFCC80)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFF47C20,
                                  ).withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.apartment_rounded,
                              size: 44,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'VenueMate',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Version 1.0.0',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF47C20).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Find Your Perfect Venue',
                              style: TextStyle(
                                color: Color(0xFFF47C20),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Contact card (Clickable)
                    _webCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Contact',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _contactRow(
                            Icons.email_outlined,
                            'support@venuemate.com',
                            'mailto:support@venuemate.com',
                          ),
                          const SizedBox(height: 12),
                          _contactRow(
                            Icons.language_outlined,
                            'www.venuemate.com',
                            'https://www.venuemate.com',
                          ),
                          const SizedBox(height: 12),
                          _contactRow(
                            Icons.location_on_outlined,
                            'Gujranwala, Pakistan',
                            'https://www.google.com/maps/search/?api=1&query=Gujranwala,Pakistan',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Social card (Clickable)
                    _webCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Follow Us',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _socialIcon(
                                Icons.facebook,
                                'Facebook',
                                'https://facebook.com/venuemate',
                              ),
                              _socialIcon(
                                Icons.camera_alt,
                                'Instagram',
                                'https://instagram.com/venuemate',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // ── Right col ──────────────────────────────────────────────────
              Expanded(
                child: Column(
                  children: [
                    // Mission card
                    _webCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFF47C20,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.flag_outlined,
                                  color: Color(0xFFF47C20),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Our Mission',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'VenueMate allows users to find and book the perfect wedding halls, marquees, and event spaces with ease.',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.7,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Our goal is to bridge the gap between venue owners and customers by providing a seamless, transparent, and efficient booking experience.',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stats row
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            '500+',
                            'Venues Listed',
                            Icons.apartment_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _statCard(
                            '10K+',
                            'Happy Customers',
                            Icons.people_outline,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _statCard(
                            '50+',
                            'Cities Covered',
                            Icons.location_city_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Why us card
                    _webCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFF47C20,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.star_outline,
                                  color: Color(0xFFF47C20),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Why Choose Us',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ...[
                            (
                              'Verified Venues',
                              'All venues go through a strict verification process.',
                              Icons.verified_outlined,
                            ),
                            (
                              'Instant Booking',
                              'Book your perfect venue in just a few taps.',
                              Icons.flash_on_outlined,
                            ),
                            (
                              'Secure Payments',
                              'Your transactions are safe and protected.',
                              Icons.lock_outline,
                            ),
                            (
                              '24/7 Support',
                              'Our support team is always here to help.',
                              Icons.headset_mic_outlined,
                            ),
                          ].map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3E0),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      item.$3,
                                      color: const Color(0xFFF47C20),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.$1,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.$2,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 4),
                          Center(
                            child: Text(
                              '© ${DateTime.now().year} VenueMate. All rights reserved.',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  MOBILE layout
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Logo
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF47C20), Color(0xFFFFCC80)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF47C20).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.apartment_rounded,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'VenueMate',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Version 1.0.0',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _statCard('500+', 'Venues', Icons.apartment_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard('10K+', 'Customers', Icons.people_outline),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard('50+', 'Cities', Icons.location_city_outlined),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Mission + Contact card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Our Mission',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'VenueMate allows users to find and book the perfect wedding halls, marquees, and event spaces with ease.\n\nOur goal is to bridge the gap between venue owners and customers by providing a seamless, transparent, and efficient booking experience.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Contact',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _contactRow(
                  Icons.email_outlined,
                  'support@venuemate.com',
                  'mailto:support@venuemate.com',
                ),
                const SizedBox(height: 10),
                _contactRow(
                  Icons.language_outlined,
                  'www.venuemate.com',
                  'https://www.venuemate.com',
                ),
                const SizedBox(height: 10),
                _contactRow(
                  Icons.location_on_outlined,
                  'Gujranwala, Pakistan',
                  'https://www.google.com/maps/search/?api=1&query=Gujranwala,Pakistan',
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _socialIcon(
                Icons.facebook,
                null,
                'https://facebook.com/venuemate',
              ),
              const SizedBox(width: 20),
              _socialIcon(
                Icons.camera_alt,
                null,
                'https://instagram.com/venuemate',
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            '© ${DateTime.now().year} VenueMate. All rights reserved.',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Shared helpers ──────────────────────────────────────────────────────────
  Widget _webCard({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      border: Border.all(color: Colors.grey.shade100),
    ),
    child: child,
  );

  Widget _statCard(String value, String label, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      border: Border.all(color: Colors.grey.shade100),
    ),
    child: Column(
      children: [
        Icon(icon, color: const Color(0xFFF47C20), size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF47C20),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _contactRow(IconData icon, String text, String url) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => _launchURL(url),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFFF47C20)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _socialIcon(IconData icon, String? label, String url) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => _launchURL(url),
      borderRadius: BorderRadius.circular(label != null ? 10 : 50),
      child: Container(
        padding: EdgeInsets.all(label != null ? 8 : 10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: label != null ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: label != null ? BorderRadius.circular(10) : null,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child:
            label != null
                ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: Colors.grey[700]),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
                : Icon(icon, size: 20, color: Colors.grey[700]),
      ),
    ),
  );
}
