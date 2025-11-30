import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:venuemate_system/Screens/HallAdmin/create_package.dart';
import 'package:venuemate_system/Utils/navigation.dart';

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
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: GestureDetector(
              onTap: () {
                Navigation.push(context, CreatePackageScreen());
              },
              child: Container(
                width: double.infinity,
                height: 55,
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
                      size: 26,
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

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              "Event Packages",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: _packages.length,
              itemBuilder: (context, index) {
                final pkg = _packages[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: ClipRRect(
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
                  ),
                );
              },
            ),
          ),
        ],
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
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Rs. $price",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF58529),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: isActive,
                  onChanged: onToggle,
                  activeColor: const Color(0xFFF58529),
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.grey[200],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            "Includes:",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFeatureItem(Icons.groups_rounded, capacity, "Capacity"),
              _buildFeatureItem(Icons.restaurant_menu_rounded, menuItems, ""),
              _buildFeatureItem(Icons.room_service_rounded, services, ""),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String line1, String line2) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 32, color: const Color(0xFFF58529)),
          const SizedBox(height: 8),
          Text(
            line1,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          if (line2.isNotEmpty)
            Text(
              line2,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}
