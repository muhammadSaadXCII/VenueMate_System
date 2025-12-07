import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:venuemate_system/Utils/app_navigation.dart';
import 'package:venuemate_system/Screens/HallAdmin/create_package.dart';

class ManagePackagesScreen extends StatefulWidget {
  const ManagePackagesScreen({super.key});

  @override
  State<ManagePackagesScreen> createState() => _ManagePackagesScreenState();
}

class _ManagePackagesScreenState extends State<ManagePackagesScreen> {
  final List<Map<String, dynamic>> _packages = [
    {
      "title": "Exclusive Birthday Celebration Bundle",
      "price": "30,000",
      "capacity": "200 Guests",
      "menuCount": "12 Menu Items",
      "serviceCount": "4 Services",
      "isActive": true,
    },
    {
      "title": "Premium Wedding Package",
      "price": "150,000",
      "capacity": "500 Guests",
      "menuCount": "20 Menu Items",
      "serviceCount": "6 Services",
      "isActive": true,
    },
    {
      "title": "Corporate Meeting Basic",
      "price": "50,000",
      "capacity": "100 Guests",
      "menuCount": "5 Menu Items",
      "serviceCount": "2 Services",
      "isActive": false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1100;
    final isTablet = screenWidth >= 650 && screenWidth < 1100;

    final horizontalPadding = isDesktop ? screenWidth * 0.05 : 20.0;
    int crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

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
          "Manage Packages",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    20,
                    horizontalPadding,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: GestureDetector(
                            onTap: () {
                              AppNavigation.push(context, CreatePackageScreen());
                            },
                            child: Container(
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE0C2),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_circle_outline,
                                    color: Color(0xFFF58529),
                                    size: 24,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    "Add New Package",
                                    style: TextStyle(
                                      color: Color(0xFFF58529),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          "Event Packages",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: EdgeInsets.only(
                  left: horizontalPadding,
                  right: horizontalPadding,
                  top: 8.0,
                  bottom: 40,
                ),
                sliver: isDesktop || isTablet
                    ? SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,

                          mainAxisExtent: 230,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildPackageItem(index),
                          childCount: _packages.length,
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildPackageItem(index),
                          ),
                          childCount: _packages.length,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackageItem(int index) {
    final pkg = _packages[index];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Slidable(
        key: ValueKey(pkg['title']),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (context) {},
              backgroundColor: Colors.blue.shade50,
              foregroundColor: Colors.blue,
              icon: Icons.edit,
              label: 'Edit',
            ),
            SlidableAction(
              onPressed: (context) {},
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: PackageCard(
          title: pkg['title'],
          price: pkg['price'],
          capacity: pkg['capacity'],
          menuItems: pkg['menuCount'],
          services: pkg['serviceCount'],
          isActive: pkg['isActive'],
          onToggle: (val) {
            setState(() {
              pkg['isActive'] = val;
            });
          },
        ),
      ),
    );
  }
}

class PackageCard extends StatelessWidget {
  final String title;
  final String price;
  final String capacity;
  final String menuItems;
  final String services;
  final bool isActive;
  final ValueChanged<bool> onToggle;

  const PackageCard({
    super.key,
    required this.title,
    required this.price,
    required this.capacity,
    required this.menuItems,
    required this.services,
    required this.isActive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isActive ? "Active" : "Inactive",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.green : Colors.grey,
                  ),
                ),
              ),
              SizedBox(
                height: 24,
                child: Transform.scale(
                  scale: 0.7,
                  child: Switch(
                    value: isActive,
                    onChanged: onToggle,
                    activeColor: const Color(0xFFF58529),
                    inactiveThumbColor: Colors.grey.shade400,
                    inactiveTrackColor: Colors.grey.shade200,
                    trackOutlineColor: MaterialStateProperty.all(
                      Colors.transparent,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 6),

          Text(
            "Rs. $price",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFFF58529),
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFeatureItem(Icons.groups_outlined, capacity, "Capacity"),
              _buildFeatureItem(Icons.restaurant_menu, menuItems, "Menu"),
              _buildFeatureItem(
                Icons.room_service_outlined,
                services,
                "Services",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String value, String label) {
    final displayValue = value.split(' ').first;
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(
          displayValue,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}
