import 'package:flutter/material.dart';
import 'HomePageVenueScreen.dart';
import 'MessagingScreen.dart';
import 'ProfileScreen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  int _selectedIndex = 2; // Map tab selected by default

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          
          // Map Background Image
          SizedBox.expand(
            child: Image.asset(
              'assets/images/googlemap 2.png',
              fit: BoxFit.cover,
            ),
          ),
          Center(child: Image.asset('assets/images/locationpin 3.png')),
          Positioned(
            bottom: 100,
            right: 30,
            child: Image.asset('assets/images/locationpin 3.png')),
             Positioned(
            top: 500,
            left: 30,
            child: Image.asset('assets/images/locationpin 3.png')),

          // Search Text Field
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search....',
                  border: InputBorder.none,
                  icon: Icon(Icons.search),
                ),
              ),
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar
        bottomNavigationBar: BottomNavigationBar(
  currentIndex: _selectedIndex,
  type: BottomNavigationBarType.fixed,
  selectedItemColor: const Color(0xFFF47C20),
  unselectedItemColor: Colors.black,
  backgroundColor: Colors.white,
  items: [
    _navBarItem(Icons.home, "Home", 0, ),
    _navBarItem(Icons.favorite_border, "Favorites", 1, ),
    _navBarItem(Icons.map_outlined, "Map", 2, ),
    _navBarItem(Icons.message_outlined, "Messages", 3, ),
    _navBarItem(Icons.person_outline, "Profile", 4, ),
  ],
  onTap: (index) {
    if (index == 0) {
      // Navigate to HomePage
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()), // replace MapPage() with your page
      );
    }else if(index==2){
       Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MapScreen()),
            );
    }
    else if(index==3){
       Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChatListScreen()),
            );
    }
     else if(index==4){
       Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Profilescreen()),
            );
    }
     else {
      // Update selected index for other tabs
      setState(() => _selectedIndex = index);
    }
  },
),
    );
  }

  BottomNavigationBarItem _navBarItem(IconData icon, String label, int index) {
    bool isActive = _selectedIndex == index;

    return BottomNavigationBarItem(
      label: '',
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFFF47C20) : Colors.black,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFFF47C20) : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
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
