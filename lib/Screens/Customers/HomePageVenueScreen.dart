import 'package:flutter/material.dart';
import 'package:venuemate_system/Customers/MapScreen.dart';
import 'package:venuemate_system/Customers/MessagingScreen.dart';
import 'package:venuemate_system/Customers/NotificationScreen.dart';
import 'package:venuemate_system/Customers/PackagesDetailScreen.dart';
import 'package:venuemate_system/Customers/ProfileScreen.dart';
import 'package:venuemate_system/Customers/SearchingScreen.dart';
import 'package:venuemate_system/Customers/VenueDetailScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _selectedCategory = 0; // 0 = Venues, 1 = Packages

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // ===========================
            //          HEADER
            // ===========================
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF47C20), Color.fromARGB(255, 233, 184, 69)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location + Notification
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Location',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.black),
                              const SizedBox(width: 4),
                              const Text(
                                '123 Anywhere St., Any City',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Notification
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => NotificationScreen()),
                            );
                          },
                          child: const Icon(Icons.notifications_outlined,
                              color: Colors.black, size: 28),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search Box
                  GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FilterSearchScreen()), // your next screen
    );
  },
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4E9),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const AbsorbPointer( // prevents keyboard opening
      child: TextField(
        readOnly: true,
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          hintText: "Search...",
          hintStyle: TextStyle(color: Colors.grey),
        ),
      ),
    ),
  ),
)

                ],
              ),
            ),

            // ===========================
            //        MAIN CONTENT
            // ===========================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Icons with Active Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildCategoryItem(
                          "assets/images/venuses logo1 1.png",
                          "Venues",
                          0,
                        ),
                        _buildCategoryItem(
                          "assets/images/pacakgeslogo1 1.png",
                          "Packages",
                          1,
                        ),
                      ],
                    ),

                    Divider(color: Colors.grey[600]),
                    const SizedBox(height: 4),

                    // Show content based on selected category
                    _selectedCategory == 0 
                        ? _buildVenuesContent() 
                        : _buildPackagesContent(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ===========================
      //   BOTTOM NAVIGATION BAR
      // ===========================
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
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MapScreen()),
            );
          } else if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Profilescreen()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChatListScreen()),
            );
          } else {
            setState(() => _selectedIndex = index);
          }
        },
      ),
    );
  }

  // Bottom Nav Item
  BottomNavigationBarItem _navBarItem(
      IconData icon, String label, int index,
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

  // ===========================
  //       CATEGORY ITEM (WITH ACTIVE INDICATOR)
  // ===========================
  Widget _buildCategoryItem(String imagePath, String label, int index) {
    bool isActive = _selectedCategory == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = index;
        });
      },
      child: Column(
        children: [
          Image.asset(
            imagePath,
            width: 40,
            height: 40,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? Colors.black : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          // Active Indicator Line
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 3,
            width: isActive ? 50 : 0,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================
  //     VENUES CONTENT
  // ===========================
  Widget _buildVenuesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recently Viewed
        const Text(
          "Recently Viewed",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 185,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildRecentlyViewedCard(),
              _buildRecentlyViewedCard(),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Featured Venues
        const Text(
          "Featured Venues",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildFeaturedVenueCard(),
      ],
    );
  }

  // ===========================
  //     PACKAGES CONTENT
  // ===========================
  Widget _buildPackagesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recently Viewed Packages
        const Text(
          "Recently Viewed",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 185,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildRecentlyViewedCard(),
              _buildRecentlyViewedCard(),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Featured Packages
        const Text(
          "Featured Venues",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildFeaturedPackageCard(),
      ],
    );
  }

  // ===========================
  //     FEATURED PACKAGE CARD (NEW DESIGN)
  // ===========================
  Widget _buildFeaturedPackageCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade400,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: InkWell(
                  onTap: (){
                    Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Packagesdetailscreen()),
            );
                  },
                  child: Image.asset(
                    "assets/images/cardimage 2.png",
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Heart Icon - TOP LEFT
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_border,
                    color: Colors.red,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  "Exclusive Birthday Celebration Bundle",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                
                // Marquee Logo with Location
                Row(
                  children: [
                    // Small Marquee Logo
                    Image.asset(
                      "assets/images/hallpic.png",
                      width: 25,
                      height: 25,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.location_on, size: 14, color: Colors.grey);
                      },
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      "Al Rehmat Banquet Hall",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(
  color: Color(0xFFCCCCCC), // Color of the line
  thickness: 5,       // Thickness of the line
  indent: 16,         // Optional: space from the left
  endIndent: 16,      // Optional: space from the right
),

                
                // Includes Section
                const Text(
                  "Includes:",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Icons Row with Asset Images
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildIncludeItemWithImage("assets/images/guest.png", "200 Guests \n Capacity"),
                    _buildIncludeItemWithImage("assets/images/menuitem.png", "12 Menu Items"),
                    _buildIncludeItemWithImage("assets/images/services.png", "4 Services"),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Price
                const Text(
                  "Rs. 20,000",
                  style: TextStyle(
                    color: Color(0xFFF47C20),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for includes items with asset images
  Widget _buildIncludeItemWithImage(String imagePath, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          // decoration: BoxDecoration(
          //   color: const Color(0xFFF47C20).withOpacity(0.1),
          //   borderRadius: BorderRadius.circular(8),
          // ),
          child: Image.asset(
            imagePath,
            width: 35,
            height: 35,
            fit: BoxFit.contain,
            color: const Color(0xFFF47C20),
            errorBuilder: (context, error, stackTrace) {
              // Fallback icons if images not found
              IconData fallbackIcon = Icons.fastfood;
              if (label == "Dinner") fallbackIcon = Icons.restaurant;
              if (label == "Lighting") fallbackIcon = Icons.lightbulb;
              
              return Icon(
                fallbackIcon,
                color: const Color(0xFFF47C20),
                size: 24,
              );
            },
          ),
        ),
        // const SizedBox(height: 0),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ===========================
  //     RECENTLY VIEWED CARD
  // ===========================
  Widget _buildRecentlyViewedCard() {
    return Container(
      width: 165,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade400,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.asset(
                  "assets/images/cardimage 2.png",
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_border,
                    size: 18,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Al Rehman Marquee...",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: const [
                    Text(
                      "300 Capacity",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.star, size: 13, color: Colors.amber),
                    SizedBox(width: 3),
                    Text(
                      "4.0",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================
  //     FEATURED VENUE CARD
  // ===========================
  Widget _buildFeaturedVenueCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade400,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: InkWell(
                  onTap: (){
                    Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => VenueDetailsScreen()),
            );
                  },
                  child: Image.asset(
                    "assets/images/cardimage 2.png",
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_border,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.star, size: 14, color: Colors.amber),
                      SizedBox(width: 3),
                      Text(
                        "4.0",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Al Rehman Banquet Hall",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Model Colony, Street 124, Karachi, Pakistan • 30 Reviews",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "300–1000 Capacity • 4 Services • 20 Different Menu Items",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Rs. 15,000/Event",
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
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










