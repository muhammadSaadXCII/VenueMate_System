import 'package:flutter/material.dart';

// Constant for the primary color requested
const Color kPrimaryColor = Color(0xFFF47C20);

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FilterSearchScreen(),
  ));
}

class FilterSearchScreen extends StatefulWidget {
  const FilterSearchScreen({super.key});

  @override
  State<FilterSearchScreen> createState() => _FilterSearchScreenState();
}

class _FilterSearchScreenState extends State<FilterSearchScreen> {
  // --- State Variables ---
  String _locationType = 'Current'; // 'Current' or 'Custom'
  RangeValues _priceRange = const RangeValues(20000, 150000);
  double _guestCount = 250;
  
  final List<String> _availableServices = [
    'Catering',
    'Photography',
    'Decoration',
    'Music System',
    'Valet Parking',
    'Air Conditioned',
    'WiFi',
    'Stage Lighting'
  ];
  
  final List<String> _selectedServices = ['Catering', 'Decoration'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // Clean off-white bg
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Filter Search",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                // Reset Logic
                _priceRange = const RangeValues(0, 300000);
                _guestCount = 100;
                _selectedServices.clear();
                _locationType = 'Current';
              });
            },
            child: const Text(
              "Reset",
              style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w600),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. Location Section ---
                  _buildSectionTitle("Location"),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildLocationTab(
                            "Nearby / Current",
                            Icons.my_location,
                            isActive: _locationType == 'Current',
                            onTap: () => setState(() => _locationType = 'Current'),
                          ),
                        ),
                        Expanded(
                          child: _buildLocationTab(
                            "Search Area",
                            Icons.map_outlined,
                            isActive: _locationType == 'Custom',
                            onTap: () => setState(() => _locationType = 'Custom'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Animated Search Bar if 'Custom' is selected
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Container(
                      margin: const EdgeInsets.only(top: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: "Enter area, city or zip code",
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    crossFadeState: _locationType == 'Custom' ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),

                  const SizedBox(height: 30),

                  // --- 2. Guest Capacity Section ---
                  _buildSectionTitle("No. of Guests"),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Up to", style: TextStyle(color: Colors.grey[600])),
                            Text(
                              "${_guestCount.round()} Guests",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kPrimaryColor),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: kPrimaryColor,
                            inactiveTrackColor: Colors.orange.withOpacity(0.1),
                            thumbColor: Colors.white,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12, elevation: 4),
                            overlayColor: kPrimaryColor.withOpacity(0.1),
                          ),
                          child: Slider(
                            value: _guestCount,
                            min: 50,
                            max: 2000,
                            divisions: 39,
                            onChanged: (val) => setState(() => _guestCount = val),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- 3. Price Range Section ---
                  _buildSectionTitle("Price Range"),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Rs. ${_priceRange.start.round()}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text("Rs. ${_priceRange.end.round()}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: kPrimaryColor,
                            inactiveTrackColor: Colors.orange.withOpacity(0.1),
                            thumbColor: Colors.white,
                            rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 12, elevation: 4),
                            overlayColor: kPrimaryColor.withOpacity(0.1),
                          ),
                          child: RangeSlider(
                            values: _priceRange,
                            min: 0,
                            max: 500000,
                            divisions: 100,
                            labels: RangeLabels(
                              "Rs. ${_priceRange.start.round()}",
                              "Rs. ${_priceRange.end.round()}",
                            ),
                            onChanged: (val) => setState(() => _priceRange = val),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- 4. Additional Services Section ---
                  _buildSectionTitle("Add Services"),
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _availableServices.map((service) {
                      final isSelected = _selectedServices.contains(service);
                      return FilterChip(
                        label: Text(service),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _selectedServices.add(service);
                            } else {
                              _selectedServices.remove(service);
                            }
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: kPrimaryColor.withOpacity(0.15),
                        checkmarkColor: kPrimaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? kPrimaryColor : Colors.black54,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? kPrimaryColor : Colors.grey.shade300,
                          ),
                        ),
                        showCheckmark: true,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
          
          // --- Bottom Action Button ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // Apply Logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 5,
                  shadowColor: kPrimaryColor.withOpacity(0.4),
                ),
                child: const Text(
                  "Apply Filters",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildLocationTab(String text, IconData icon, {required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isActive ? kPrimaryColor : Colors.grey),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: isActive ? Colors.black : Colors.grey,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}