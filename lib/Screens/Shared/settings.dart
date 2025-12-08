import 'package:flutter/material.dart';
import 'package:venuemate_system/Utils/app_navigation.dart';
import 'package:venuemate_system/Screens/Shared/about_us.dart';
import 'package:venuemate_system/Screens/Shared/change_password.dart';
import 'package:venuemate_system/Screens/Shared/terms_and_policy.dart';
import 'package:venuemate_system/Screens/Shared/hep_and_support.dart.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _isDarkMode = false;
  final Color _activeThemeColor = const Color(0xFFF47C20);

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          "Settings",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 40 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("Account"),
                const SizedBox(height: 10),
                Container(
                  decoration: _cardDecoration(),
                  child: _SettingsTile(
                    icon: Icons.lock_outline,
                    title: "Change Password",
                    onTap: () {
                      AppNavigation.push(context, ChangePasswordScreen());
                    },
                  ),
                ),

                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.palette_outlined,
                              color: Color(0xFFF47C20),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Theme Mode",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isDarkMode
                                    ? "Dark theme is active"
                                    : "Light theme is active",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _buildThemeButton(
                            targetModeIsDark: false,
                            icon: Icons.light_mode_outlined,
                            text: "Light",
                          ),
                          const SizedBox(width: 16),
                          _buildThemeButton(
                            targetModeIsDark: true,
                            icon: Icons.dark_mode_outlined,
                            text: "Dark",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                _buildSectionTitle("Notifications"),
                const SizedBox(height: 10),
                Container(
                  decoration: _cardDecoration(),
                  child: Column(
                    children: [
                      _SwitchTile(
                        title: "Push Notifications",
                        value: _pushNotifications,
                        onChanged: (val) =>
                            setState(() => _pushNotifications = val),
                        icon: Icons.notifications_outlined,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                _buildSectionTitle("Support"),
                const SizedBox(height: 10),
                Container(
                  decoration: _cardDecoration(),
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.help_outline,
                        title: "Help Center",
                        onTap: () {
                          AppNavigation.push(context, HelpSupportScreen());
                        },
                      ),
                      _divider(),
                      _SettingsTile(
                        icon: Icons.info_outline,
                        title: "About Us",
                        onTap: () {
                          AppNavigation.push(context, AboutUsScreen());
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                _buildSectionTitle("Legal"),
                const SizedBox(height: 10),
                Container(
                  decoration: _cardDecoration(),
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.privacy_tip_outlined,
                        title: "Privacy Policy",
                        onTap: () {
                          AppNavigation.push(context, PrivacyPolicyScreen());
                        },
                      ),
                      _divider(),
                      _SettingsTile(
                        icon: Icons.description_outlined,
                        title: "Terms & Conditions",
                        onTap: () {
                          AppNavigation.push(context, TermsConditionsScreen());
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildThemeButton({
    required bool targetModeIsDark,
    required IconData icon,
    required String text,
  }) {
    final bool isActive = _isDarkMode == targetModeIsDark;
    final Color activeColor = _activeThemeColor;
    final Color inactiveColor = Colors.grey.shade600;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isDarkMode = targetModeIsDark;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: isActive ? activeColor : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: activeColor.withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isActive ? activeColor : inactiveColor,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                text,
                style: TextStyle(
                  color: isActive ? activeColor : inactiveColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
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
      border: Border.all(color: Colors.grey.shade200),
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, color: Color(0xFFEEEEEE)),
    );
  }
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
  Widget build(BuildContext context) {
    return ListTile(
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
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;

  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      activeColor: const Color(0xFFF47C20),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFFF47C20), size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}
