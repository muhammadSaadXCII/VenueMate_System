import 'package:flutter/material.dart';

class ManageUserDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const ManageUserDetailsScreen({super.key, required this.user});

  @override
  State<ManageUserDetailsScreen> createState() =>
      _ManageUserDetailsScreenState();
}

class _ManageUserDetailsScreenState extends State<ManageUserDetailsScreen> {
  late bool _isUserActive;

  @override
  void initState() {
    super.initState();

    _isUserActive =
        widget.user['status'] == 'Active' || widget.user['status'] == null;
  }

  void _toggleUserStatus() {
    setState(() {
      _isUserActive = !_isUserActive;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Manage User",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 900) {
            return _buildDesktopLayout(context);
          } else {
            return _buildMobileLayout(context);
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _ProfileCard(
                        isDesktop: true,
                        user: widget.user,
                        isActive: _isUserActive,
                      ),
                      const SizedBox(height: 24),
                      _ContactSection(isDesktop: true, user: widget.user),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                flex: 6,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _StatsCard(isDesktop: true),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: _cardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Account Actions",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isUserActive
                                  ? "Deactivating this account will prevent the user from logging in or making new bookings. Existing bookings will remain active."
                                  : "Activating this account will restore the user's login access and ability to make new bookings.",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: _ActionButton(
                                text: _isUserActive
                                    ? "Deactivate Account"
                                    : "Activate Account",
                                icon: _isUserActive
                                    ? Icons.block
                                    : Icons.check_circle_outline,
                                isDesktop: true,

                                isDeactivateButton: _isUserActive,
                                onTap: _toggleUserStatus,
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileCard(
                isDesktop: false,
                user: widget.user,
                isActive: _isUserActive,
              ),
              const SizedBox(height: 24),
              _ContactSection(isDesktop: false, user: widget.user),
              const SizedBox(height: 24),
              _StatsCard(isDesktop: false),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: _ActionButton(
              text: _isUserActive ? "Deactivate Account" : "Activate Account",
              icon: _isUserActive ? Icons.block : Icons.check_circle_outline,
              isDesktop: false,

              isDeactivateButton: _isUserActive,
              onTap: _toggleUserStatus,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool isDesktop;

  final bool isDeactivateButton;
  final VoidCallback onTap;

  const _ActionButton({
    required this.text,
    required this.icon,
    required this.isDesktop,
    required this.isDeactivateButton,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color buttonColor = isDeactivateButton
        ? Color(0xFFD92D20)
        : Color(0xFFF47C20);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: buttonColor.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final bool isDesktop;
  final Map<String, dynamic> user;
  final bool isActive;

  const _ProfileCard({
    required this.isDesktop,
    required this.user,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final String statusText = isActive ? "● Active" : "● Deactivated";
    final Color statusColor = isActive ? Color(0xFFF47C20) : Colors.redAccent;

    return Center(
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 32 : 24),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            Container(
              width: isDesktop ? 120 : 100,
              height: isDesktop ? 120 : 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: statusColor, width: 3),
              ),
              child: ClipOval(
                child: Image.network(
                  "https://img.freepik.com/free-psd/3d-illustration-person-with-sunglasses_23-2149436188.jpg",
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.person, size: 50, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Zulhaq Hussain",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Role: Customer",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.2)),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactSection extends StatelessWidget {
  final bool isDesktop;
  final Map<String, dynamic> user;

  const _ContactSection({required this.isDesktop, required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: "Contact Information"),
        _ContactTile(
          icon: Icons.phone_in_talk_outlined,
          label: "Phone Number",
          value: "+92 3XX XXXXXXX",
          actionIcon: Icons.call,
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _ContactTile(
          icon: Icons.email_outlined,
          label: "Email Address",
          value: "zulhaq.hussain@email.com",
          actionIcon: Icons.email,
          onTap: () {},
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  final bool isDesktop;

  const _StatsCard({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: "Booking Performance"),
        Container(
          padding: EdgeInsets.all(isDesktop ? 32 : 24),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Bookings",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    "3",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              const Divider(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatItem(
                    count: "2",
                    label: "Completed",
                    color: Colors.green,
                    icon: Icons.check_circle_outline,
                  ),
                  _StatItem(
                    count: "1",
                    label: "Upcoming",
                    color: const Color(0xFFF47C20),
                    icon: Icons.calendar_today,
                  ),
                  _StatItem(
                    count: "0",
                    label: "Cancelled",
                    color: Colors.redAccent,
                    icon: Icons.cancel_outlined,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final IconData actionIcon;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.actionIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.black87, size: 22),
        ),
        title: Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        trailing: Icon(actionIcon, color: const Color(0xFFF47C20), size: 20),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String count;
  final String label;
  final Color color;
  final IconData icon;

  const _StatItem({
    required this.count,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.grey.shade200),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
