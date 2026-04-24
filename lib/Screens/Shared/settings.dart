import 'package:flutter/material.dart';
import 'package:venuemate_system/Utils/app_navigation.dart';
import 'package:venuemate_system/Screens/Shared/about_us.dart';
import 'package:venuemate_system/Screens/Shared/change_password.dart';
import 'package:venuemate_system/Screens/Shared/terms_and_policy.dart';
import 'package:venuemate_system/Screens/Shared/help_and_support.dart.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: isWide ? _buildWebLayout() : _buildMobileLayout(),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  WEB — two columns: Account left, Notifications+Support+Legal right
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Account'),
              const SizedBox(height: 10),
              Container(
                decoration: _cardDecoration(),
                child: _SettingsTile(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap:
                      () => AppNavigation.push(context, ChangePasswordScreen()),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Support'),
              const SizedBox(height: 10),
              Container(
                decoration: _cardDecoration(),
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.help_outline,
                      title: 'Help Center',
                      onTap:
                          () =>
                              AppNavigation.push(context, HelpSupportScreen()),
                    ),
                    _divider(),
                    _SettingsTile(
                      icon: Icons.info_outline,
                      title: 'About Us',
                      onTap: () => AppNavigation.push(context, AboutUsScreen()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Legal'),
              const SizedBox(height: 10),
              Container(
                decoration: _cardDecoration(),
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      onTap:
                          () => AppNavigation.push(
                            context,
                            PrivacyPolicyScreen(),
                          ),
                    ),
                    _divider(),
                    _SettingsTile(
                      icon: Icons.description_outlined,
                      title: 'Terms & Conditions',
                      onTap:
                          () => AppNavigation.push(
                            context,
                            TermsConditionsScreen(),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  MOBILE — single column
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Account'),
        const SizedBox(height: 10),
        Container(
          decoration: _cardDecoration(),
          child: _SettingsTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () => AppNavigation.push(context, ChangePasswordScreen()),
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Support'),
        const SizedBox(height: 10),
        Container(
          decoration: _cardDecoration(),
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.help_outline,
                title: 'Help Center',
                onTap: () => AppNavigation.push(context, HelpSupportScreen()),
              ),
              _divider(),
              _SettingsTile(
                icon: Icons.info_outline,
                title: 'About Us',
                onTap: () => AppNavigation.push(context, AboutUsScreen()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Legal'),
        const SizedBox(height: 10),
        Container(
          decoration: _cardDecoration(),
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () => AppNavigation.push(context, PrivacyPolicyScreen()),
              ),
              _divider(),
              _SettingsTile(
                icon: Icons.description_outlined,
                title: 'Terms & Conditions',
                onTap:
                    () => AppNavigation.push(context, TermsConditionsScreen()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSectionTitle(String title) => Text(
    title,
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.grey[600],
    ),
  );

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
    border: Border.all(color: Colors.grey.shade200),
  );

  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 20),
    child: Divider(height: 1, color: Color(0xFFEEEEEE)),
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: const Color(0xFFF47C20), size: 22),
    ),
    title: Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
  );
}
