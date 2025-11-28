import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:venuemate_system/Shared/user_notifications.dart';
import 'package:venuemate_system/SystemAdmin/manage_all_halls.dart';
import 'package:venuemate_system/SystemAdmin/manage_all_users.dart';
import 'package:venuemate_system/SystemAdmin/handle_complaints.dart';
import 'package:venuemate_system/SystemAdmin/pending_registrations.dart';
import 'package:venuemate_system/Utils/navigation.dart';

class SystemAdminHome extends StatelessWidget {
  const SystemAdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _AdminHeader(),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigation.push(context, PendingRegistrationsScreen());
                    },
                    child: const ActionCard(
                      title: "4 Pending Hall Registrations",
                      subtitle: "Review new submissions for approval",
                      icon: Icons.description_outlined,
                      iconColor: Colors.amber,
                      borderColor: Colors.amber,
                      secondaryIcon: Icons.access_time_filled,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      Navigation.push(context, ComplaintsScreen());
                    },
                    child: const ActionCard(
                      title: "2 New Complaints",
                      subtitle: "Resolve user-reported issues",
                      icon: Icons.assignment_late_outlined,
                      iconColor: Colors.redAccent,
                      borderColor: Colors.redAccent,
                      secondaryIcon: Icons.cancel,
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "Platform Statistics",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              count: "150",
                              label: "Total Halls",
                              icon: Icons.account_balance_outlined,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: StatCard(
                              count: "500",
                              label: "Total Users",
                              icon: Icons.people_outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              count: "320",
                              label: "Total Bookings",
                              icon: Icons.calendar_today_outlined,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: StatCard(
                              count: "150",
                              label: "Cancelled\nBookings",
                              icon: Icons.event_busy_outlined,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "Management",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: () {
                      Navigation.push(context, ManageAllHallsScreen());
                    },
                    child: const ManagementCard(
                      title: "Manage All Halls",
                      icon: Icons.account_balance_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Navigation.push(context, ManageAllUsersScreen());
                    },
                    child: const ManagementCard(
                      title: "Manage All Users",
                      icon: Icons.people_outline,
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFB8C00), Color(0xFFFFCC80)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Welcome, Admin!",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_outlined,
                    size: 25,
                    color: Colors.redAccent,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              GestureDetector(
                onTap: () {
                  Navigation.push(context, NotificationsScreen());
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: badges.Badge(
                    position: badges.BadgePosition.topEnd(top: -1, end: -1),
                    showBadge: true,
                    ignorePointer: true,
                    badgeContent: Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                    ),
                    badgeStyle: const badges.BadgeStyle(
                      shape: badges.BadgeShape.circle,
                      badgeColor: Colors.red,
                      padding: EdgeInsets.all(4),
                      elevation: 0,
                    ),
                    child: const Icon(Icons.notifications_outlined, size: 25),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color borderColor;
  final IconData secondaryIcon;

  const ActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.borderColor,
    required this.secondaryIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 40, color: iconColor),
              Positioned(
                bottom: -2,
                right: -2,
                child: Icon(secondaryIcon, size: 20, color: iconColor),
              ),
            ],
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[600]),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String count;
  final String label;
  final IconData icon;

  const StatCard({
    super.key,
    required this.count,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFEA845), Color(0xFFFFCE85)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: const Color(0xFF1D1D1D)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D1D1D),
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF333333),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ManagementCard extends StatelessWidget {
  final String title;
  final IconData icon;

  const ManagementCard({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: Colors.black87),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
        ],
      ),
    );
  }
}
