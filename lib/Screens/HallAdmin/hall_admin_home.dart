import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:badges/badges.dart' as badges;
import 'package:venuemate_system/Utils/app_navigation.dart';
import 'package:venuemate_system/Screens/HallAdmin/manage_hall.dart';
import 'package:venuemate_system/Screens/HallAdmin/manage_menu.dart';
import 'package:venuemate_system/Screens/HallAdmin/manage_packages.dart';
import 'package:venuemate_system/Screens/Shared/user_notifications.dart';
import 'package:venuemate_system/Screens/HallAdmin/hall_admin_bookings.dart';
import 'package:venuemate_system/Screens/HallAdmin/manage_vendor_services.dart';

class HallAdminHomeScreen extends StatelessWidget {
  const HallAdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 60,
            bottom: 30,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF47C20), Color(0xFFFFD166)],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Welcome, Rehman!",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              GestureDetector(
                onTap: () {
                  AppNavigation.push(context, UserNotificationsScreen());
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
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Bookings Status",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),

                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 130,
                        width: 130,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 0,
                            centerSpaceRadius: 40,
                            sections: [
                              _buildPieSection(Colors.redAccent, 25),
                              _buildPieSection(const Color(0xFFFEDA77), 40),
                              _buildPieSection(Colors.orange, 15),
                              _buildPieSection(Colors.greenAccent.shade400, 10),
                            ],
                          ),
                        ),
                      ),

                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Booking Data",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const Text(
                              "24 Total Bookings",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildLegendItem(
                              const Color(0xFFFEDA77),
                              "Upcoming: 10",
                            ),
                            _buildLegendItem(Colors.orange, "Pending: 4"),
                            _buildLegendItem(
                              Colors.greenAccent.shade400,
                              "Completed: 2",
                            ),
                            _buildLegendItem(Colors.redAccent, "Cancelled: 6"),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => HallAdminBookingsScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                "View Bookings >",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  "Quick Actions",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),

                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            title: "Manage Hall",
                            icon: Icons.storefront_outlined,
                            onActionTap: () {
                              AppNavigation.push(context, ManageHallScreen());
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionCard(
                            title: "Manage Menu",
                            icon: Icons.restaurant_menu_outlined,
                            onActionTap: () {
                              AppNavigation.push(context, ManageMenuScreen());
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            title: "Manage Services",
                            icon: Icons.room_service_outlined,
                            onActionTap: () {
                              AppNavigation.push(
                                context,
                                ManageServicesScreen(),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionCard(
                            title: "Manage Packages",
                            icon: Icons.card_giftcard_outlined,
                            onActionTap: () {
                              AppNavigation.push(
                                context,
                                ManagePackagesScreen(),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  PieChartSectionData _buildPieSection(Color color, double value) {
    return PieChartSectionData(
      color: color,
      value: value,
      radius: 30,
      showTitle: false,
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required void Function() onActionTap,
  }) {
    return GestureDetector(
      onTap: onActionTap,
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFEA845), Color(0xFFFFCE85)],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: const Color(0xFF1D1D1D)),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Color(0xFF1D1D1D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
