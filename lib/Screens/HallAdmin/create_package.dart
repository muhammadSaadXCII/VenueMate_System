import 'package:flutter/material.dart';

class CreatePackageScreen extends StatefulWidget {
  const CreatePackageScreen({super.key});

  @override
  State<CreatePackageScreen> createState() => _CreatePackageScreenState();
}

class _CreatePackageScreenState extends State<CreatePackageScreen> {
  int _currentStep = 0;

  final List<Map<String, dynamic>> _stepData = [
    {'title': 'Package Details', 'number': 1},
    {'title': 'Items & Services', 'number': 2},
    {'title': 'Review', 'number': 3},
  ];

  void _nextStep() {
    if (_currentStep < 2) setState(() => _currentStep++);
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
  }

  Widget _buildStepIndicatorWithTabs() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Row(
                children: _stepData.asMap().entries.map((entry) {
                  int idx = entry.key;
                  Map<String, dynamic> step = entry.value;
                  final isActive = idx == _currentStep;

                  return Expanded(
                    child: Center(
                      child: Text(
                        step['title'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isActive ? Colors.black : Colors.grey[400],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(_stepData.length, (index) {
                  final stepNumber = index + 1;
                  final isActive = index == _currentStep;
                  final isCompleted = index < _currentStep;

                  return Expanded(
                    child: Column(
                      children: [
                        Container(
                          height: 4,
                          margin: EdgeInsets.only(
                            right: index < _stepData.length - 1 ? 4 : 0,
                          ),
                          decoration: BoxDecoration(
                            color: isActive || isCompleted
                                ? const Color(0xFFF97316)
                                : const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? const Color(0xFF10B981)
                                : isActive
                                ? const Color(0xFFF97316)
                                : Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 14,
                                  )
                                : Text(
                                    '$stepNumber',
                                    style: TextStyle(
                                      color: isActive
                                          ? Colors.white
                                          : Colors.grey[600],
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 700;

    final List<Widget> steps = [
      PackageDetailsStep(isDesktop: isDesktop),
      const ItemsServicesStep(),
      ReviewSaveStep(onEdit: _goToStep, isDesktop: isDesktop),
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
          _buildStepIndicatorWithTabs(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
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
                                  child: SizedBox(
                                    height: 50,
                                    child: OutlinedButton(
                                      onPressed: _prevStep,
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Colors.grey,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        foregroundColor: Colors.black87,
                                      ),
                                      child: const Text(
                                        "Previous",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: _currentStep > 0 ? 10 : 0,
                                ),
                                child: SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _nextStep,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF58529),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      "Next",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PackageDetailsStep extends StatelessWidget {
  final bool isDesktop;
  const PackageDetailsStep({super.key, required this.isDesktop});

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

        const RegistrationTextField(
          label: "Package Name",
          hintText: "e.g. Wedding Gold Package",
        ),

        const RegistrationTextField(
          label: "Description",
          hintText: "Describe what makes this package special...",
          maxLines: 5,
        ),

        const Text(
          "Guest Capacity",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildSimpleField("Min Guest")),
            const SizedBox(width: 20),
            Expanded(child: _buildSimpleField("Max Guest")),
          ],
        ),
        const SizedBox(height: 16),

        const RegistrationTextField(
          label: "Total Price (Rs.)",
          hintText: "Enter Price",
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildSimpleField(String hint) {
    return TextFormField(
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
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
  ];

  final List<Map<String, String>> _allServices = [
    {"title": "Premium Catering", "price": "5000"},
    {"title": "Event Photography", "price": "5000"},
    {"title": "DJ & Sound System", "price": "8000"},
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
    final visibleMenuItems = _isMenuExpanded
        ? _allMenuItems
        : _allMenuItems.take(2).toList();
    final visibleServices = _isServicesExpanded
        ? _allServices
        : _allServices.take(2).toList();

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
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        _buildSelectionContainer(
          items: visibleMenuItems,
          isExpanded: _isMenuExpanded,
          onToggleExpand: () =>
              setState(() => _isMenuExpanded = !_isMenuExpanded),
          expandLabel: _isMenuExpanded
              ? "View Less Items"
              : "View more Items...",
        ),

        const SizedBox(height: 25),

        const Text(
          "Select Additional Services",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        _buildSelectionContainer(
          items: visibleServices,
          isExpanded: _isServicesExpanded,
          onToggleExpand: () =>
              setState(() => _isServicesExpanded = !_isServicesExpanded),
          expandLabel: _isServicesExpanded
              ? "View Less Services"
              : "View more Services...",
          isService: true,
        ),
      ],
    );
  }

  Widget _buildSelectionContainer({
    required List<Map<String, String>> items,
    required bool isExpanded,
    required VoidCallback onToggleExpand,
    required String expandLabel,
    bool isService = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...items.asMap().entries.map((entry) {
            int idx = entry.key;
            var item = entry.value;
            bool isLast = idx == items.length - 1;
            return Column(
              children: [
                _buildSelectableItem(
                  title: item["title"]!,
                  price: item["price"]!,
                  priceUnit: isService ? "" : item["priceUnit"]!,
                ),
                if (!isLast) const Divider(height: 20),
              ],
            );
          }),
          const SizedBox(height: 15),
          GestureDetector(
            onTap: onToggleExpand,
            child: Text(
              expandLabel,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              gradient: isAdded
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
  final bool isDesktop;
  const ReviewSaveStep({
    super.key,
    required this.onEdit,
    required this.isDesktop,
  });

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

        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildSummaryCard()),
              const SizedBox(width: 20),
              Expanded(child: _buildIncludesCard()),
            ],
          )
        else
          Column(
            children: [
              _buildSummaryCard(),
              const SizedBox(height: 20),
              _buildIncludesCard(),
            ],
          ),

        const SizedBox(height: 40),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Package Created Successfully!")),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF58529),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Create Package",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return _ReviewCard(
      title: "Package Summary",
      stepIndex: 0,
      onEdit: onEdit,
      children: const [
        _ReviewRow(
          icon: Icons.card_giftcard,
          label: "Package Name",
          value: "Exclusive Birthday Bundle",
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
          value: "Lorem ipsum dolor sit amet...",
        ),
      ],
    );
  }

  Widget _buildIncludesCard() {
    return _ReviewCard(
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

class RegistrationTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextInputType? keyboardType;
  final int maxLines;
  final TextEditingController? controller;

  const RegistrationTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.keyboardType,
    this.maxLines = 1,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFFF97316),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              return null;
            },
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
