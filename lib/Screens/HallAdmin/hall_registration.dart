import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:venuemate_system/Widgets/add_new_button.dart';
import 'package:venuemate_system/Widgets/menu_item_card.dart';
import 'package:venuemate_system/Widgets/service_card.dart';
import 'package:venuemate_system/Services/auth_service.dart';
import 'package:venuemate_system/Services/hall_service.dart';
import 'package:venuemate_system/Services/storage_service.dart';
import 'package:venuemate_system/Services/menu_service.dart';
import 'package:venuemate_system/Screens/HallAdmin/pending_review.dart';
import 'package:venuemate_system/Screens/HallAdmin/add_menu_item_sheet.dart';
import 'package:venuemate_system/Screens/HallAdmin/location_picker_sheet.dart';
import 'package:venuemate_system/Screens/HallAdmin/add_vendor_service_sheet.dart';

import '../../Services/service_item_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  SHARED STATE — passed from parent down to each step widget
// ══════════════════════════════════════════════════════════════════════════════
class RegistrationData {
  // Step 1 – Basic Details
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final cnicController = TextEditingController();
  File? cnicFrontFile;
  File? cnicBackFile;

  // Step 2 – Hall Details
  final hallNameController = TextEditingController();
  final rentController = TextEditingController();
  final locationController = TextEditingController();
  final minController = TextEditingController();
  final maxController = TextEditingController();
  final descController = TextEditingController();
  double selectedLat = 0.0;
  double selectedLng = 0.0;

  // Step 3 – Uploads & Payouts
  List<File> hallPhotos = [];
  final bankNameController = TextEditingController();
  final bankAccController = TextEditingController();
  File? ntnFile;
  String ntnFileName = ''; // original filename (for display)
  File? licenseFile;
  String licenseFileName = ''; // original filename (for display)

  // Step 4 – Menu & Services (local lists until final submit)
  List<Map<String, String>> menuItems = [];
  List<Map<String, String>> serviceItems = [];

  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    cnicController.dispose();
    hallNameController.dispose();
    rentController.dispose();
    locationController.dispose();
    minController.dispose();
    maxController.dispose();
    descController.dispose();
    bankNameController.dispose();
    bankAccController.dispose();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class HallRegistrationScreen extends StatefulWidget {
  const HallRegistrationScreen({super.key});

  @override
  State<HallRegistrationScreen> createState() => _HallRegistrationScreenState();
}

class _HallRegistrationScreenState extends State<HallRegistrationScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;
  final _data = RegistrationData();

