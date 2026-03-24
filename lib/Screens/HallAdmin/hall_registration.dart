import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:venuemate_system/Utils/app_navigation.dart';
import 'package:venuemate_system/Screens/HallAdmin/pending_review.dart';
import 'package:venuemate_system/Screens/HallAdmin/add_menu_item_sheet.dart';
import 'package:venuemate_system/Screens/HallAdmin/location_picker_sheet.dart';
import 'package:venuemate_system/Screens/HallAdmin/add_vendor_service_sheet.dart';

import '../../Widgets/add_new_button.dart';
import '../../Widgets/menu_item_card.dart';
import '../../Widgets/service_card.dart';

class HallRegistrationScreen extends StatefulWidget {
  const HallRegistrationScreen({super.key});

  @override
  State<HallRegistrationScreen> createState() => _HallRegistrationScreenState();
}

class _HallRegistrationScreenState extends State<HallRegistrationScreen> {
  int _currentStep = 0;

  final List<Map<String, dynamic>> _stepData = [
    {'title': 'Basic Details', 'number': 1},
    {'title': 'Hall Details', 'number': 2},
    {'title': 'Uploads & Payout', 'number': 3},
    {'title': 'Menu & Services', 'number': 4},
    {'title': 'Review', 'number': 5},
  ];

