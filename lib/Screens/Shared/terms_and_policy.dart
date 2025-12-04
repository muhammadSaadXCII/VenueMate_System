import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: _buildAppBar(context, "Privacy Policy"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Last Updated: November 2025",
                style: TextStyle(
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
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _SectionTitle(title: "1. Information Collection"),
                  _SectionText(
                    text:
                        "We collect information you provide directly to us, such as when you create or modify your account, request on-demand services, contact customer support, or otherwise communicate with us. This information may include: name, email, phone number, postal address, profile picture, payment method, items requested (for delivery services), delivery notes, and other information you choose to provide.",
                  ),
                  SizedBox(height: 20),
                  _SectionTitle(
                    title: "2. Information We Collect Through Your Use",
                  ),
                  _SectionText(
                    text:
                        "When you use our Services, we collect information about you in the following general categories: Location Information, Transaction Information, Usage and Preference Information, Device Information, Call and SMS Data.",
                  ),
                  SizedBox(height: 20),
                  _SectionTitle(title: "3. Use of Information"),
                  _SectionText(
                    text:
                        "We use the information we collect to: Provide, maintain, and improve our Services, including, for example, to facilitate payments, send receipts, provide products and services you request (and send related information), develop new features, provide customer support to Users and Drivers, develop safety features, authenticate users, and send product updates and administrative messages.",
                  ),
                  SizedBox(height: 20),
                  _SectionTitle(title: "4. Sharing of Information"),
                  _SectionText(
                    text:
                        "We may share the information we collect about you as described in this Statement or as described at the time of collection or sharing, including as follows: Through Our Services, We may share your information with: Drivers to enable them to provide the Services you request. For example, we share your name, photo (if you provide one), and pickup and/or drop-off locations with Drivers.",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: _buildAppBar(context, "Terms & Conditions"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Last Updated: November 2025",
                style: TextStyle(
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
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _SectionTitle(title: "1. Acceptance of Terms"),
                  _SectionText(
                    text:
                        "By accessing and using VenueMate, you accept and agree to be bound by the terms and provision of this agreement. In addition, when using these particular services, you shall be subject to any posted guidelines or rules applicable to such services.",
                  ),
                  SizedBox(height: 20),
                  _SectionTitle(title: "2. User Account"),
                  _SectionText(
                    text:
                        "To access certain features of the platform, you must register for an account. You agree to provide accurate, current, and complete information during the registration process and to update such information to keep it accurate, current, and complete.",
                  ),
                  SizedBox(height: 20),
                  _SectionTitle(title: "3. Booking & Payments"),
                  _SectionText(
                    text:
                        "VenueMate facilitates bookings between Hall Owners and Customers. VenueMate is not a party to any rental agreement or other transaction between users of the Site. We allow Hall Owners to set their own prices. Payment processing services for Hall Owners on VenueMate are provided by third-party payment processors.",
                  ),
                  SizedBox(height: 20),
                  _SectionTitle(title: "4. Cancellation Policy"),
                  _SectionText(
                    text:
                        "Cancellation policies are set by the Hall Owners. Customers are advised to review the specific cancellation policy of a venue before booking. VenueMate is not responsible for refunds outside of the platform's standard operating procedures.",
                  ),
                  SizedBox(height: 20),
                  _SectionTitle(title: "5. Prohibited Activities"),
                  _SectionText(
                    text:
                        "You may not access or use the Site for any purpose other than that for which we make the Site available. The Site may not be used in connection with any commercial endeavors except those that are specifically endorsed or approved by us.",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

AppBar _buildAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: true,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.black),
      onPressed: () => Navigator.pop(context),
    ),
    title: Text(
      title,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
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
  );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}

class _SectionText extends StatelessWidget {
  final String text;
  const _SectionText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: Colors.grey[600],
          fontWeight: FontWeight.w400,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }
}
