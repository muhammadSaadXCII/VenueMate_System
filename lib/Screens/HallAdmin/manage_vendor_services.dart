import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:venuemate_system/Screens/HallAdmin/add_vendor_service_sheet.dart';

class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  final List<Map<String, dynamic>> _services = [
    {
      "name": "Premium Catering",
      "price": "5000",
      "description": "Full-service dinner & dessert.",
    },
    {
      "name": "Event Photography",
      "price": "5000",
      "description": "Full-service dinner & dessert.",
    },
    {
      "name": "DJ & Sound System",
      "price": "8000",
      "description": "Professional sound setup for events.",
    },
    {
      "name": "Valet Parking",
      "price": "3000",
      "description": "Dedicated valet service for guests.",
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
          "Manage Services",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1100;
          final isTablet =
              constraints.maxWidth >= 700 && constraints.maxWidth < 1100;

          int crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const AddServiceSheet(),
                            );
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
                                  color: Color(0xFFF47C20),
                                  size: 26,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "Add New Service",
                                  style: TextStyle(
                                    color: Color(0xFFF47C20),
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

                    const Text(
                      "Additional Services",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Expanded(
                      child: isDesktop || isTablet
                          ? GridView.builder(
                              itemCount: _services.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 20,
                                    mainAxisSpacing: 20,

                                    mainAxisExtent: 100,
                                  ),
                              itemBuilder: (context, index) {
                                return _buildServiceItem(index);
                              },
                            )
                          : ListView.separated(
                              itemCount: _services.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                return _buildServiceItem(index);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceItem(int index) {
    final service = _services[index];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Slidable(
        key: ValueKey(index),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (context) {},
              backgroundColor: Colors.blue.shade50,
              foregroundColor: Colors.blue,
              icon: Icons.edit,
              label: 'Edit',
              borderRadius: BorderRadius.circular(12),
            ),
            SlidableAction(
              onPressed: (context) {},
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              icon: Icons.delete,
              label: 'Delete',
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        child: ServiceCard(
          name: service['name'],
          price: service['price'],
          description: service['description'],
        ),
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final String name;
  final String price;
  final String description;

  const ServiceCard({
    super.key,
    required this.name,
    required this.price,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "Rs. $price",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF47C20),
            ),
          ),
        ],
      ),
    );
  }
}
