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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isMobile = screenWidth < 600;

    final horizontalPadding =
        isDesktop
            ? screenWidth * 0.1
            : isTablet
            ? 40.0
            : 20.0;

    final crossAxisCount = isDesktop ? 2 : 1;

    final childAspectRatio =
        isDesktop
            ? 3.8
            : isTablet
            ? 5.0
            : 3.5;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: isMobile,
        title: Text(
          "Manage All Users",
          style: TextStyle(
            color: Colors.black,
            fontSize:
                isDesktop
                    ? 24
                    : isTablet
                    ? 22
                    : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical:
                  isDesktop
                      ? 20
                      : isTablet
                      ? 16
                      : 10,
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
                    style: TextStyle(fontSize: isDesktop ? 16 : 14),
                    decoration: InputDecoration(
                      hintText: "Search users....",
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: isDesktop ? 16 : 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey,
                        size: isDesktop ? 26 : 24,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: isDesktop ? 18 : 14,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: isDesktop ? 24 : 16),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment:
                        isDesktop || isTablet
                            ? MainAxisAlignment.center
                            : MainAxisAlignment.start,
                    children:
                        _filters.map((filter) {
                          return Padding(
                            padding: EdgeInsets.only(
                              right: isDesktop ? 12.0 : 10.0,
                            ),
                            child: _buildFilterTab(filter, isDesktop, isTablet),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child:
                isDesktop
                    ? GridView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 10,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return UserManagementCard(
                          name: user['name'],
                          role: user['role'],
                          email: user['email'],
                          status: user['status'],
                          imageUrl: user['image'],
                          isDesktop: isDesktop,
                          isTablet: isTablet,
                          onManageTap: () {
                            AppNavigation.push(
                              context,
                              ManageUserDetailsScreen(user: user),
                            );
                          },
                        );
                      },
                    )
                    : ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 10,
                      ),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: isTablet ? 20.0 : 16.0,
                          ),
                          child: UserManagementCard(
                            name: user['name'],
                            role: user['role'],
                            email: user['email'],
                            status: user['status'],
                            imageUrl: user['image'],
                            isDesktop: isDesktop,
                            isTablet: isTablet,
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

  Widget _buildFilterTab(String text, bool isDesktop, bool isTablet) {
    bool isActive = _selectedFilter == text;
    final fontSize = isDesktop ? 15.0 : 13.0;
    final horizontalPadding = isDesktop ? 24.0 : 20.0;
    final verticalPadding = isDesktop ? 10.0 : 8.0;

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
              isActive && (isDesktop || isTablet)
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
  final bool isDesktop;
  final bool isTablet;
  final VoidCallback onManageTap;

  const UserManagementCard({
    super.key,
    required this.name,
    required this.role,
    required this.email,
    required this.status,
    required this.imageUrl,
    required this.isDesktop,
    required this.isTablet,
    required this.onManageTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isActive = status == "Active";

    final cardHeight =
        isDesktop
            ? 130.0
            : isTablet
            ? 105.0
            : 95.0;

    final avatarSize =
        isDesktop
            ? 70.0
            : isTablet
            ? 65.0
            : 60.0;
    final borderRadius = isDesktop ? 20.0 : 16.0;
    final cardPadding =
        isDesktop
            ? 16.0
            : isTablet
            ? 14.0
            : 10.0;

    final nameFontSize =
        isDesktop
            ? 16.0
            : isTablet
            ? 15.0
            : 14.0;
    final roleFontSize =
        isDesktop
            ? 14.0
            : isTablet
            ? 13.0
            : 12.0;
    final emailFontSize =
        isDesktop
            ? 14.0
            : isTablet
            ? 13.0
            : 12.0;
    final statusFontSize =
        isDesktop
            ? 12.0
            : isTablet
            ? 11.0
            : 10.0;
    final manageFontSize =
        isDesktop
            ? 15.0
            : isTablet
            ? 14.0
            : 13.0;
    final iconSize =
        isDesktop
            ? 14.0
            : isTablet
            ? 13.0
            : 11.0;

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
              blurRadius: isDesktop ? 12 : 8,
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
                  border: Border.all(
                    color: Colors.grey.shade100,
                    width: isDesktop ? 2 : 1,
                  ),
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

              SizedBox(width: isDesktop ? 16 : 12),

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
                    SizedBox(height: isDesktop ? 6 : 4),
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

              SizedBox(
                width:
                    isDesktop
                        ? 16
                        : isTablet
                        ? 12
                        : 8,
              ),

              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          isDesktop
                              ? 14
                              : isTablet
                              ? 12
                              : 10,
                      vertical: isDesktop ? 6 : 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isActive
                              ? const Color(0xFFD8F3DC)
                              : const Color(0xFFFFD8D8),
                      borderRadius: BorderRadius.circular(isDesktop ? 10 : 8),
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
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 12 : 8,
                        vertical: isDesktop ? 6 : 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isDesktop || isTablet
                                ? Colors.grey[100]
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            isDesktop || isTablet
                                ? Border.all(color: Colors.grey.shade300)
                                : null,
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
                          SizedBox(width: isDesktop ? 4 : 2),
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
