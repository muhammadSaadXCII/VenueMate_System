import 'package:flutter/material.dart';
import 'package:venuemate_system/Utils/app_navigation.dart';
import 'package:venuemate_system/Screens/SystemAdmin/manage_user_details.dart';

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
    final horizontalPadding = 20.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: true,
        title: Text(
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
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 10,
            ),
            child: Column(
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    style: TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Search users....",
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey,
                        size: 24,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

                SizedBox(height: 16),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children:
                        _filters.map((filter) {
                          return Padding(
                            padding: EdgeInsets.only(right: 10.0),
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
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 10,
              ),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: UserManagementCard(
                    name: user['name'],
                    role: user['role'],
                    email: user['email'],
                    status: user['status'],
                    imageUrl: user['image'],
                    onManageTap: () {
                      AppNavigation.push(
                        context,
                        ManageUserDetailsScreen(user: user),
                      );
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
    final fontSize = 13.0;
    final horizontalPadding = 20.0;
    final verticalPadding = 8.0;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = text;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF47C20) : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
          boxShadow:
              isActive
                  ? [
                    BoxShadow(
                      color: const Color(0xFFF47C20).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
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

    final cardHeight = 95.0;

    final avatarSize = 60.0;
    final borderRadius = 16.0;
    final cardPadding = 10.0;

    final nameFontSize = 14.0;
    final roleFontSize = 12.0;
    final emailFontSize = 12.0;
    final statusFontSize = 10.0;
    final manageFontSize = 13.0;
    final iconSize = 11.0;

    return GestureDetector(
      onTap: onManageTap,
      child: Container(
        height: cardHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
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
          padding: EdgeInsets.all(cardPadding),
          child: Row(
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade100, width: 1),
                ),
                child: ClipOval(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.person,
                            color: Colors.grey[400],
                            size: avatarSize * 0.5,
                          ),
                        ),
                  ),
                ),
              ),

              SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: nameFontSize,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(
                            text: "$name ",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: "($role)",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: roleFontSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: emailFontSize,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 8),

              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                        fontSize: statusFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: onManageTap,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Manage",
                            style: TextStyle(
                              fontSize: manageFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: iconSize,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
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
