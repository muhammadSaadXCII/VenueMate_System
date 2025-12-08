import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:venuemate_system/Screens/HallAdmin/add_menu_item_sheet.dart';

class ManageMenuScreen extends StatefulWidget {
  const ManageMenuScreen({super.key});

  @override
  State<ManageMenuScreen> createState() => _ManageMenuScreenState();
}

class _ManageMenuScreenState extends State<ManageMenuScreen> {
  final List<Map<String, dynamic>> _menuItems = [
    {
      "name": "Chicken Cheese Paratha Roll",
      "price": "400",
      "description": "It's very delicious with creamy Chicken.",
      "image":
          "https://img.freepik.com/free-photo/side-view-shawarma-with-fried-potatoes-board-cookware_176474-3215.jpg",
    },
    {
      "name": "White Chicken Karahi",
      "price": "1200",
      "description": "Traditional creamy white karahi with naan.",
      "image":
          "https://img.freepik.com/free-photo/side-view-shawarma-with-fried-potatoes-board-cookware_176474-3215.jpg",
    },
    {
      "name": "Seekh Kabab Platter",
      "price": "800",
      "description": "Juicy beef kebabs served with chutney.",
      "image":
          "https://img.freepik.com/free-photo/side-view-shawarma-with-fried-potatoes-board-cookware_176474-3215.jpg",
    },
    {
      "name": "Special Zarda",
      "price": "350",
      "description": "Traditional sweet rice dessert.",
      "image":
          "https://img.freepik.com/free-photo/side-view-shawarma-with-fried-potatoes-board-cookware_176474-3215.jpg",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
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
          "Manage Menu",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1100;
          final isTablet =
              constraints.maxWidth >= 700 && constraints.maxWidth < 1100;
          int crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const AddMenuItemSheet(),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            height: 55,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE0C2),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  color: Color(0xFFF47C20),
                                  size: 26,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "Add New Menu Item",
                                  style: TextStyle(
                                    color: Color(0xFFF47C20),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      "Menu Items",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Expanded(
                      child: isDesktop || isTablet
                          ? GridView.builder(
                              itemCount: _menuItems.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 20,
                                    mainAxisSpacing: 20,

                                    mainAxisExtent: 110,
                                  ),
                              itemBuilder: (context, index) {
                                return _buildMenuItem(index);
                              },
                            )
                          : ListView.separated(
                              itemCount: _menuItems.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                return _buildMenuItem(index);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuItem(int index) {
    final item = _menuItems[index];

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Slidable(
        key: ValueKey(index),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (context) {},
              backgroundColor: Colors.blue.shade50,
              foregroundColor: Colors.blue,
              icon: Icons.edit,
              label: 'Edit',
              borderRadius: BorderRadius.circular(12)
            ),
            SlidableAction(
              onPressed: (context) {},
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              icon: Icons.delete,
              label: 'Delete',
              borderRadius: BorderRadius.circular(12)
            ),
          ],
        ),
        child: MenuItemCard(
          name: item['name'],
          price: item['price'],
          description: item['description'],
          imageUrl: item['image'],
        ),
      ),
    );
  }
}

class MenuItemCard extends StatelessWidget {
  final String name;
  final String price;
  final String description;
  final String imageUrl;

  const MenuItemCard({
    super.key,
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(width: 80, height: 80, color: Colors.grey[200]),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "Rs. $price / Serving",
                  style: const TextStyle(
                    color: Color(0xFFF47C20),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
