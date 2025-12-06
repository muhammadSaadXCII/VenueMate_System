import 'package:flutter/material.dart';
import 'package:venuemate_system/Screens/Customers/HomePageVenueScreen.dart';
// import 'HomeScreen.dart';
import 'MapScreen.dart';
import 'MessagingScreen.dart';
import 'ProfileScreen.dart';
import 'VenueDetailScreen.dart';
import 'PackagesDetailScreen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  int _selectedIndex = 1; // Favorites tab is active

  void _removeFavorite(String id) {
    setState(() {
      favoritesList.removeWhere((item) => item.id == id);
    });
  }

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
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'My Favorites',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),

            // ===========================
            //        MAIN CONTENT
            // ===========================
            Expanded(
              child: favoritesList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No favorites yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start adding venues and packages to your favorites!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: favoritesList.length,
                      itemBuilder: (context, index) {
                        final item = favoritesList[index];
                        return _buildFavoriteCard(item);
                      },
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
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          } else if (index == 2) {
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
  //     FAVORITE CARD
  // ===========================
  Widget _buildFavoriteCard(FavoriteItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                  onTap: () {
                    if (item.isPackage) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Packagesdetailscreen()),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => VenueDetailsScreen()),
                      );
                    }
                  },
                  child: Image.asset(
                    item.imagePath,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Heart Icon - Filled
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () => _removeFavorite(item.id),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                ),
              ),
              // Rating Badge (for venues)
              if (!item.isPackage)
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
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text(
                          item.rating,
                          style: const TextStyle(
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
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                
                // Subtitle/Location
                if (item.isPackage)
                  Row(
                    children: [
                      Image.asset(
                        "assets/images/hallpic.png",
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.location_on, size: 14, color: Colors.grey);
                        },
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    item.location ?? item.subtitle,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                
                // Additional Info
                if (item.capacity != null || item.includes != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    [item.capacity, item.includes]
                        .where((e) => e != null)
                        .join(' • '),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
                
                const SizedBox(height: 8),
                
                // Price
                Text(
                  item.price,
                  style: const TextStyle(
                    color: Color(0xFFF47C20),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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