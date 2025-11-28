import 'package:flutter/material.dart';
import 'package:venuemate_system/SystemAdmin/manage_hall_details.dart';
import 'package:venuemate_system/Utils/navigation.dart';

class ManageAllHallsScreen extends StatefulWidget {
  const ManageAllHallsScreen({super.key});

  @override
  State<ManageAllHallsScreen> createState() => _ManageAllHallsScreenState();
}

class _ManageAllHallsScreenState extends State<ManageAllHallsScreen> {
  String _selectedFilter = "All";

  final List<Map<String, dynamic>> _halls = [
    {
      "name": "Al Rehman Banquet Hall",
      "owner": "Rehman Hussain",
      "status": "Approved",
      "image":
          "https://images.unsplash.com/photo-1519167758481-83f550bb49b3?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60",
    },
    {
      "name": "Akbar Marquee",
      "owner": "Ali Akbar",
      "status": "Disabled",
      "image":
          "https://images.unsplash.com/photo-1519167758481-83f550bb49b3?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60",
    },
    {
      "name": "Grand Palace Hall",
      "owner": "Usman Ghani",
      "status": "Approved",
      "image":
          "https://images.unsplash.com/photo-1519167758481-83f550bb49b3?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
          "Manage All Halls",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: "Search Halls...",
                      hintStyle: TextStyle(color: Colors.black87),
                      prefixIcon: Icon(Icons.search, color: Colors.black87),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFilterTab("All"),
                    const SizedBox(width: 12),
                    _buildFilterTab("Approved"),
                    const SizedBox(width: 12),
                    _buildFilterTab("Disabled"),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _halls.length,
              itemBuilder: (context, index) {
                final hall = _halls[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: HallManagementCard(
                    name: hall['name'],
                    owner: hall['owner'],
                    status: hall['status'],
                    imageUrl: hall['image'],
                    onManageTap: () {
                      Navigation.push(context, ManageHallDetailsScreen(hall: hall,));
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String text) {
    bool isActive = _selectedFilter == text;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = text;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFEA845) : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class HallManagementCard extends StatelessWidget {
  final String name;
  final String owner;
  final String status;
  final String imageUrl;
  final VoidCallback onManageTap;

  const HallManagementCard({
    super.key,
    required this.name,
    required this.owner,
    required this.status,
    required this.imageUrl,
    required this.onManageTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isApproved = status == "Approved";

    return GestureDetector(
      onTap: onManageTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
      
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.25),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: 90,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          Container(width: 90, color: Colors.grey[200]),
                ),
              ),
            ),
      
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Hall Owner: $owner",
                      style: TextStyle(fontSize: 11, color: Colors.grey[800]),
                    ),
                    const Spacer(),
      
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isApproved
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color:
                                  isApproved
                                      ? Colors.green[700]
                                      : Colors.red[700],
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
      
                        GestureDetector(
                          onTap: onManageTap,
                          child: Row(
                            children: [
                              Text(
                                "Manage",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