  void _nextStep() {
    if (_currentStep < 4) setState(() => _currentStep++);
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  void _jumpToStep(int stepIndex) {
    setState(() => _currentStep = stepIndex);
  }

  Widget _buildStepIndicatorWithTabs() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Row(
                children:
                    _stepData.asMap().entries.map((entry) {
                      int idx = entry.key;
                      Map<String, dynamic> step = entry.value;
                      final isActive = idx == _currentStep;

                      return Expanded(
                        child: Center(
                          child: Text(
                            step['title'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  isActive ? FontWeight.w700 : FontWeight.w400,
                              color: isActive ? Colors.black : Colors.grey[400],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                            color:
                                isActive || isCompleted
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
                            color:
                                isCompleted
                                    ? const Color(0xFF10B981)
                                    : isActive
                                    ? const Color(0xFFF97316)
                                    : Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child:
                                isCompleted
                                    ? Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 14,
                                    )
                                    : Text(
                                      '$stepNumber',
                                      style: TextStyle(
                                        color:
                                            isActive
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
          "Hall Registration",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final List<Widget> stepsContent = [
            BasicDetailsStep(),
            HallDetailsStep(),
            UploadsPayoutsStep(),
            MenuServicesStep(),
            ReviewSubmitStep(onEditStep: _jumpToStep),
          ];

          return Column(
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
                          stepsContent[_currentStep],

                          const SizedBox(height: 30),

                          if (_currentStep < 4)
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
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                                          backgroundColor: const Color(
                                            0xFFF47C20,
                                          ),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
          );
        },
      ),
    );
  }
}

class BasicDetailsStep extends StatelessWidget {
  const BasicDetailsStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: "Basic Details",
          subtitle: "Please fill in your contact Details.",
        ),
        const SizedBox(height: 24),
        GridRow(
          children: const [
            RegistrationTextField(
              label: "Full Name",
              hintText: "Enter your Full Name",
            ),
            RegistrationTextField(
              label: "Phone Number",
              hintText: "+92 3**_*******",
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        GridRow(
          children: const [
            RegistrationTextField(
              label: "Email",
              hintText: "Enter your Email",
              keyboardType: TextInputType.emailAddress,
            ),
            RegistrationTextField(
              label: "CNIC",
              hintText: "CNIC in format *****-*******-*",
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          "CNIC Photos",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: const [
            Expanded(child: UploadBox(label: "Front Side CNIC")),
            SizedBox(width: 15),
            Expanded(child: UploadBox(label: "Back Side CNIC")),
          ],
        ),
      ],
    );
  }
}

class HallDetailsStep extends StatelessWidget {
  const HallDetailsStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: "Hall Details",
          subtitle: "Please fill in Details for your Hall",
        ),
        const SizedBox(height: 24),
        GridRow(
          children: const [
            RegistrationTextField(
              label: "Hall Name",
              hintText: "Enter your Hall Name",
            ),
            RegistrationTextField(
              label: "Hall Rent (Rs.)",
              hintText: "Enter Hall's Rent",
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        const Text(
          "Hall Location",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Your Hall Location",
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
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () async {
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const LocationPickerSheet(),
                );
              },
              child: Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF47C20), Color(0xFFFFD166)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.my_location, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
            Expanded(child: _buildSimpleField("Min")),
            const SizedBox(width: 20),
            Expanded(child: _buildSimpleField("Max")),
          ],
        ),
        const SizedBox(height: 16),
        const RegistrationTextField(
          label: "Hall Description",
          hintText: "Enter your Hall Description",
          maxLines: 5,
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

class UploadsPayoutsStep extends StatefulWidget {
  const UploadsPayoutsStep({super.key});

  @override
  State<UploadsPayoutsStep> createState() => _UploadsPayoutsStepState();
}

class _UploadsPayoutsStepState extends State<UploadsPayoutsStep> {
  int _photoBoxCount = 2;
  void _addPhotoBox() => setState(() => _photoBoxCount++);
  void _removePhotoBox() {
    if (_photoBoxCount > 2) setState(() => _photoBoxCount--);
  }

  @override
  Widget build(BuildContext context) {
    double boxWidth = 140;
    double boxHeight = 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: "Uploads & Payouts",
          subtitle: "Upload your hall photos, verification documents...",
        ),
        const SizedBox(height: 24),
        const Text(
          "Hall Photos",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (int i = 0; i < _photoBoxCount; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: boxWidth,
                    height: boxHeight,
                    child: Stack(
                      children: [
                        const UploadBox(label: "Upload Photo"),
                        if (i >= 2)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _removePhotoBox,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              GestureDetector(
                onTap: _addPhotoBox,
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey, width: 2),
                  ),
                  child: const Icon(Icons.add, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SectionTitle(
          title: "Payout Details",
          subtitle: "(This information will only be displayed to Customer...)",
        ),
        const SizedBox(height: 16),
        GridRow(
          children: const [
            RegistrationTextField(
              label: "Bank Name",
              hintText: "Enter your Bank Name",
            ),
            RegistrationTextField(
              label: "Bank Account Number",
              hintText: "Enter your Account Number",
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        const SizedBox(height: 10),
        const SectionTitle(
          title: "Business Verification",
          subtitle: "(This information will be used by VenueMate Admin...)",
        ),
        const SizedBox(height: 16),
        Row(
          children: const [
            Expanded(child: UploadBox(label: "NTN TaxPayer file")),
            SizedBox(width: 15),
            Expanded(child: UploadBox(label: "Business License")),
          ],
        ),
      ],
    );
  }
}

class MenuServicesStep extends StatefulWidget {
  const MenuServicesStep({super.key});

  @override
  State<MenuServicesStep> createState() => _MenuServicesStepState();
}

class _MenuServicesStepState extends State<MenuServicesStep> {
  final List<Map<String, String>> _menuItems = [
    {
      "name": "Chicken Cheese Paratha Roll",
      "price": "400",
      "description": "It's very delicious with creamy Chicken.",
    },
  ];
  final List<Map<String, String>> _services = [
    {
      "name": "Premium Catering",
      "price": "5000",
      "description": "Full-service dinner & dessert.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: "Menu & Services",
          subtitle: "Detail the food, beverages, and extra services.",
        ),
        const SizedBox(height: 24),
        const Text(
          "Menu Items",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        ..._menuItems.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Slidable(
              key: ValueKey("menu_${entry.key}"),
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: (context) {},
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue,
                    icon: Icons.edit,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  SlidableAction(
                    onPressed: (context) {
                      setState(() {
                        _menuItems.removeAt(entry.key);
                      });
                    },
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    icon: Icons.delete,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ],
              ),
              child: MenuItemCard(
                name: entry.value["name"]!,
                price: entry.value["price"]!,
                priceUnit: "Serving",
                description: entry.value["description"]!,
                imageUrl:
                    "https://img.freepik.com/free-photo/side-view-shawarma-with-fried-potatoes-board-cookware_176474-3215.jpg",
              ),
            ),
          );
        }),
        const SizedBox(height: 15),
        AddNewButton(
          label: "Add New Menu Item",
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const AddMenuItemSheet(),
            );
          },
        ),
        const SizedBox(height: 32),
        RichText(
          text: TextSpan(
            style: const TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            children: [
              const TextSpan(text: "Additional Services "),
              TextSpan(
                text: "(If Any)",
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ..._services.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Slidable(
              key: ValueKey("service_${entry.key}"),
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: (context) {},
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue,
                    icon: Icons.edit,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  SlidableAction(
                    onPressed: (context) {
                      setState(() {
                        _services.removeAt(entry.key);
                      });
                    },
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    icon: Icons.delete,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ],
              ),
              child: ServiceCard(
                name: entry.value["name"]!,
                price: entry.value["price"]!,
                description: entry.value["description"]!,
              ),
            ),
          );
        }),
        const SizedBox(height: 15),
        AddNewButton(
          label: "Add New Service",
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const AddServiceSheet(),
            );
          },
        ),
      ],
    );
  }
}

class ReviewSubmitStep extends StatefulWidget {
  final Function(int) onEditStep;
  const ReviewSubmitStep({super.key, required this.onEditStep});

  @override
  State<ReviewSubmitStep> createState() => _ReviewSubmitStepState();
}

class _ReviewSubmitStepState extends State<ReviewSubmitStep> {
  bool _isConfirmed = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: "Review & Submit",
          subtitle: "Please review all your information and submit...",
        ),
        const SizedBox(height: 24),

        Column(
          children: [
            _buildBasicDetailsCard(),
            const SizedBox(height: 16),
            _buildHallDetailsCard(),
            const SizedBox(height: 16),
            _buildUploadsCard(),
            const SizedBox(height: 16),
            _buildMenuCard(),
          ],
        ),

        const SizedBox(height: 40),

        GestureDetector(
          onTap: () {
            setState(() {
              _isConfirmed = !_isConfirmed;
            });
          },
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 24,
                width: 24,
                decoration: BoxDecoration(
                  color:
                      _isConfirmed
                          ? const Color(0xFFF47C20)
                          : Colors.transparent,
                  border: Border.all(
                    color: _isConfirmed ? const Color(0xFFF47C20) : Colors.grey,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child:
                    _isConfirmed
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "I confirm that the information provided is accurate.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed:
                _isConfirmed
                    ? () {
                      AppNavigation.pushReplacement(
                        context,
                        PendingReviewScreen(),
                      );
                    }
                    : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF47C20),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              disabledForegroundColor: Colors.grey[600],
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Submit for Verification",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBasicDetailsCard() {
    return _ReviewCard(
      title: "Basic Details",
      stepIndex: 0,
      onEdit: widget.onEditStep,
      children: const [
        _ReviewRow(icon: Icons.person, label: "Name", value: "Rehman Hussain"),
        _ReviewRow(icon: Icons.phone, label: "Phone", value: "+92 3XX XXXXXXX"),
        _ReviewRow(icon: Icons.badge, label: "CNIC", value: "42201-XXXXXXX-X"),
      ],
    );
  }

  Widget _buildHallDetailsCard() {
    return _ReviewCard(
      title: "Hall Details",
      stepIndex: 1,
      onEdit: widget.onEditStep,
      children: const [
        _ReviewRow(
          icon: Icons.store,
          label: "Hall Name",
          value: "Al Rehman Banquet Hall",
        ),
        _ReviewRow(
          icon: Icons.location_on,
          label: "Location",
          value: "Model Colony, Street 12A, Karachi",
        ),
        _ReviewRow(
          icon: Icons.groups,
          label: "Capacity",
          value: "300 - 800 Guests",
        ),
      ],
    );
  }

  Widget _buildUploadsCard() {
    return _ReviewCard(
      title: "Uploads & Payouts",
      stepIndex: 2,
      onEdit: widget.onEditStep,
      children: const [
        _ReviewRow(
          icon: Icons.photo_library,
          label: "Hall Photos",
          value: "4 Images Uploaded",
        ),
        _ReviewRow(
          icon: Icons.assignment,
          label: "Documents",
          value: "Business License, NTN",
        ),
        _ReviewRow(
          icon: Icons.account_balance,
          label: "Bank Info",
          value: "Meezan Bank (**** 1234)",
        ),
      ],
    );
  }

  Widget _buildMenuCard() {
    return _ReviewCard(
      title: "Menu & Services",
      stepIndex: 3,
      onEdit: widget.onEditStep,
      children: [
        const Text(
          "Menu Items",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        _itemRow("Chicken Cheese Paratha", "Rs. 400"),
        _itemRow("White Chicken Karahi", "Rs. 600"),
        const Divider(height: 24),
        const Text(
          "Services",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        _itemRow("Premium Catering", "Rs. 5000"),
        _itemRow("Event Photography", "Rs. 5000"),
      ],
    );
  }

  Widget _itemRow(String name, String price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFF47C20),
            ),
          ),
        ],
      ),
    );
  }
}

class GridRow extends StatelessWidget {
  final List<Widget> children;
  const GridRow({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(children: children);
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

class SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const SectionTitle({super.key, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class UploadBox extends StatelessWidget {
  final String label;
  const UploadBox({super.key, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_upload_outlined,
            size: 30,
            color: Colors.black54,
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black54,
              fontWeight: FontWeight.bold,
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
                          color: Color(0xFFF47C20),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.edit, size: 12, color: Color(0xFFF47C20)),
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
  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.value,
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
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
