import 'package:flutter/material.dart';
import 'package:venuemate_system/Customers/BasicDetailScreen.dart';

class Packagesdetailscreen extends StatefulWidget {
  const Packagesdetailscreen({Key? key}) : super(key: key);

  @override
  State<Packagesdetailscreen> createState() => _VenueDetailsScreenState();
}

class _VenueDetailsScreenState extends State<Packagesdetailscreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFavorite = false;
  int _currentImageIndex = 0;
  final int _totalImages = 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // UPDATED
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(),
          _buildVenueTitleSection(),
          _buildTabBar(),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildMenuTab(),
                _buildServicesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _buildHeader() {
    return Stack(
      children: [
        Container(
          height: 240,
          width: double.infinity,
          child: Image.asset(
            'assets/images/cardimage 2.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Icon(Icons.image, size: 60, color: Colors.grey),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    padding: EdgeInsets.zero,
                  ),
                ),
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _isFavorite = !_isFavorite;
                      });
                    },
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentImageIndex + 1}/$_totalImages',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- VENUE TITLE ----------------
  Widget _buildVenueTitleSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Al Rehman Banquet Hall',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Model Colony, Street 124, Karachi, Pakistan',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: const [
                    Icon(Icons.star, color: Colors.amber, size: 14),
                    SizedBox(width: 4),
                    Text(
                      '4.0',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '(30)',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          const Text(
            "Contact",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 9),
            child: Row(
              children: const [
                Icon(Icons.person_outline, size: 20),
                SizedBox(width: 8),
                Text(
                  'Rehman Hussain',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                Icon(Icons.message_outlined, size: 20),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Divider(
              color: Color(0xFFCCCCCC),
              thickness: 3,
              height: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- TAB BAR ----------------
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFFF47C20),
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: const [
          Tab(text: 'Details'),
          Tab(text: 'Menu'),
          Tab(text: 'Services'),
        ],
      ),
    );
  }

  // ---------------- FOOTER ----------------
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Starting from',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Rs. 15,000/Event',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF47C20),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF47C20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: InkWell(
                  onTap: (){
                    Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BasicDetailsScreen()),
            );
                  },
                  child: const Text(
                    'Select Package',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- DETAILS TAB ----------------
  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      child: Container(
        color: Color(0xFFF0F0F0),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Location',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(0),
                child: Image.asset(
                  'assets/images/googlemap 2.png',
                  width: 350,
                  height: 500,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ---------------- MENU TAB ----------------
  Widget _buildMenuTab() {
    return Container(
      color: Color(0xFFF0F0F0),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMenuItem('Chicken Cheese Paratha Roll', 'Rs. 400/Serving',
              isAvailable: true),
          _buildMenuItem('Chicken Biryani Special', 'Rs. 400/Serving',
              isAvailable: true),
          _buildMenuItem('Beef Kebab Platter', 'Sold Out', isAvailable: false),
          _buildMenuItem('Vegetable Spring Rolls', 'Rs. 400/Serving',
              isAvailable: true),

          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String name, String price,
      {required bool isAvailable}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            child: Image.asset('assets/images/karahi.png'),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "",
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 3),
                Text(
                  "It’s very delicious with creamy Chicken.",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          Text(
            price,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isAvailable ? const Color(0xFFF47C20) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- SERVICES TAB ----------------
  Widget _buildServicesTab() {
    return Container(
      color: Color(0xFFF0F0F0),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildServiceItem('Premium Catering', 'Rs. 5000',
              'Full-service dinner & dessert.'),
          _buildServiceItem('Event Photography', 'Rs. 8000',
              'Covers photography for the entire event'),
          _buildServiceItem('Stage Decoration', 'Rs. 3000',
              'Includes floral and lighting setup'),
          _buildServiceItem('Sound System', 'Rs. 2500',
              'Professional sound & mic setup'),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildServiceItem(
      String name, String price, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.camera_enhance_outlined,
              color: Color(0xFFF47C20), size: 30),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style:
                      const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          Text(
            price,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF47C20),
            ),
          ),
        ],
      ),
    );
  }
}
