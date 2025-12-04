import 'package:flutter/material.dart';

class VenueDetailsScreen extends StatefulWidget {
  const VenueDetailsScreen({Key? key}) : super(key: key);

  @override
  State<VenueDetailsScreen> createState() => _VenueDetailsScreenState();
}

class _VenueDetailsScreenState extends State<VenueDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFavorite = false;
  int _currentImageIndex = 0;
  final int _totalImages = 5;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
          // 1. Header with Image, Back Button & Like Button
          _buildHeader(),

          // 2. Venue Title and Contact Info
          _buildVenueTitleSection(),

          // 3. Tab Bar
          _buildTabBar(),

          // 4. Tab Content (Scrollable Area)
          // The Footer is now INSIDE these tabs, so it scrolls with them.
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildMenuTab(),
                _buildServicesTab(),
                _buildPackagesTab(),
                _buildReviewsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Header Section ---
  Widget _buildHeader() {
    return Stack(
      children: [
        // Venue Image
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
        // Top Bar
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
        // Image Counter
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

  // --- Venue Title Section ---
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
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
              ),
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

        // Contact row
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

        // Divider at bottom
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


  // --- Tab Bar ---
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
        unselectedLabelStyle: const TextStyle(fontSize: 14),
        tabs: const [
          Tab(text: 'Details'),
          Tab(text: 'Menu'),
          Tab(text: 'Services'),
          Tab(text: 'Packages'),
          Tab(text: 'Reviews'),
        ],
      ),
    );
  }

  // --- Shared Footer Widget (Scrollable) ---
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
            mainAxisSize: MainAxisSize.min, // Prevents overflow
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
            height: 40, // Fits well inside footer
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF47C20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Book me',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}


  // --- Details Tab ---
  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      child: Container(
        color: Color(0xFFF0F0F0),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // About Section
            const Text(
              'About',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            // Location Section
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
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.map, size: 60, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Footer Added Here
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // --- Menu Tab ---
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

        // Footer Added Here
        _buildFooter(),
      ],
    ),
  );
}


  Widget _buildMenuItem(String name, String price, {required bool isAvailable}) {
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
        // --- Image ---
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
          ),
          child: Image.asset('assets/images/karahi.png'),
        ),

        const SizedBox(width: 12),

        // --- Text Section (Aligned perfectly left) ---
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Name
              Text(
                name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 3),

              // Small Description
              const Text(
                "It’s very delicious with creamy Chicken.",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),

        // --- Price (right aligned) ---
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



  // --- Services Tab ---
 Widget _buildServicesTab() {
  return Container(
     color: Color(0xFFF0F0F0),
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildServiceItem('Premium Catering', 'Rs. 5000', 'Full-service dinner & dessert.'),
        _buildServiceItem('Event Photography', 'Rs. 8000', 'Covers photography for the entire event'),
        _buildServiceItem('Stage Decoration', 'Rs. 3000', 'Includes floral and lighting setup'),
        _buildServiceItem('Sound System', 'Rs. 2500', 'Professional sound & mic setup'),
        // Footer Added Here
        _buildFooter(),
      ],
    ),
  );
}

// Updated Service Item with small description text
Widget _buildServiceItem(String name, String price, String description) {
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
        // Icon/Image
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            // color: const Color(0xFFF47C20).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.camera_enhance_outlined,
            color: Color(0xFFF47C20),
            size: 30,
          ),
        ),

        const SizedBox(width: 12),

        // Name + Description
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service Name
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 3),

              // Small Description
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),

        // Price
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


  // --- Packages Tab ---
  Widget _buildPackagesTab() {
    return Container(
        color: Color(0xFFF0F0F0),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPackageCard(),
          _buildPackageCard(),
          // Footer Added Here
          _buildFooter(),
        ],
      ),
    );
  }

 Widget _buildPackageCard() {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: Stack(
      children: [
        // ❤️ Favorite Icon (Top Right)
        Positioned(
          top: 15,
          right: 8,
          child: CircleAvatar(
            backgroundColor: Colors.white,
            radius: 16,
            child: const Icon(
              Icons.favorite_border,
              color: Colors.red,
              size: 25,
            ),
          ),
        ),

        // 🌟 Main Content
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4), // Small spacing under the heart icon

              const Text(
                'Exclusive Birthday Celebration Bundle',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
          


              const SizedBox(height: 2),
    const Divider(
  color:Color(0xFFCCCCCC),
  thickness: 3,
  indent: 0,
  endIndent: 0,
),
              const Text(
                'Includes:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              

              const SizedBox(height: 2),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildIncludeIcon('assets/images/guest.png', '200 Guests \n Capacity'),
                  _buildIncludeIcon('assets/images/menuitem.png', '12 Menu Items'),
                  _buildIncludeIcon('assets/images/services.png', '4 Services'),
                ],
              ),

              const SizedBox(height: 12),

              const Text(
                'Rs. 20,000',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF47C20),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}



  Widget _buildIncludeIcon(String imagePath, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            // color: const Color(0xFFF47C20).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Image.asset(
            imagePath,
            width: 30,
            height: 30,
            color: const Color(0xFFF47C20),
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.fastfood,
                color: Color(0xFFF47C20),
                size: 20,
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // --- Reviews Tab ---
  Widget _buildReviewsTab() {
    return Container(
      color:   Color(0xFFF0F0F0),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildReviewCard('Muhammad Ahmad', '4.0',
              'yeh asalaan wala event mana hay menu bohot parta hay location bohot achi ha'),
          _buildReviewCard('Ali Ahmed', '5.0',
              'Great venue for weddings and events. Staff was very cooperative and helpful.'),
          _buildReviewCard('Sarah Khan', '4.5',
              'Beautiful hall with excellent services. Highly recommended!'),
          // Footer Added Here
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildReviewCard(String name, String rating, String review) {
  double ratingValue = double.tryParse(rating) ?? 0;

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFF47C20),
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),

                  Row(
                    children: [
                      Text(
                        rating,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),

                      // ⭐ Generate Stars Dynamically
                      Row(
                        children: List.generate(
                          ratingValue.round(),
                          (index) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Text(
          review,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}
    }