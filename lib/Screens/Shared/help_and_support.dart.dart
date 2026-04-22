import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const double _kHelpWebBreak = 900;

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});
  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _allFaqs = [
    {
      'question': 'How do I change my password?',
      'answer':
          'Go to Settings > Account > Change Password. You will need to enter your old password to set a new one.',
    },
    {
      'question': 'How do refunds work?',
      'answer':
          'Refunds are processed according to the cancellation policy set by the Hall Admin. Usually, it takes 5-7 business days.',
    },
    {
      'question': 'How do I contact support?',
      'answer':
          'You can use the buttons below to Call or Email our support team directly.',
    },
    {
      'question': 'How do I cancel a booking?',
      'answer':
          'Go to My Bookings, select the booking you want to cancel, and tap Cancel Booking. Please review the cancellation policy before proceeding.',
    },
    {
      'question': 'How are venues verified?',
      'answer':
          'All venues go through a strict verification process by our system administrators. This includes document verification, location confirmation, and a quality check.',
    },
  ];

  List<Map<String, String>> _foundFaqs = [];

  @override
  void initState() {
    super.initState();
    _foundFaqs = _allFaqs;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _runFilter(String keyword) {
    setState(() {
      _foundFaqs =
          keyword.isEmpty
              ? _allFaqs
              : _allFaqs
                  .where(
                    (faq) => faq['question']!.toLowerCase().contains(
                      keyword.toLowerCase(),
                    ),
                  )
                  .toList();
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= _kHelpWebBreak;
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
          'Help & Support',
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
  //  WEB — two column: FAQs left (wider), search+contact right
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
              // ── Left: FAQ list ─────────────────────────────────────────────
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF47C20), Color(0xFFFFD166)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'How can we help you?',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Find answers to common questions below',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.88),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.support_agent,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Frequently Asked Questions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_foundFaqs.length} results',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _foundFaqs.isNotEmpty
                        ? Column(
                          children:
                              _foundFaqs
                                  .map(
                                    (faq) => _FaqTile(
                                      question: faq['question']!,
                                      answer: faq['answer']!,
                                    ),
                                  )
                                  .toList(),
                        )
                        : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 48,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No results found',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // ── Right: Search + Contact ────────────────────────────────────
              SizedBox(
                width: 300,
                child: Column(
                  children: [
                    // Search card
                    _webCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Search Questions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: _runFilter,
                              decoration: InputDecoration(
                                hintText: 'Search for issues...',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Colors.grey,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Contact card
                    _webCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.headset_mic_outlined,
                                  color: Color(0xFFF47C20),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Contact Us',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _webContactButton(
                            icon: Icons.call_outlined,
                            label: 'Call Support',
                            subtitle: '+92 300 1234567',
                            color: Colors.green.shade50,
                            iconColor: Colors.green.shade700,
                            onTap: () => _makePhoneCall('+923001234567'),
                          ),
                          const SizedBox(height: 12),
                          _webContactButton(
                            icon: Icons.email_outlined,
                            label: 'Email Support',
                            subtitle: 'support@venuemate.com',
                            color: const Color(0xFFFFF3E0),
                            iconColor: const Color(0xFFF47C20),
                            onTap: () => _sendEmail('support@venuemate.com'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick tips card
                    _webCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.lightbulb_outline,
                                  color: Color(0xFFF47C20),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Quick Tips',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...[
                            'Keep your booking ID handy when contacting support.',
                            'Check your email for booking confirmations.',
                            'Update your profile for faster bookings.',
                          ].map(
                            (tip) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 6),
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF47C20),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      tip,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
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
  //  MOBILE (unchanged structure)
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How can we help you?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _runFilter,
              decoration: InputDecoration(
                hintText: 'Search for issues...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          _foundFaqs.isNotEmpty
              ? Column(
                children:
                    _foundFaqs
                        .map(
                          (faq) => _FaqTile(
                            question: faq['question']!,
                            answer: faq['answer']!,
                          ),
                        )
                        .toList(),
              )
              : Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'No results found',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          const SizedBox(height: 30),
          const Text(
            'Contact Us',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          Container(
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
            ),
            child: Column(
              children: [
                _ContactTile(
                  icon: Icons.headset_mic,
                  title: 'Customer Service',
                  subtitle: '+92 300 1234567',
                  onTap: () => _makePhoneCall('+923001234567'),
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                _ContactTile(
                  icon: Icons.email_outlined,
                  title: 'Email Support',
                  subtitle: 'support@venuemate.com',
                  onTap: () => _sendEmail('support@venuemate.com'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Shared helpers ──────────────────────────────────────────────────────────
  Widget _webCard({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
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

  Widget _webContactButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: iconColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: iconColor.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── FAQ Tile (shared) ──────────────────────────────────────────────────────────
class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;
  const _FaqTile({required this.question, required this.answer});
  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isExpanded ? const Color(0xFFF47C20) : Colors.grey.shade200,
          width: _isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                _isExpanded
                    ? const Color(0xFFF47C20).withOpacity(0.15)
                    : Colors.grey.withOpacity(0.05),
            blurRadius: _isExpanded ? 15 : 5,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (v) => setState(() => _isExpanded = v),
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  _isExpanded
                      ? const Color(0xFFF47C20)
                      : const Color(0xFFFFF3E0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isExpanded ? Icons.remove : Icons.add,
              color: _isExpanded ? Colors.white : const Color(0xFFF47C20),
              size: 20,
            ),
          ),
          title: Text(
            widget.question,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _isExpanded ? const Color(0xFFF47C20) : Colors.black87,
            ),
          ),
          trailing: const SizedBox.shrink(),
          children: [
            Text(
              widget.answer,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Contact Tile (mobile) ──────────────────────────────────────────────────────
class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _ContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: const Color(0xFFF47C20), size: 22),
    ),
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
    ),
    subtitle: Text(
      subtitle,
      style: const TextStyle(fontSize: 12, color: Colors.grey),
    ),
    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
  );
}
