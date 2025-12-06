import 'package:flutter/material.dart';
import 'package:venuemate_system/Screens/Customers/FavoritesScreen.dart';
import 'AllEventsScreen.dart';
import 'EditProfileScreen.dart';
import 'HelpandSupportScreen.dart';
import 'HomePageVenueScreen.dart';
import 'MapScreen.dart';
import 'MessagingScreen.dart';
import 'NotificationScreen.dart';
import 'SettingsScreen.dart';

class Profilescreen extends StatefulWidget {
  const Profilescreen({super.key});

  @override
  State<Profilescreen> createState() => _ProfilescreenState();
}

class _ProfilescreenState extends State<Profilescreen> {
  // Set index to 4 because this is the Profile screen
  int _selectedIndex = 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light grey background
      body: SingleChildScrollView(
        child: Column(
          children: [
            // TOP SECTION: Orange Background + Profile Info
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // 1. Orange Gradient Background
                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                     
                      // colors: [
                      //   Color(0xFFF47C20), // Your primary orange
                      //   Color(0xFFFFB74D), // Lighter orange for gradient
                      // ],
                      colors: [Color(0xFFF47C20), Color.fromARGB(255, 233, 184, 69)],
                          begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                    
                    ),
                  ),
                ),

                // 2. Profile Details (Avatar, Name, Email)
                Positioned(
                  top: 60,
                  child: Column(
                    children: [
                      const Text(
                        "Profile",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Avatar Circle
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        child: const CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white,
                          backgroundImage: NetworkImage(
                            'https://i.pravatar.cc/300', // Placeholder image
                          ),
                        ),
                      ),
                      const Text(
                        "Muhammad Ahmed",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                        const Text(
                        "m.ahmed@email.com",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white70,
                        ),
                      ), 
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 15,),

            // MIDDLE SECTION: Floating Action Card (Bookings/Logout)
            // We use transform to pull this container up over the orange background
            Transform.translate(
  offset: const Offset(0, -40),
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 0),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // All Bookings (already clickable)
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AllEventsScreen()),
              );
            },
            child: _buildActionItem(Icons.calendar_month_outlined, "All Bookings"),
          ),

          Container(height: 40, width: 1, color: Colors.grey[300]),

          // ✅ Logout (NOW CLICKABLE)
          InkWell(
            onTap: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => LogoutScreen()),
              // );
            },
            child: _buildActionItem(Icons.logout, "Logout"),
          ),
        ],
      ),
    ),
  ),
),


            // BOTTOM SECTION: Menu List (Edit Profile, etc.)
           Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20),
  child: Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        _buildMenuItem(
          Icons.person_outline,
          "Edit Profile",
          () {
            Navigator.push(context,
              MaterialPageRoute(builder: (_) => EditProfileScreen()));
          },
        ),
        _buildDivider(),

        _buildMenuItem(
          Icons.notifications_none,
          "Notifications",
          () {
            Navigator.push(context,
              MaterialPageRoute(builder: (_) => NotificationScreen()));
          },
        ),
        _buildDivider(),

        _buildMenuItem(
          Icons.settings_outlined,
          "Settings",
          () {
            Navigator.push(context,
              MaterialPageRoute(builder: (_) => SettingsScreen()));
          },
        ),
        _buildDivider(),

        _buildMenuItem(
          Icons.headset_mic_outlined,
          "Help & Support",
          () {
            Navigator.push(context,
              MaterialPageRoute(builder: (_) => HelpSupportScreen()));
          },
        ),
      ],
    ),
  ),
),
          


            const SizedBox(height: 20),
            const Text(
              "Member Since November 2022",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),

      // YOUR BOTTOM NAVIGATION BAR CODE
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFF47C20),
        unselectedItemColor: Colors.black,
        backgroundColor: Colors.white,
        items: [
          _navBarItem(Icons.home, "Home", 0, unselectedColor: Colors.black),
          _navBarItem(Icons.favorite_border, "Favorites", 1, unselectedColor: Colors.black),
          _navBarItem(Icons.map_outlined, "Map", 2, unselectedColor: Colors.black),
          _navBarItem(Icons.message_outlined, "Messages", 3, unselectedColor: Colors.black),
          _navBarItem(Icons.person_outline, "Profile", 4, unselectedColor: Colors.black),
        ],
        onTap: (index) {
          if (index == 0) {
            // Navigate back to Home
             Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
            // Navigator.pop(context);
          } else if (index == 1) {
            // Navigate to Map
             // Navigator.push(...)
              Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FavoritesScreen()),
            );
          }
          
          else if (index == 2) {
            // Navigate to Map
             // Navigator.push(...)
              Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MapScreen()),
            );
          }
          else if (index == 3) {
            // Navigate to Map
             // Navigator.push(...)
              Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChatListScreen()),
            );
          } else if (index == 4) {
            // We are already on Profile, do nothing
          } else {
             // Handle other tabs
             setState(() => _selectedIndex = index);
          }
        },
      ),
    );
  }

  // --- Helper Widgets ---

  // 1. The small action buttons (Bookings / Logout)
  Widget _buildActionItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.black87),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // 2. The Menu List Items
  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,   // 👈 individual function for each item
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange, size: 26),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    ),
  );
}


  // 3. Simple Divider
  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, indent: 20, endIndent: 20, color: Color(0xFFEEEEEE));
  }

  // YOUR NAVBAR ITEM BUILDER
  BottomNavigationBarItem _navBarItem(IconData icon, String label, int index,
      {Color unselectedColor = Colors.black}) {
    bool isActive = _selectedIndex == index;

    return BottomNavigationBarItem(
      label: label,
      icon: Column(
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFFF47C20) : unselectedColor,
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 3,
            width: isActive ? 25 : 0,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFF47C20) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    );
  }
}