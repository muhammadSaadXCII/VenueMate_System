import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:venuemate_system/Screens/HallAdmin/add_menu_item_sheet.dart';
import 'package:venuemate_system/Screens/HallAdmin/add_vendor_service_sheet.dart';
import 'package:venuemate_system/Screens/HallAdmin/location_picker_sheet.dart';
import 'package:venuemate_system/Screens/HallAdmin/pending_review.dart';
import 'package:venuemate_system/Utils/navigation.dart';
import 'package:venuemate_system/Widgets/gradient_button.dart';

class HallRegistrationScreen extends StatefulWidget {
  const HallRegistrationScreen({super.key});

  @override
  State<HallRegistrationScreen> createState() => _HallRegistrationScreenState();
}

class _HallRegistrationScreenState extends State<HallRegistrationScreen> {
  int _currentStep = 0;

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _jumpToStep(int stepIndex) {
    setState(() {
      _currentStep = stepIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> steps = [
      const BasicDetailsStep(),
      const HallDetailsStep(),
      const UploadsPayoutsStep(),
      const MenuServicesStep(),
      ReviewSubmitStep(onEditStep: _jumpToStep),
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
          "Hall Registration",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: List.generate(5, (index) {
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

                  if (_currentStep < 4)
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

class BasicDetailsStep extends StatelessWidget {
  const BasicDetailsStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: "Basic Details",
          subtitle: "Please fill in your contact Details",
        ),
        const SizedBox(height: 20),
        const CustomTextField(label: "Full Name", hint: "Enter your Full Name"),
        const CustomTextField(label: "Phone Number", hint: "+92 3**_*******"),
        const CustomTextField(
          label: "CNIC",
          hint: "CNIC in format *****-*******-*",
        ),
        const SizedBox(height: 10),
        Row(
          children: const [
            Expanded(
              child: UploadBox(label: "Tap to upload your Front Side of CNIC"),
            ),
            SizedBox(width: 15),
            Expanded(
              child: UploadBox(label: "Tap to upload your Back Side of CNIC"),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const CustomTextField(label: "Email", hint: "Enter your Email"),
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
        const SizedBox(height: 20),
        const CustomTextField(label: "Hall Name", hint: "Enter your Hall Name"),

        const Text(
          "Hall Location",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  hintText: "Your Hall Location",
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () async {
                final result = await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const LocationPickerSheet(),
                );
                if (result != null) {
                  debugPrint("Selected Location: ${result['address']}");
                  debugPrint("Coords: ${result['lat']}, ${result['lng']}");
                }
              },
              child: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF47C20), Color(0xFFFFD166)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.my_location, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const CustomTextField(
          label: "Hall Rent (Rs.)",
          hint: "Enter Hall's Rent",
        ),
        const Text(
          "Guest Capacity",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  hintText: "Min Guest",
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontWeight: FontWeight.bold,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  hintText: "Max Guest",
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontWeight: FontWeight.bold,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        const CustomTextField(
          label: "Hall Description",
          hint: "Enter your Hall Description",
          maxLines: 5,
        ),
      ],
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

  void _addPhotoBox() {
    setState(() {
      _photoBoxCount++;
    });
  }

  void _removePhotoBox() {
    if (_photoBoxCount > 2) {
      setState(() {
        _photoBoxCount--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double boxWidth = 140;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: "Uploads & Payouts",
          subtitle: "Upload your hall photos, verification documents...",
        ),
        const SizedBox(height: 20),

        const Text(
          "Hall Photos",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

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
                    height: 100,
                    child: Stack(
                      children: [
                        const UploadBox(label: "Tap to upload photo"),
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

        const SizedBox(height: 20),
        const SectionTitle(
          title: "Payout Details",
          subtitle: "(This information will only be displayed to Customer...)",
        ),
        const SizedBox(height: 10),

        const CustomTextField(label: "Bank Name", hint: "Enter your Bank Name"),
        const CustomTextField(
          label: "Bank Account Number",
          hint: "Enter your Account Number",
        ),

        const SizedBox(height: 10),
        const SectionTitle(
          title: "Business Verification",
          subtitle: "(This information will be used by VenueMate Admin...)",
        ),
        const SizedBox(height: 10),

        Row(
          children: const [
            Expanded(
              child: UploadBox(label: "Tap to upload your NTN TaxPayer file"),
            ),
            SizedBox(width: 15),
            Expanded(
              child: UploadBox(label: "Tap to upload your Business License"),
            ),
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
          subtitle: "Detail the food, beverages, and extra services you offer.",
        ),
        const SizedBox(height: 20),

        const Text(
          "Menu Items",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        ..._menuItems.asMap().entries.map((entry) {
          int idx = entry.key;
          var item = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Slidable(
              key: ValueKey("menu_$idx"),
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: (context) {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const AddMenuItemSheet(),
                      );
                    },
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue,
                    icon: Icons.edit,
                    label: 'Edit',
                    borderRadius: BorderRadius.circular(12),
                  ),
                  SlidableAction(
                    onPressed: (context) {
                      setState(() {
                        _menuItems.removeAt(idx);
                      });
                    },
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    icon: Icons.delete,
                    label: 'Delete',
                    borderRadius: BorderRadius.circular(12),
                  ),
                ],
              ),
              child: MenuItemCard(
                name: item["name"]!,
                price: item["price"]!,
                priceUnit: "Serving",
                description: item["description"]!,
                imageUrl:
                    "https://img.freepik.com/free-photo/side-view-shawarma-with-fried-potatoes-board-cookware_176474-3215.jpg",
              ),
            ),
          );
        }),

        const SizedBox(height: 15),
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const AddMenuItemSheet(),
            );
          },
          child: const AddNewButton(label: "Add New Menu Item"),
        ),
        const SizedBox(height: 25),

        RichText(
          text: TextSpan(
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.bold,
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
          int idx = entry.key;
          var service = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Slidable(
              key: ValueKey("service_$idx"),
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: (context) {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const AddServiceSheet(),
                      );
                    },
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue,
                    icon: Icons.edit,
                    label: 'Edit',
                    borderRadius: BorderRadius.circular(12),
                  ),
                  SlidableAction(
                    onPressed: (context) {
                      setState(() {
                        _services.removeAt(idx);
                      });
                    },
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    icon: Icons.delete,
                    label: 'Delete',
                    borderRadius: BorderRadius.circular(12),
                  ),
                ],
              ),
              child: ServiceCard(
                name: service["name"]!,
                price: service["price"]!,
                description: service["description"]!,
              ),
            ),
          );
        }),

        const SizedBox(height: 15),
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const AddServiceSheet(),
            );
          },
          child: const AddNewButton(label: "Add New Service"),
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
        const SizedBox(height: 20),

        _ReviewCard(
          title: "Basic Details",
          stepIndex: 0,
          onEdit: widget.onEditStep,
          children: const [
            _ReviewRow(
              icon: Icons.person,
              label: "Name",
              value: "Rehman Hussain",
            ),
            _ReviewRow(
              icon: Icons.phone,
              label: "Phone",
              value: "+92 3XX XXXXXXX",
            ),
            _ReviewRow(
              icon: Icons.badge,
              label: "CNIC",
              value: "42201-XXXXXXX-X",
            ),
          ],
        ),

        const SizedBox(height: 16),

        _ReviewCard(
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
        ),

        const SizedBox(height: 16),

        _ReviewCard(
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
        ),

        const SizedBox(height: 16),

        _ReviewCard(
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
        ),

        const SizedBox(height: 30),

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
                          ? const Color(0xFFF58529)
                          : Colors.transparent,
                  border: Border.all(
                    color: _isConfirmed ? const Color(0xFFF58529) : Colors.grey,
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

        const SizedBox(height: 20),

        GestureDetector(
          onTap:
              _isConfirmed
                  ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Form Submitted Successfully!"),
                      ),
                    );
                    Navigation.push(context, PendingReviewScreen());
                  }
                  : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient:
                  _isConfirmed
                      ? const LinearGradient(
                        colors: [Color(0xFFF47C20), Color(0xFFFFD166)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                      : null,
              color: _isConfirmed ? null : Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "Submit for Verification",
              style: TextStyle(
                color: _isConfirmed ? Colors.white : Colors.grey[600],
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
          Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            price,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFF58529),
            ),
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
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final int maxLines;
  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey[300],
                fontWeight: FontWeight.bold,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
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

class AddNewButton extends StatelessWidget {
  final String label;
  const AddNewButton({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        color: const Color(0xFFFFE0C2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.add_circle_outline,
            color: Color(0xFFF58529),
            size: 26,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFF58529),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class MenuItemCard extends StatelessWidget {
  final String name;
  final String price;
  final String priceUnit;
  final String description;
  final String imageUrl;

  const MenuItemCard({
    super.key,
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.priceUnit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) =>
                      Container(width: 60, height: 60, color: Colors.grey[200]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                    children: [
                      TextSpan(
                        text: "$name ",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: "\nRs. $price/$priceUnit",
                        style: const TextStyle(
                          color: Color(0xFFF58529),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
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

class ServiceCard extends StatelessWidget {
  final String name;
  final String price;
  final String description;

  const ServiceCard({
    super.key,
    required this.name,
    required this.price,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            "Rs. $price",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF58529),
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
