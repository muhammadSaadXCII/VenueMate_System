import 'package:flutter/material.dart';
import 'package:venuemate_system/Widgets/gradient_button.dart';

class CreatePackageScreen extends StatefulWidget {
  const CreatePackageScreen({super.key});

  @override
  State<CreatePackageScreen> createState() => _CreatePackageScreenState();
}

class _CreatePackageScreenState extends State<CreatePackageScreen> {
  int _currentStep = 0;

  void _nextStep() {
    if (_currentStep < 2) setState(() => _currentStep++);
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> steps = [
      const PackageDetailsStep(),
      const ItemsServicesStep(),
      ReviewSaveStep(onEdit: _goToStep),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (_currentStep > 0) {
              _prevStep();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        centerTitle: true,
        title: const Text(
          "Create Package",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              children: List.generate(3, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color:
                          index == _currentStep
                              ? const Color(0xFFF58529)
                              : Colors.black,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  steps[_currentStep],

                  const SizedBox(height: 30),

                  if (_currentStep < 2)
                    Row(
                      children: [
                        if (_currentStep > 0)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: GradientButton(
                                text: "Prev",
                                onTap: _prevStep,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: _currentStep > 0 ? 10 : 0,
                            ),
                            child: GradientButton(
                              text: "Next",
                              onTap: _nextStep,
                            ),
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
    );
  }
}

class PackageDetailsStep extends StatelessWidget {
  const PackageDetailsStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Package Details",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          "Enter the name, price, and details.",
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 25),

        const CustomTextField(
          label: "Package Name",
          hint: "Enter your Full Name",
        ),

        const Text(
          "Hall Description",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          maxLines: 5,
          decoration: InputDecoration(
            hintText: "Enter your Hall Description",
            hintStyle: TextStyle(
              color: Colors.grey[300],
              fontWeight: FontWeight.bold,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black),
            ),
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          "Guest Capacity",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildSmallInput("Min Guest")),
            const SizedBox(width: 20),
            Expanded(child: _buildSmallInput("Max Guest")),
          ],
        ),
        const SizedBox(height: 20),

        const CustomTextField(label: "Total Price (Rs.)", hint: "Enter Price"),
      ],
    );
  }

  Widget _buildSmallInput(String hint) {
    return TextFormField(
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey[300],
          fontWeight: FontWeight.bold,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

class ItemsServicesStep extends StatefulWidget {
  const ItemsServicesStep({super.key});

  @override
  State<ItemsServicesStep> createState() => _ItemsServicesStepState();
}

class _ItemsServicesStepState extends State<ItemsServicesStep> {
  bool _isMenuExpanded = false;
  bool _isServicesExpanded = false;

  final Set<String> _selectedItems = {};

  final List<Map<String, String>> _allMenuItems = [
    {
      "title": "Chicken Cheese Paratha Roll",
      "price": "400",
      "priceUnit": "Serving",
    },
    {"title": "White Chicken Karahi", "price": "600", "priceUnit": "Serving"},
    {"title": "Mutton Korma Special", "price": "900", "priceUnit": "Serving"},
    {"title": "Seekh Kabab Platter", "price": "500", "priceUnit": "Serving"},
    {"title": "Special Zarda Rice", "price": "300", "priceUnit": "Serving"},
  ];

  final List<Map<String, String>> _allServices = [
    {"title": "Premium Catering", "price": "5000"},
    {"title": "Event Photography", "price": "5000"},
    {"title": "DJ & Sound System", "price": "8000"},
    {"title": "Valet Parking", "price": "3000"},
  ];

  void _toggleSelection(String title) {
    setState(() {
      if (_selectedItems.contains(title)) {
        _selectedItems.remove(title);
      } else {
        _selectedItems.add(title);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleMenuItems =
        _isMenuExpanded ? _allMenuItems : _allMenuItems.take(2).toList();
    final visibleServices =
        _isServicesExpanded ? _allServices : _allServices.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Items & Services",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          "Choose items and services for this bundle.",
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 25),

        const Text(
          "Select Menu Items",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...visibleMenuItems.asMap().entries.map((entry) {
                int idx = entry.key;
                var item = entry.value;
                bool isLast = idx == visibleMenuItems.length - 1;

                return Column(
                  children: [
                    _buildSelectableItem(
                      title: item["title"]!,
                      price: item["price"]!,
                      priceUnit: item["priceUnit"]!,
                    ),
                    if (!isLast) const Divider(height: 20),
                  ],
                );
              }),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isMenuExpanded = !_isMenuExpanded;
                  });
                },
                child: Text(
                  _isMenuExpanded ? "View Less Items" : "View more Items....",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 25),

        const Text(
          "Select Additional Services",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...visibleServices.asMap().entries.map((entry) {
                int idx = entry.key;
                var service = entry.value;
                bool isLast = idx == visibleServices.length - 1;

                return Column(
                  children: [
                    _buildSelectableItem(
                      title: service["title"]!,
                      price: service["price"]!,
                    ),
                    if (!isLast) const Divider(height: 20),
                  ],
                );
              }),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isServicesExpanded = !_isServicesExpanded;
                  });
                },
                child: Text(
                  _isServicesExpanded
                      ? "View Less Services"
                      : "View more Services....",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectableItem({
    required String title,
    required String price,
    String priceUnit = "",
  }) {
    bool isAdded = _selectedItems.contains(title);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              (priceUnit.isEmpty) ? "Rs. $price" : "Rs. $price/$priceUnit",
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),

        GestureDetector(
          onTap: () => _toggleSelection(title),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 80,
            height: 35,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient:
                  isAdded
                      ? null
                      : const LinearGradient(
                        colors: [Color(0xFFF47C20), Color(0xFFFFD166)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
              color: isAdded ? Colors.redAccent : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isAdded ? "Remove" : "Add",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ReviewSaveStep extends StatelessWidget {
  final Function(int) onEdit;
  const ReviewSaveStep({super.key, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Review & Save",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          "Review your new package and save it.",
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 25),

        _ReviewCard(
          title: "Package Summary",
          stepIndex: 0,
          onEdit: onEdit,
          children: const [
            _ReviewRow(
              icon: Icons.card_giftcard,
              label: "Package Name",
              value: "Exclusive Birthday Celebration Bundle",
            ),
            _ReviewRow(
              icon: Icons.monetization_on_outlined,
              label: "Total Price",
              value: "Rs. 30,000",
              valueColor: Color(0xFFF58529),
            ),
            _ReviewRow(
              icon: Icons.description_outlined,
              label: "Description",
              value: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
            ),
          ],
        ),

        const SizedBox(height: 20),

        _ReviewCard(
          title: "Includes",
          stepIndex: 1,
          onEdit: onEdit,
          children: [
            const _ReviewRow(
              icon: Icons.groups_outlined,
              label: "Capacity",
              value: "300-800 Guests",
            ),
            const Divider(height: 24),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    size: 18,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "MENU ITEMS",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 46),
              child: Column(
                children: [
                  _itemRow("Chicken Cheese Paratha", "Rs. 400"),
                  _itemRow("White Chicken Karahi", "Rs. 600"),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.room_service_outlined,
                    size: 18,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "SERVICES",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 46),
              child: Column(
                children: [
                  _itemRow("Premium Catering", "Rs. 5000"),
                  _itemRow("Event Photography", "Rs. 5000"),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 30),

        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Package Created Successfully!")),
            );
            Navigator.pop(context);
          },
          child: Container(
            width: double.infinity,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF58529), Color(0xFFFEDA77)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              "Create Package",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _itemRow(String name, String price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          Text(
            price,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFFF58529),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  const CustomTextField({super.key, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey[300],
                fontWeight: FontWeight.bold,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String title;
  final int stepIndex;
  final Function(int) onEdit;
  final List<Widget> children;

  const _ReviewCard({
    required this.title,
    required this.stepIndex,
    required this.onEdit,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: () => onEdit(stepIndex),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: const [
                      Text(
                        "Edit",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF58529),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.edit, size: 12, color: Color(0xFFF58529)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: Colors.grey[600]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.black87,
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