  final List<Map<String, dynamic>> _stepData = [
    {'title': 'Basic Details', 'number': 1},
    {'title': 'Hall Details', 'number': 2},
    {'title': 'Uploads & Payout', 'number': 3},
    {'title': 'Menu & Services', 'number': 4},
    {'title': 'Review', 'number': 5},
  ];

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 4) setState(() => _currentStep++);
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  void _jumpToStep(int i) => setState(() => _currentStep = i);

  // ── Validate before advancing ──────────────────────────────────────────────
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_data.nameController.text.trim().isEmpty) {
          _snack('Please enter your full name.');
          return false;
        }
        if (_data.phoneController.text.trim().length != 11) {
          _snack('Phone number must be exactly 11 digits.');
          return false;
        }
        if (_data.emailController.text.trim().isEmpty) {
          _snack('Please enter your email.');
          return false;
        }
        if (_data.cnicController.text.trim().isEmpty) {
          _snack('Please enter your CNIC.');
          return false;
        }
        if (_data.cnicFrontFile == null) {
          _snack('Please upload CNIC front side.');
          return false;
        }
        if (_data.cnicBackFile == null) {
          _snack('Please upload CNIC back side.');
          return false;
        }
        return true;

      case 1:
        if (_data.hallNameController.text.trim().isEmpty) {
          _snack('Please enter hall name.');
          return false;
        }
        if (_data.rentController.text.trim().isEmpty ||
            double.tryParse(_data.rentController.text.trim()) == null) {
          _snack('Please enter a valid hall rent.');
          return false;
        }
        if (_data.locationController.text.trim().isEmpty) {
          _snack('Please select a location.');
          return false;
        }
        if (_data.minController.text.trim().isEmpty ||
            _data.maxController.text.trim().isEmpty) {
          _snack('Please enter guest capacity (min and max).');
          return false;
        }
        return true;

      case 2:
        if (_data.hallPhotos.isEmpty) {
          _snack('Please upload at least one hall photo.');
          return false;
        }
        if (_data.bankNameController.text.trim().isEmpty) {
          _snack('Please enter bank name.');
          return false;
        }
        if (_data.bankAccController.text.trim().isEmpty) {
          _snack('Please enter account number.');
          return false;
        }
        if (_data.ntnFile == null) {
          _snack('Please upload NTN document.');
          return false;
        }
        if (_data.licenseFile == null) {
          _snack('Please upload business license.');
          return false;
        }
        return true;

      default:
        return true;
    }
  }

  // ── Final submit ───────────────────────────────────────────────────────────
  Future<void> _submitRegistration() async {
    final uid = AuthService.currentUid;
    if (uid == null) {
      _snack('Please log in first.');
      return;
    }

    setState(() => _isSubmitting = true);

    final String? hallId = await HallService.registerHall(
      ownerId: uid,
      ownerName: _data.nameController.text.trim(),
      contactPhone: _data.phoneController.text.trim(),
      cnicFront: _data.cnicFrontFile!,
      cnicBack: _data.cnicBackFile!,
      hallName: _data.hallNameController.text.trim(),
      pricePerEvent: double.parse(_data.rentController.text.trim()),
      address: _data.locationController.text.trim(),
      latitude: _data.selectedLat,
      longitude: _data.selectedLng,
      capacityMin: int.tryParse(_data.minController.text.trim()) ?? 0,
      capacityMax: int.tryParse(_data.maxController.text.trim()) ?? 0,
      description: _data.descController.text.trim(),
      hallPhotos: _data.hallPhotos,
      bankName: _data.bankNameController.text.trim(),
      bankAccountNumber: _data.bankAccController.text.trim(),
      ntnDoc: _data.ntnFile!,
      businessLicense: _data.licenseFile!,
    );

    if (hallId == null) {
      if (mounted) setState(() => _isSubmitting = false);
      _snack(
        'Failed to submit. Please check your connection and try again.',
        isError: true,
      );
      return;
    }

    // ── Step 4: Save menu items and services to Firestore sub-collections ──
    // These are the items the hall admin added in the Menu & Services step.
    // They are saved after the hall doc is created so we have the hallId.
    for (final item in _data.menuItems) {
      // imageUrl in _data.menuItems is a local file path
      File? imageFile;
      final path = item['imageUrl'] ?? '';
      if (path.isNotEmpty) imageFile = File(path);

      await MenuService.addMenuItem(
        hallId: hallId,
        name: item['name'] ?? '',
        price: double.tryParse(item['price'] ?? '0') ?? 0,
        priceUnit: '/${item['priceUnit'] ?? 'Serving'}',
        description: item['description'] ?? '',
        imageFile: imageFile,
      );
    }

    for (final svc in _data.serviceItems) {
      await ServiceItemService.addService(
        hallId: hallId,
        name: svc['name'] ?? '',
        price: double.tryParse(svc['price'] ?? '0') ?? 0,
        description: svc['description'] ?? '',
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const PendingReviewScreen()),
      (route) => false,
    );
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : const Color(0xFFF47C20),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> steps = [
      BasicDetailsStep(data: _data, onChanged: () => setState(() {})),
      HallDetailsStep(data: _data, onChanged: () => setState(() {})),
      UploadsPayoutsStep(data: _data, onChanged: () => setState(() {})),
      MenuServicesStep(data: _data, onChanged: () => setState(() {})),
      ReviewSubmitStep(
        data: _data,
        onEditStep: _jumpToStep,
        isSubmitting: _isSubmitting,
        onSubmit: _submitRegistration,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed:
              () => _currentStep > 0 ? _prevStep() : Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Hall Registration',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        foregroundColor: Colors.black87,
                                      ),
                                      child: const Text(
                                        'Previous',
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
                                    onPressed: () {
                                      if (!_validateCurrentStep()) return;
                                      _nextStep();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF47C20),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Next',
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

  Widget _buildStepIndicator() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Row(
                children:
                    _stepData.asMap().entries.map((e) {
                      final isActive = e.key == _currentStep;
                      return Expanded(
                        child: Center(
                          child: Text(
                            e.value['title'] as String,
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
                children: List.generate(5, (index) {
                  final isActive = index == _currentStep;
                  final isCompleted = index < _currentStep;
                  return Expanded(
                    child: Column(
                      children: [
                        Container(
                          height: 4,
                          margin: EdgeInsets.only(right: index < 4 ? 4 : 0),
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
                                    ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 14,
                                    )
                                    : Text(
                                      '${index + 1}',
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
}

// ══════════════════════════════════════════════════════════════════════════════
//  STEP 1 — BASIC DETAILS
// ══════════════════════════════════════════════════════════════════════════════
class BasicDetailsStep extends StatefulWidget {
  final RegistrationData data;
  final VoidCallback onChanged;
  const BasicDetailsStep({
    super.key,
    required this.data,
    required this.onChanged,
  });

  @override
  State<BasicDetailsStep> createState() => _BasicDetailsStepState();
}

class _BasicDetailsStepState extends State<BasicDetailsStep> {
  Future<void> _pickCnic(bool isFront) async {
    final file = await StorageService.pickImageFromGallery();
    if (file == null) return;
    setState(() {
      if (isFront) {
        widget.data.cnicFrontFile = file;
      } else {
        widget.data.cnicBackFile = file;
      }
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Basic Details',
          'Fill in your personal contact details.',
        ),
        const SizedBox(height: 24),
        _field('Full Name', d.nameController, 'Enter your Full Name'),
        _field(
          'Phone Number',
          d.phoneController,
          '03**-*******',
          type: TextInputType.phone,
          formatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
        ),
        _field(
          'Email',
          d.emailController,
          'Enter your Email',
          type: TextInputType.emailAddress,
        ),
        _field(
          'CNIC',
          d.cnicController,
          'CNIC in format *****-*******-*',
          type: TextInputType.number,
        ),
        const SizedBox(height: 4),
        const Text(
          'CNIC Photos',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _uploadBox(
                'Front Side CNIC',
                d.cnicFrontFile,
                () => _pickCnic(true),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _uploadBox(
                'Back Side CNIC',
                d.cnicBackFile,
                () => _pickCnic(false),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  STEP 2 — HALL DETAILS
// ══════════════════════════════════════════════════════════════════════════════
class HallDetailsStep extends StatefulWidget {
  final RegistrationData data;
  final VoidCallback onChanged;
  const HallDetailsStep({
    super.key,
    required this.data,
    required this.onChanged,
  });

  @override
  State<HallDetailsStep> createState() => _HallDetailsStepState();
}

class _HallDetailsStepState extends State<HallDetailsStep> {
  Future<void> _openLocationPicker() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      isDismissible: false,
      builder: (_) => const LocationPickerSheet(),
    );
    if (result != null) {
      setState(() {
        widget.data.locationController.text = result['address'] ?? '';
        widget.data.selectedLat = (result['lat'] ?? 0).toDouble();
        widget.data.selectedLng = (result['lng'] ?? 0).toDouble();
      });
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Hall Details', 'Fill in details for your hall.'),
        const SizedBox(height: 24),
        _field('Hall Name', d.hallNameController, 'Enter your Hall Name'),
        _field(
          'Hall Rent (Rs.)',
          d.rentController,
          'Enter Hall\'s Rent',
          type: TextInputType.number,
        ),
        const Text(
          'Hall Location',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: d.locationController,
                readOnly: true,
                style: const TextStyle(fontSize: 14),
                decoration: _inputDec('Your Hall Location'),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _openLocationPicker,
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
          'Guest Capacity',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: d.minController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 14),
                decoration: _inputDec('Min'),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: TextFormField(
                controller: d.maxController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 14),
                decoration: _inputDec('Max'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _field(
          'Hall Description',
          d.descController,
          'Enter your Hall Description',
          maxLines: 5,
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  STEP 3 — UPLOADS & PAYOUTS
// ══════════════════════════════════════════════════════════════════════════════
class UploadsPayoutsStep extends StatefulWidget {
  final RegistrationData data;
  final VoidCallback onChanged;
  const UploadsPayoutsStep({
    super.key,
    required this.data,
    required this.onChanged,
  });

  @override
  State<UploadsPayoutsStep> createState() => _UploadsPayoutsStepState();
}

class _UploadsPayoutsStepState extends State<UploadsPayoutsStep> {
  Future<void> _addPhoto() async {
    final file = await StorageService.pickImageFromGallery();
    if (file == null) return;
    setState(() => widget.data.hallPhotos.add(file));
    widget.onChanged();
  }

  void _removePhoto(int index) {
    setState(() => widget.data.hallPhotos.removeAt(index));
    widget.onChanged();
  }

  /// Opens file picker allowing only images (jpg/png/etc) and PDF.
  /// No Word, PPT, Excel, or other formats.
  Future<void> _pickDocument(bool isNtn) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        // Only allow images and PDFs — no word/ppt/xlsx
        allowedExtensions: [
          'pdf',
          'jpg',
          'jpeg',
          'png',
          'heic',
          'heif',
          'webp',
        ],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final picked = result.files.single;
      if (picked.path == null) return;

      final file = File(picked.path!);
      final fileName = picked.name;

      setState(() {
        if (isNtn) {
          widget.data.ntnFile = file;
          widget.data.ntnFileName = fileName;
        } else {
          widget.data.licenseFile = file;
          widget.data.licenseFileName = fileName;
        }
      });
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open file picker: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Uploads & Payouts',
          'Upload hall photos, verification documents...',
        ),
        const SizedBox(height: 24),

        // Hall Photos
        const Text(
          'Hall Photos',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...d.hallPhotos.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          e.value,
                          width: 140,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removePhoto(e.key),
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
                onTap: _addPhoto,
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 32,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add Photo',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Payout details
        _sectionTitle(
          'Payout Details',
          'This information will only be displayed to customers.',
        ),
        const SizedBox(height: 16),
        _field('Bank Name', d.bankNameController, 'Enter your Bank Name'),
        _field(
          'Bank Account Number',
          d.bankAccController,
          'Enter your Account Number',
          type: TextInputType.number,
        ),
        const SizedBox(height: 10),

        // Business verification docs
        _sectionTitle(
          'Business Verification',
          'This information will be used by VenueMate Admin.',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _docUploadBox(
                'NTN TaxPayer File',
                d.ntnFile,
                d.ntnFileName,
                () => _pickDocument(true),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _docUploadBox(
                'Business License',
                d.licenseFile,
                d.licenseFileName,
                () => _pickDocument(false),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  STEP 4 — MENU & SERVICES
// ══════════════════════════════════════════════════════════════════════════════
class MenuServicesStep extends StatefulWidget {
  final RegistrationData data;
  final VoidCallback onChanged;
  const MenuServicesStep({
    super.key,
    required this.data,
    required this.onChanged,
  });

  @override
  State<MenuServicesStep> createState() => _MenuServicesStepState();
}

class _MenuServicesStepState extends State<MenuServicesStep> {
  void _openMenuSheet([Map<String, String>? existing, int? index]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => AddMenuItemSheet(
            existing: existing,
            onSave: (item) {
              setState(() {
                if (index != null) {
                  widget.data.menuItems[index] = item;
                } else {
                  widget.data.menuItems.add(item);
                }
              });
              widget.onChanged();
            },
          ),
    );
  }

  void _openServiceSheet([Map<String, String>? existing, int? index]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => AddServiceSheet(
            existing: existing,
            onSave: (item) {
              setState(() {
                if (index != null) {
                  widget.data.serviceItems[index] = item;
                } else {
                  widget.data.serviceItems.add(item);
                }
              });
              widget.onChanged();
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Menu & Services',
          'Detail the food, beverages, and extra services.',
        ),
        const SizedBox(height: 24),

        // Menu items
        const Text(
          'Menu Items',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        ...d.menuItems.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Slidable(
              key: ValueKey('menu_${entry.key}'),
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: (_) => _openMenuSheet(entry.value, entry.key),
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue,
                    icon: Icons.edit,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  SlidableAction(
                    onPressed:
                        (_) => setState(() => d.menuItems.removeAt(entry.key)),
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    icon: Icons.delete,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ],
              ),
              child: MenuItemCard(
                name: entry.value['name'] ?? '',
                price: entry.value['price'] ?? '',
                priceUnit: entry.value['priceUnit'] ?? 'Serving',
                description: entry.value['description'] ?? '',
                imageUrl:
                    entry.value['imageUrl'] ??
                    'https://img.freepik.com/free-photo/side-view-shawarma-with-fried-potatoes-board-cookware_176474-3215.jpg',
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        AddNewButton(label: 'Add New Menu Item', onTap: _openMenuSheet),
        const SizedBox(height: 32),

        // Services
        RichText(
          text: TextSpan(
            style: const TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            children: [
              const TextSpan(text: 'Additional Services '),
              TextSpan(
                text: '(If Any)',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...d.serviceItems.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Slidable(
              key: ValueKey('svc_${entry.key}'),
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: (_) => _openServiceSheet(entry.value, entry.key),
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue,
                    icon: Icons.edit,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  SlidableAction(
                    onPressed:
                        (_) =>
                            setState(() => d.serviceItems.removeAt(entry.key)),
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    icon: Icons.delete,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ],
              ),
              child: ServiceCard(
                name: entry.value['name'] ?? '',
                price: entry.value['price'] ?? '',
                description: entry.value['description'] ?? '',
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        AddNewButton(label: 'Add New Service', onTap: _openServiceSheet),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  STEP 5 — REVIEW & SUBMIT
// ══════════════════════════════════════════════════════════════════════════════
class ReviewSubmitStep extends StatefulWidget {
  final RegistrationData data;
  final Function(int) onEditStep;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  const ReviewSubmitStep({
    super.key,
    required this.data,
    required this.onEditStep,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  State<ReviewSubmitStep> createState() => _ReviewSubmitStepState();
}

class _ReviewSubmitStepState extends State<ReviewSubmitStep> {
  bool _isConfirmed = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Review & Submit',
          'Please review all your information before submitting.',
        ),
        const SizedBox(height: 24),

        _reviewCard('Basic Details', 0, widget.onEditStep, [
          _reviewRow(Icons.person, 'Name', d.nameController.text),
          _reviewRow(Icons.phone, 'Phone', d.phoneController.text),
          _reviewRow(Icons.badge, 'CNIC', d.cnicController.text),
          _reviewRow(Icons.email, 'Email', d.emailController.text),
          _reviewRow(
            Icons.photo,
            'CNIC Photos',
            '${d.cnicFrontFile != null ? '✓' : '✗'} Front  '
                '${d.cnicBackFile != null ? '✓' : '✗'} Back',
          ),
        ]),
        const SizedBox(height: 16),

        _reviewCard('Hall Details', 1, widget.onEditStep, [
          _reviewRow(Icons.store, 'Hall Name', d.hallNameController.text),
          _reviewRow(Icons.location_on, 'Location', d.locationController.text),
          _reviewRow(
            Icons.groups,
            'Capacity',
            '${d.minController.text} – ${d.maxController.text} Guests',
          ),
          _reviewRow(
            Icons.payments,
            'Rent',
            'Rs. ${d.rentController.text}/Event',
          ),
        ]),
        const SizedBox(height: 16),

        _reviewCard('Uploads & Payouts', 2, widget.onEditStep, [
          _reviewRow(
            Icons.photo_library,
            'Hall Photos',
            '${d.hallPhotos.length} photo(s) selected',
          ),
          _reviewRow(
            Icons.account_balance,
            'Bank',
            '${d.bankNameController.text} • ${d.bankAccController.text}',
          ),
          _reviewRow(
            Icons.assignment,
            'Documents',
            '${d.ntnFile != null ? '✓' : '✗'} NTN  '
                '${d.licenseFile != null ? '✓' : '✗'} License',
          ),
        ]),
        const SizedBox(height: 16),

        _reviewCard('Menu & Services', 3, widget.onEditStep, [
          if (d.menuItems.isEmpty && d.serviceItems.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'No items added.',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
          if (d.menuItems.isNotEmpty) ...[
            const Text(
              'Menu Items',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            ...d.menuItems.map(
              (i) => _itemRow(
                i['name'] ?? '',
                'Rs. ${i['price']}/${i['priceUnit']}',
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (d.serviceItems.isNotEmpty) ...[
            const Text(
              'Services',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            ...d.serviceItems.map(
              (s) => _itemRow(s['name'] ?? '', 'Rs. ${s['price']}'),
            ),
          ],
        ]),
        const SizedBox(height: 40),

        // Confirmation checkbox
        GestureDetector(
          onTap: () => setState(() => _isConfirmed = !_isConfirmed),
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
                  'I confirm that the information provided is accurate.',
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
                (_isConfirmed && !widget.isSubmitting) ? widget.onSubmit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF47C20),
              disabledBackgroundColor: Colors.grey[300],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child:
                widget.isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                      'Submit for Verification',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _itemRow(String name, String price) => Padding(
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

// ══════════════════════════════════════════════════════════════════════════════
//  SHARED HELPER WIDGETS & FUNCTIONS
// ══════════════════════════════════════════════════════════════════════════════

Widget _sectionTitle(String title, String subtitle) {
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

Widget _field(
  String label,
  TextEditingController ctrl,
  String hint, {
  TextInputType? type,
  int maxLines = 1,
  List<TextInputFormatter>? formatters,
}) {
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
          controller: ctrl,
          keyboardType: type,
          maxLines: maxLines,
          inputFormatters: formatters,
          style: const TextStyle(fontSize: 14),
          decoration: _inputDec(hint),
        ),
      ],
    ),
  );
}

/// Tappable upload box for CNIC / hall photos. Shows image thumbnail if picked.
Widget _uploadBox(String label, File? file, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: file != null ? const Color(0xFFF47C20) : Colors.grey[300]!,
          width: file != null ? 2 : 1,
        ),
      ),
      child:
          file != null
              ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(file, fit: BoxFit.cover),
              )
              : Column(
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
    ),
  );
}

/// Upload box for NTN and Business License.
/// Supports both image and PDF files.
/// - For images: shows a thumbnail
/// - For PDFs: shows a PDF icon with the filename
/// - For empty: shows the upload icon with label
Widget _docUploadBox(
  String label,
  File? file,
  String fileName,
  VoidCallback onTap,
) {
  final isPdf = fileName.toLowerCase().endsWith('.pdf');
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: file != null ? const Color(0xFFF47C20) : Colors.grey[300]!,
          width: file != null ? 2 : 1,
        ),
      ),
      child:
          file == null
              // ── Not picked yet ──────────────────────────────────────────────
              ? Column(
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
                  const SizedBox(height: 4),
                  Text(
                    'Image or PDF',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                  ),
                ],
              )
              : isPdf
              // ── PDF picked ──────────────────────────────────────────────
              ? Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.picture_as_pdf,
                      size: 32,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      fileName.length > 20
                          ? '${fileName.substring(0, 17)}...'
                          : fileName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '✓ PDF uploaded',
                      style: TextStyle(
                        fontSize: 9,
                        color: Color(0xFFF47C20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
              // ── Image picked ─────────────────────────────────────────────
              : ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  file,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
    ),
  );
}

Widget _reviewCard(
  String title,
  int stepIndex,
  Function(int) onEdit,
  List<Widget> children,
) {
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
                child: const Row(
                  children: [
                    Text(
                      'Edit',
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

Widget _reviewRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
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

InputDecoration _inputDec(String hint) => InputDecoration(
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
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
);
