import 'package:flutter/material.dart';

const double _kLegalWebBreak = 900;

// ══════════════════════════════════════════════════════════════════════════════
//  PRIVACY POLICY
// ══════════════════════════════════════════════════════════════════════════════
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = [
    _LegalSection(
      title: '1. Information Collection',
      body:
          'We collect information you provide directly to us, such as when you create or modify your account, request on-demand services, contact customer support, or otherwise communicate with us. This information may include: name, email, phone number, postal address, profile picture, payment method, items requested (for delivery services), delivery notes, and other information you choose to provide.',
    ),
    _LegalSection(
      title: '2. Information We Collect Through Your Use',
      body:
          'When you use our Services, we collect information about you in the following general categories: Location Information, Transaction Information, Usage and Preference Information, Device Information, Call and SMS Data.',
    ),
    _LegalSection(
      title: '3. Use of Information',
      body:
          'We use the information we collect to: Provide, maintain, and improve our Services, including, for example, to facilitate payments, send receipts, provide products and services you request (and send related information), develop new features, provide customer support to Users and Drivers, develop safety features, authenticate users, and send product updates and administrative messages.',
    ),
    _LegalSection(
      title: '4. Sharing of Information',
      body:
          'We may share the information we collect about you as described in this Statement or as described at the time of collection or sharing, including as follows: Through Our Services, We may share your information with: Drivers to enable them to provide the Services you request. For example, we share your name, photo (if you provide one), and pickup and/or drop-off locations with Drivers.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _LegalScreen(
      title: 'Privacy Policy',
      lastUpdated: 'November 2025',
      sections: _sections,
      icon: Icons.privacy_tip_outlined,
      accentColor: Colors.blue.shade700,
      accentBg: Colors.blue.shade50,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  TERMS & CONDITIONS
// ══════════════════════════════════════════════════════════════════════════════
class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  static const _sections = [
    _LegalSection(
      title: '1. Acceptance of Terms',
      body:
          'By accessing and using VenueMate, you accept and agree to be bound by the terms and provision of this agreement. In addition, when using these particular services, you shall be subject to any posted guidelines or rules applicable to such services.',
    ),
    _LegalSection(
      title: '2. User Account',
      body:
          'To access certain features of the platform, you must register for an account. You agree to provide accurate, current, and complete information during the registration process and to update such information to keep it accurate, current, and complete.',
    ),
    _LegalSection(
      title: '3. Booking & Payments',
      body:
          'VenueMate facilitates bookings between Hall Owners and Customers. VenueMate is not a party to any rental agreement or other transaction between users of the Site. We allow Hall Owners to set their own prices. Payment processing services for Hall Owners on VenueMate are provided by third-party payment processors.',
    ),
    _LegalSection(
      title: '4. Cancellation Policy',
      body:
          'Cancellation policies are set by the Hall Owners. Customers are advised to review the specific cancellation policy of a venue before booking. VenueMate is not responsible for refunds outside of the platform\'s standard operating procedures.',
    ),
    _LegalSection(
      title: '5. Prohibited Activities',
      body:
          'You may not access or use the Site for any purpose other than that for which we make the Site available. The Site may not be used in connection with any commercial endeavors except those that are specifically endorsed or approved by us.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _LegalScreen(
      title: 'Terms & Conditions',
      lastUpdated: 'November 2025',
      sections: _sections,
      icon: Icons.description_outlined,
      accentColor: const Color(0xFFF47C20),
      accentBg: const Color(0xFFFFF3E0),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SHARED LEGAL SCREEN  (handles both Privacy + Terms)
// ══════════════════════════════════════════════════════════════════════════════
class _LegalScreen extends StatefulWidget {
  final String title;
  final String lastUpdated;
  final List<_LegalSection> sections;
  final IconData icon;
  final Color accentColor;
  final Color accentBg;

  const _LegalScreen({
    required this.title,
    required this.lastUpdated,
    required this.sections,
    required this.icon,
    required this.accentColor,
    required this.accentBg,
  });

  @override
  State<_LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<_LegalScreen> {
  int _activeSection = 0;
  final ScrollController _scrollCtrl = ScrollController();
  final List<GlobalKey> _sectionKeys = [];

  @override
  void initState() {
    super.initState();
    _sectionKeys.addAll(
      List.generate(widget.sections.length, (_) => GlobalKey()),
    );
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    for (int i = 0; i < _sectionKeys.length; i++) {
      final ctx = _sectionKeys[i].currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final pos = box.localToGlobal(Offset.zero);
      if (pos.dy >= 0 && pos.dy < MediaQuery.of(context).size.height * 0.5) {
        if (_activeSection != i) setState(() => _activeSection = i);
        break;
      }
    }
  }

  void _scrollToSection(int index) {
    final ctx = _sectionKeys[index].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    setState(() => _activeSection = index);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= _kLegalWebBreak;
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
        title: Text(
          widget.title,
          style: const TextStyle(
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
  //  WEB — left sidebar (section index) + scrollable content right
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left sidebar ───────────────────────────────────────────────
              SizedBox(
                width: 260,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: widget.accentBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: widget.accentColor.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: widget.accentColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              widget.icon,
                              color: widget.accentColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: widget.accentColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Last updated: ${widget.lastUpdated}',
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.accentColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section index
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Contents',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...widget.sections.asMap().entries.map((e) {
                            final isActive = e.key == _activeSection;
                            return InkWell(
                              onTap: () => _scrollToSection(e.key),
                              borderRadius: BorderRadius.circular(8),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isActive
                                          ? widget.accentBg
                                          : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      isActive
                                          ? Border.all(
                                            color: widget.accentColor
                                                .withOpacity(0.3),
                                          )
                                          : null,
                                ),
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      width: 3,
                                      height: isActive ? 20 : 0,
                                      decoration: BoxDecoration(
                                        color: widget.accentColor,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    SizedBox(width: isActive ? 8 : 0),
                                    Expanded(
                                      child: Text(
                                        e.value.title,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight:
                                              isActive
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                          color:
                                              isActive
                                                  ? widget.accentColor
                                                  : Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // ── Right content ──────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollCtrl,
                  child: Column(
                    children: [
                      ...widget.sections.asMap().entries.map(
                        (e) => Container(
                          key: _sectionKeys[e.key],
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: widget.accentColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      e.value.title,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                e.value.body,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.7,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.justify,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Footer
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: widget.accentBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: widget.accentColor.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: widget.accentColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'By using VenueMate, you agree to these terms. For questions, contact support@venuemate.com',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: widget.accentColor.withOpacity(0.85),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  MOBILE (unchanged structure)
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Last Updated: ${widget.lastUpdated}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  widget.sections
                      .expand(
                        (s) => [
                          Text(
                            s.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              s.body,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      )
                      .toList(),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ── Data class ─────────────────────────────────────────────────────────────────
class _LegalSection {
  final String title;
  final String body;
  const _LegalSection({required this.title, required this.body});
}
