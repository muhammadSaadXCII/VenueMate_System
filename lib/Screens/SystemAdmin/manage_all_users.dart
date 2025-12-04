import 'package:flutter/material.dart';
import 'package:venuemate_system/Screens/SystemAdmin/manage_user_details.dart';
import 'package:venuemate_system/Utils/navigation.dart';

class ManageAllUsersScreen extends StatefulWidget {
  const ManageAllUsersScreen({super.key});

  @override
  State<ManageAllUsersScreen> createState() => _ManageAllUsersScreenState();
}

class _ManageAllUsersScreenState extends State<ManageAllUsersScreen> {
  String _selectedFilter = "All";

  final List<Map<String, dynamic>> _users = [
    {
      "name": "Rehman Hussain",
      "role": "Hall Admin",
      "email": "admin@alrehman.com",
      "status": "Active",
      "image":
          "https://img.freepik.com/free-psd/3d-illustration-business-man-with-glasses_23-2149436194.jpg",
    },
    {
      "name": "Zulhaq Hussain",
      "role": "Customer",
      "email": "zulhaq.khan@email.com",
      "status": "Deactivated",
      "image":
          "https://img.freepik.com/free-psd/3d-illustration-business-man-with-glasses_23-2149436194.jpg",
    },
    {
      "name": "Rehman Hussain",
      "role": "Hall Admin",
      "email": "admin@alrehman.com",
      "status": "Active",
      "image":
          "https://img.freepik.com/free-psd/3d-illustration-business-man-with-glasses_23-2149436194.jpg",
    },
    {
      "name": "Zulhaq Hussain",
      "role": "Customer",
      "email": "zulhaq.khan@email.com",
      "status": "Deactivated",
      "image":
          "https://img.freepik.com/free-psd/3d-illustration-business-man-with-glasses_23-2149436194.jpg",
    },
  ];

  final List<String> _filters = [
    "All",
    "Active",
    "Deactivated",
    "Customer",
    "Hall Admin",
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
          "Manage All Users",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
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
                      hintText: "Search users....",
                      hintStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        _filters.map((filter) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: _buildFilterTab(filter),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: UserManagementCard(
                    name: user['name'],
                    role: user['role'],
                    email: user['email'],
                    status: user['status'],
                    imageUrl: user['image'],
                    onManageTap: () {
                      Navigation.push(context, ManageUserDetailsScreen(user: user,));
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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

class UserManagementCard extends StatelessWidget {
  final String name;
  final String role;
  final String email;
  final String status;
  final String imageUrl;
  final VoidCallback onManageTap;

  const UserManagementCard({
    super.key,
    required this.name,
    required this.role,
    required this.email,
    required this.status,
    required this.imageUrl,
    required this.onManageTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isActive = status == "Active";

    return GestureDetector(
      onTap: onManageTap,
      child: Container(
        height: 95,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: ClipOval(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) =>
                            Container(color: Colors.grey[200]),
                  ),
                ),
              ),
      
              const SizedBox(width: 12),
      
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: const TextStyle(fontSize: 14, color: Colors.black),
                        children: [
                          TextSpan(
                            text: "$name ",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: "($role)",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
      
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isActive
                              ? const Color(0xFFD8F3DC)
                              : const Color(0xFFFFD8D8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: isActive ? Colors.green[700] : Colors.red[400],
                        fontSize: 10,
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
                          size: 11,
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
    );
  }
}
