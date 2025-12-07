import 'package:flutter/material.dart';
import 'package:venuemate_system/Utils/app_navigation.dart';
import 'package:venuemate_system/Screens/SystemAdmin/manage_hall_details.dart';

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
      "name": "Grand Palace Hall with a very long name to test overflow",
      "owner": "Usman Ghani",
      "status": "Approved",
      "image":
          "https://images.unsplash.com/photo-1519167758481-83f550bb49b3?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          "Manage All Halls",
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1100;
          final padding = isDesktop ? 40.0 : 16.0;

          return Column(
            children: [
              Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(padding, 10, padding, 20),
                child: Column(
                  children: [
                    _buildSearchBar(isDesktop),
                    const SizedBox(height: 20),
                    _buildFilterSection(isDesktop),
                  ],
                ),
              ),

              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.all(padding),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 500,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,

                    childAspectRatio: constraints.maxWidth < 600 ? 2.6 : 3.0,
                    mainAxisExtent: 140,
                  ),
                  itemCount: _halls.length,
                  itemBuilder: (context, index) {
                    final hall = _halls[index];
                    return HallManagementCard(
                      name: hall['name'],
                      owner: hall['owner'],
                      status: hall['status'],
                      imageUrl: hall['image'],
                      onManageTap: () {
                        AppNavigation.push(
                          context,
                          ManageHallDetailsScreen(hall: hall),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(bool isDesktop) {
    return Center(
      child: Container(
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
          decoration: InputDecoration(
            hintText: "Search Halls...",
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(bool isDesktop) {
    final filters = ["All", "Approved", "Disabled"];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: filters.map((filter) => _buildFilterTab(filter)).toList(),
    );
  }

  Widget _buildFilterTab(String text) {
    bool isActive = _selectedFilter == text;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = text),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFEA845) : Colors.grey[100],
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isActive ? Colors.transparent : Colors.grey.shade300,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFFFEA845).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w600,
            fontSize: 14,
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onManageTap,
            child: Row(
              children: [
                Container(
                  width: 130,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: Color(0xFFEEEEEE))),
                  ),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3436),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Owner: $owner",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isApproved
                                      ? const Color(0xFFE6F7ED)
                                      : const Color(0xFFFFF0F1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: isApproved
                                        ? const Color(0xFF00B85E)
                                        : const Color(0xFFD92D20),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    "Manage",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 14,
                                    color: Colors.grey[700],
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
        ),
      ),
    );
  }
}
