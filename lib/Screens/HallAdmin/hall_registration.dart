import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
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
import 'package:venuemate_system/Services/notification_service.dart';

const double _kWebBreak = 900;

// ══════════════════════════════════════════════════════════════════════════════
//  CROSS-PLATFORM FILE WRAPPER
// ══════════════════════════════════════════════════════════════════════════════
class _PickedFile {
  final XFile xFile;
  final Uint8List bytes;
  final String name;

  _PickedFile({required this.xFile, required this.bytes}) : name = xFile.name;

  static Future<_PickedFile> fromXFile(XFile xf) async {
    final bytes = await xf.readAsBytes();
    return _PickedFile(xFile: xf, bytes: bytes);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SHARED STATE
// ══════════════════════════════════════════════════════════════════════════════
class RegistrationData {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final cnicController = TextEditingController();

  _PickedFile? cnicFront;
  _PickedFile? cnicBack;

  final hallNameController = TextEditingController();
  final rentController = TextEditingController();
  final locationController = TextEditingController();
  final minController = TextEditingController();
  final maxController = TextEditingController();
  final descController = TextEditingController();
  double selectedLat = 0.0;
  double selectedLng = 0.0;

  List<_PickedFile> hallPhotos = [];
  final bankNameController = TextEditingController();
  final bankAccController = TextEditingController();
  _PickedFile? ntnFile;
  _PickedFile? licenseFile;

  List<Map<String, String>> menuItems = [];
  List<XFile?> menuXFiles = [];
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
    {'title': 'Basic Details', 'icon': Icons.person_outline, 'number': 1},
    {'title': 'Hall Details', 'icon': Icons.store_outlined, 'number': 2},
    {
      'title': 'Uploads & Payout',
      'icon': Icons.upload_file_outlined,
      'number': 3,
    },
    {
      'title': 'Menu & Services',
      'icon': Icons.restaurant_menu_outlined,
      'number': 4,
    },
    {'title': 'Review', 'icon': Icons.fact_check_outlined, 'number': 5},
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

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_data.nameController.text.trim().isEmpty) {
          _snack('Please enter your full name.');
          return false;
        }
        if (_data.phoneController.text.trim().isEmpty) {
          _snack('Please enter your phone number.');
          return false;
        }
        if (_data.phoneController.text.trim().length != 11) {
          _snack('Phone number must be exactly 11 digits.');
          return false;
        }
        if (!(_data.phoneController.text.trim().startsWith("03"))) {
          _snack("Phone number must start with 03");
          return false;
        }
        if (_data.emailController.text.trim().isEmpty) {
          _snack('Please enter your email.');
          return false;
        }
        if (!(RegExp(
          r'^[\w.-]+@[\w.-]+\.\w{2,}$',
        ).hasMatch(_data.emailController.text.trim()))) {
          _snack('Enter a valid email address');
          return false;
        }
        if (_data.cnicController.text.trim().isEmpty) {
          _snack('Please enter your CNIC.');
          return false;
        }
        if (_data.cnicController.text.trim().length != 13) {
          _snack('CNIC must be exactly 13 digits.');
          return false;
        }
        if (_data.cnicFront == null) {
          _snack('Please upload CNIC front side.');
          return false;
        }
        if (_data.cnicBack == null) {
          _snack('Please upload CNIC back side.');
          return false;
        }
        return true;
      case 1:
        if (_data.hallNameController.text.trim().isEmpty) {
          _snack('Please enter hall name.');
          return false;
        }
        final rentText = _data.rentController.text.trim();
        if (rentText.isEmpty) {
          _snack('Hall Rent is required.');
          return false;
        }
        final rent = double.tryParse(rentText);
        if (rent == null || rent <= 0) {
          _snack('Please enter a valid hall rent.');
          return false;
        }
        if (_data.locationController.text.trim().isEmpty) {
          _snack('Please select a location.');
          return false;
        }
        final minText = _data.minController.text.trim();
        final maxText = _data.maxController.text.trim();
        if (minText.isEmpty || maxText.isEmpty) {
          _snack('Both minimum and maximum capacity are required.');
          return false;
        }
        final minCap = int.tryParse(minText);
        final maxCap = int.tryParse(maxText);
        if (minCap == null || minCap <= 0) {
          _snack('Minimum capacity must be a positive number.');
          return false;
        }
        if (maxCap == null || maxCap <= 0) {
          _snack('Maximum capacity must be a positive number.');
          return false;
        }
        if (minCap >= maxCap) {
          _snack('Minimum capacity must be less than maximum capacity.');
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

  Future<void> _submitRegistration() async {
    final uid = AuthService.currentUid;
    if (uid == null) {
      _snack('Please log in first.');
      return;
    }
    setState(() => _isSubmitting = true);

    final String? hallId = await HallService.registerHallXFile(
      ownerId: uid,
      ownerName: _data.nameController.text.trim(),
      contactPhone: _data.phoneController.text.trim(),
      cnicFront: _data.cnicFront!.xFile,
      cnicBack: _data.cnicBack!.xFile,
      hallName: _data.hallNameController.text.trim(),
      pricePerEvent: double.parse(_data.rentController.text.trim()),
      address: _data.locationController.text.trim(),
      latitude: _data.selectedLat,
      longitude: _data.selectedLng,
      capacityMin: int.tryParse(_data.minController.text.trim()) ?? 0,
      capacityMax: int.tryParse(_data.maxController.text.trim()) ?? 0,
      description: _data.descController.text.trim(),
      hallPhotos: _data.hallPhotos.map((p) => p.xFile).toList(),
      bankName: _data.bankNameController.text.trim(),
      bankAccountNumber: _data.bankAccController.text.trim(),
      ntnDoc: _data.ntnFile!.xFile,
      businessLicense: _data.licenseFile!.xFile,
    );

    if (hallId == null) {
      if (mounted) setState(() => _isSubmitting = false);
      _snack(
        'Failed to submit. Please check your connection and try again.',
        isError: true,
      );
      return;
    }

    for (int i = 0; i < _data.menuItems.length; i++) {
      final item = _data.menuItems[i];
      final xFile = i < _data.menuXFiles.length ? _data.menuXFiles[i] : null;
      await MenuService.addMenuItemXFile(
        hallId: hallId,
        name: item['name'] ?? '',
        price: double.tryParse(item['price'] ?? '0') ?? 0,
        priceUnit: '/${item['priceUnit'] ?? 'Serving'}',
        description: item['description'] ?? '',
        imageXFile: xFile,
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

    // Notify all system admins — service handles the query internally
    unawaited(
      NotificationService.sendRegistrationSubmitted(
        systemAdminUid: '', // ignored, service notifies all admins
        hallId: hallId,
        hallName: _data.hallNameController.text.trim(),
        ownerName: _data.nameController.text.trim(),
      ),
    );

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
    final isWide = MediaQuery.of(context).size.width >= _kWebBreak;

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

    return isWide ? _buildWebLayout(steps) : _buildMobileLayout(steps);
  }

  // ── WEB LAYOUT ─────────────────────────────────────────────────────────────
  Widget _buildWebLayout(List<Widget> steps) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      body: Row(
        children: [
          _buildWebSidebar(),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFEEEEEE)),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
                          size: 20,
                        ),
                        onPressed:
                            () =>
                                _currentStep > 0
                                    ? _prevStep()
                                    : Navigator.pop(context),
                        tooltip: _currentStep > 0 ? 'Previous Step' : 'Back',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _stepData[_currentStep]['title'] as String,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF47C20).withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Step ${_currentStep + 1} of 5',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF47C20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: const Color(0xFFEEEEF2),
                                ),
                              ),
                              child: steps[_currentStep],
                            ),
                            const SizedBox(height: 16),
                            if (_currentStep < 4)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (_currentStep > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 10),
                                      child: SizedBox(
                                        height: 38,
                                        child: OutlinedButton(
                                          onPressed: _prevStep,
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                              color: Colors.grey,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            foregroundColor: Colors.black87,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                            ),
                                          ),
                                          child: const Text(
                                            'Previous',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  SizedBox(
                                    height: 38,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (!_validateCurrentStep()) return;
                                        _nextStep();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFF47C20,
                                        ),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                        ),
                                      ),
                                      child: const Text(
                                        'Next',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebSidebar() {
    return Container(
      width: 240,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF47C20), Color(0xFFFFD166)],
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.app_registration, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Hall Registration',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              'STEPS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 6),
          ...List.generate(_stepData.length, (i) {
            final isActive = i == _currentStep;
            final isCompleted = i < _currentStep;
            final color =
                isActive
                    ? const Color(0xFFF47C20)
                    : isCompleted
                    ? const Color(0xFF10B981)
                    : Colors.grey[400]!;
            return InkWell(
              onTap: i <= _currentStep ? () => _jumpToStep(i) : null,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      isActive
                          ? const Color(0xFFF47C20).withOpacity(0.08)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color:
                            isCompleted
                                ? const Color(0xFF10B981)
                                : isActive
                                ? const Color(0xFFF47C20)
                                : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child:
                            isCompleted
                                ? const Icon(
                                  Icons.check,
                                  size: 13,
                                  color: Colors.white,
                                )
                                : Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    color:
                                        isActive
                                            ? Colors.white
                                            : Colors.grey[600],
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _stepData[i]['title'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.normal,
                          color: color,
                        ),
                      ),
                    ),
                    if (isCompleted)
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: const Color(0xFF10B981).withOpacity(0.6),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── MOBILE LAYOUT (unchanged) ───────────────────────────────────────────────
  Widget _buildMobileLayout(List<Widget> steps) {
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
          _buildMobileStepIndicator(),
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

  Widget _buildMobileStepIndicator() {
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
    final xf = await StorageService.pickImageXFile();
    if (xf == null) return;
    final picked = await _PickedFile.fromXFile(xf);
    setState(() {
      if (isFront) {
        widget.data.cnicFront = picked;
      } else {
        widget.data.cnicBack = picked;
      }
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final isWide = MediaQuery.of(context).size.width >= _kWebBreak;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Basic Details',
          'Fill in your personal contact details.',
          isWide,
        ),
        SizedBox(height: isWide ? 16 : 24),
        if (isWide) ...[
          Row(
            children: [
              Expanded(
                child: _field(
                  'Full Name',
                  d.nameController,
                  'Enter your Full Name',
                  isWide: isWide,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _field(
                  'Phone Number',
                  d.phoneController,
                  '03XXXXXXXXX',
                  type: TextInputType.phone,
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  isWide: isWide,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _field(
                  'Email',
                  d.emailController,
                  'Enter your Email',
                  type: TextInputType.emailAddress,
                  isWide: isWide,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _field(
                  'CNIC',
                  d.cnicController,
                  'CNIC in format XXXXXXXXXXXXX',
                  type: TextInputType.number,
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(13),
                  ],
                  isWide: isWide,
                ),
              ),
            ],
          ),
        ] else ...[
          _field('Full Name', d.nameController, 'Enter your Full Name'),
          _field(
            'Phone Number',
            d.phoneController,
            '03XXXXXXXXX',
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
            'CNIC in format XXXXXXXXXXXXX',
            type: TextInputType.number,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(13),
            ],
          ),
        ],
        const SizedBox(height: 4),
        Text(
          'CNIC Photos',
          style: TextStyle(
            fontSize: isWide ? 12 : 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: isWide ? 6 : 8),
        Row(
          children: [
            Expanded(
              child: _uploadBox(
                'Front Side CNIC',
                d.cnicFront,
                () => _pickCnic(true),
                isWide: isWide,
              ),
            ),
            SizedBox(width: isWide ? 12 : 15),
            Expanded(
              child: _uploadBox(
                'Back Side CNIC',
                d.cnicBack,
                () => _pickCnic(false),
                isWide: isWide,
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
    final savedLat = widget.data.selectedLat;
    final savedLng = widget.data.selectedLng;
    final hasExisting = savedLat != 0.0 || savedLng != 0.0;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      isDismissible: false,
      builder:
          (_) => LocationPickerSheet(
            initialPosition: hasExisting ? LatLng(savedLat, savedLng) : null,
          ),
    );
    if (result != null && mounted) {
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
    final isWide = MediaQuery.of(context).size.width >= _kWebBreak;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Hall Details', 'Fill in details for your hall.', isWide),
        SizedBox(height: isWide ? 16 : 24),
        if (isWide) ...[
          Row(
            children: [
              Expanded(
                child: _field(
                  'Hall Name',
                  d.hallNameController,
                  'Enter your Hall Name',
                  isWide: isWide,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _field(
                  'Hall Rent (Rs.)',
                  d.rentController,
                  "Enter Hall's Rent",
                  type: TextInputType.number,
                  isWide: isWide,
                ),
              ),
            ],
          ),
        ] else ...[
          _field('Hall Name', d.hallNameController, 'Enter your Hall Name'),
          _field(
            'Hall Rent (Rs.)',
            d.rentController,
            "Enter Hall's Rent",
            type: TextInputType.number,
          ),
        ],
        Text(
          'Hall Location',
          style: TextStyle(
            fontSize: isWide ? 12 : 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: isWide ? 6 : 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: d.locationController,
                readOnly: true,
                style: TextStyle(fontSize: isWide ? 13 : 14),
                decoration: _inputDec('Your Hall Location', isWide: isWide),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _openLocationPicker,
              child: Container(
                height: isWide ? 40 : 48,
                width: isWide ? 40 : 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF47C20), Color(0xFFFFD166)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.my_location,
                  color: Colors.white,
                  size: isWide ? 18 : 22,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isWide ? 12 : 16),
        Text(
          'Guest Capacity',
          style: TextStyle(
            fontSize: isWide ? 12 : 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: isWide ? 6 : 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: d.minController,
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: isWide ? 13 : 14),
                decoration: _inputDec('Min', isWide: isWide),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: d.maxController,
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: isWide ? 13 : 14),
                decoration: _inputDec('Max', isWide: isWide),
              ),
            ),
          ],
        ),
        SizedBox(height: isWide ? 12 : 16),
        _field(
          'Hall Description',
          d.descController,
          'Enter your Hall Description',
          maxLines: isWide ? 4 : 5,
          isWide: isWide,
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
    final xf = await StorageService.pickImageXFile();
    if (xf == null) return;
    final picked = await _PickedFile.fromXFile(xf);
    if (!mounted) return;
    setState(() => widget.data.hallPhotos.add(picked));
    widget.onChanged();
  }

  void _removePhoto(int index) {
    setState(() => widget.data.hallPhotos.removeAt(index));
    widget.onChanged();
  }

  Future<void> _pickDocument(bool isNtn) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
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
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final pf = result.files.single;

      final XFile xf;
      if (kIsWeb) {
        xf = XFile.fromData(
          pf.bytes!,
          name: pf.name,
          mimeType: _mimeFromName(pf.name),
        );
      } else {
        xf = XFile(pf.path!);
      }

      final bytes = pf.bytes ?? await xf.readAsBytes();
      final picked = _PickedFile(xFile: xf, bytes: bytes);

      if (!mounted) return;
      setState(() {
        if (isNtn) {
          widget.data.ntnFile = picked;
        } else {
          widget.data.licenseFile = picked;
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

  String _mimeFromName(String name) {
    final ext = name.split('.').last.toLowerCase();
    if (ext == 'pdf') return 'application/pdf';
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final isWide = MediaQuery.of(context).size.width >= _kWebBreak;

    final double thumbW = isWide ? 110 : 140;
    final double thumbH = isWide ? 78 : 100;
    final double addBoxW = isWide ? 78 : 100;
    final double addBoxH = isWide ? 78 : 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Uploads & Payouts',
          'Upload hall photos, verification documents...',
          isWide,
        ),
        SizedBox(height: isWide ? 16 : 24),
        Text(
          'Hall Photos',
          style: TextStyle(
            fontSize: isWide ? 12 : 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: isWide ? 6 : 8),
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
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          e.value.bytes,
                          width: thumbW,
                          height: thumbH,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removePhoto(e.key),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 12,
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
                  height: addBoxH,
                  width: addBoxW,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: isWide ? 22 : 32,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add Photo',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isWide ? 20 : 24),
        _sectionTitle(
          'Payout Details',
          'This information will only be displayed to customers.',
          isWide,
        ),
        SizedBox(height: isWide ? 12 : 16),
        if (isWide)
          Row(
            children: [
              Expanded(
                child: _field(
                  'Bank Name',
                  d.bankNameController,
                  'Enter your Bank Name',
                  isWide: isWide,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _field(
                  'Bank Account Number',
                  d.bankAccController,
                  'Enter your Account Number',
                  type: TextInputType.number,
                  isWide: isWide,
                ),
              ),
            ],
          )
        else ...[
          _field('Bank Name', d.bankNameController, 'Enter your Bank Name'),
          _field(
            'Bank Account Number',
            d.bankAccController,
            'Enter your Account Number',
            type: TextInputType.number,
          ),
        ],
        SizedBox(height: isWide ? 12 : 16),
        _sectionTitle(
          'Business Verification',
          'This information will be used by VenueMate Admin.',
          isWide,
        ),
        SizedBox(height: isWide ? 12 : 16),
        Row(
          children: [
            Expanded(
              child: _docUploadBox(
                'NTN TaxPayer File',
                d.ntnFile,
                () => _pickDocument(true),
                isWide: isWide,
              ),
            ),
            SizedBox(width: isWide ? 12 : 15),
            Expanded(
              child: _docUploadBox(
                'Business License',
                d.licenseFile,
                () => _pickDocument(false),
                isWide: isWide,
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
  // ── FIX: use addPostFrameCallback so setState fires AFTER the sheet has
  //         fully closed, preventing "setState called after dispose" errors.
  void _openMenuSheet([Map<String, String>? existing, int? index]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => AddMenuItemSheet(
            existing: existing,
            onSave: (item, xFile) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  if (index != null) {
                    widget.data.menuItems[index] = item;
                    if (xFile != null) widget.data.menuXFiles[index] = xFile;
                  } else {
                    widget.data.menuItems.add(item);
                    widget.data.menuXFiles.add(xFile);
                  }
                });
                widget.onChanged();
              });
            },
          ),
    );
  }

  // ── FIX: same pattern for services ─────────────────────────────────────────
  void _openServiceSheet([Map<String, String>? existing, int? index]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => AddServiceSheet(
            existing: existing,
            onSave: (item) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  if (index != null) {
                    widget.data.serviceItems[index] = item;
                  } else {
                    widget.data.serviceItems.add(item);
                  }
                });
                widget.onChanged();
              });
            },
          ),
    );
  }

  void _deleteMenuItem(int index) {
    if (!mounted) return;
    setState(() {
      widget.data.menuItems.removeAt(index);
      if (index < widget.data.menuXFiles.length)
        widget.data.menuXFiles.removeAt(index);
    });
    widget.onChanged();
  }

  void _deleteServiceItem(int index) {
    if (!mounted) return;
    setState(() => widget.data.serviceItems.removeAt(index));
    widget.onChanged();
  }

  Widget _webAddButton(String label, VoidCallback onTap) => SizedBox(
    height: 36,
    child: OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add, size: 15, color: Color(0xFFF47C20)),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFFF47C20),
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFF47C20)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 14),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final isWide = MediaQuery.of(context).size.width >= _kWebBreak;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Menu & Services',
          'Detail the food, beverages, and extra services.',
          isWide,
        ),
        SizedBox(height: isWide ? 16 : 24),
        Text(
          'Menu Items',
          style: TextStyle(
            fontSize: isWide ? 12 : 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: isWide ? 8 : 10),
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
                    onPressed: (_) => _deleteMenuItem(entry.key),
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
                imageUrl: entry.value['imageUrl'] ?? '',
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: isWide ? Alignment.centerLeft : Alignment.center,
          child:
              isWide
                  ? _webAddButton('Add New Menu Item', _openMenuSheet)
                  : AddNewButton(
                    label: 'Add New Menu Item',
                    onTap: _openMenuSheet,
                  ),
        ),
        SizedBox(height: isWide ? 24 : 32),
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: Colors.black,
              fontSize: isWide ? 12 : 13,
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
        SizedBox(height: isWide ? 8 : 10),
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
                    // ── FIX: use extracted method with mounted check ──────────
                    onPressed: (_) => _deleteServiceItem(entry.key),
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
        const SizedBox(height: 12),
        Align(
          alignment: isWide ? Alignment.centerLeft : Alignment.center,
          child:
              isWide
                  ? _webAddButton('Add New Service', _openServiceSheet)
                  : AddNewButton(
                    label: 'Add New Service',
                    onTap: _openServiceSheet,
                  ),
        ),
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
    final isWide = MediaQuery.of(context).size.width >= _kWebBreak;

    final card1 = _reviewCard('Basic Details', 0, widget.onEditStep, isWide, [
      _reviewRow(Icons.person, 'Name', d.nameController.text, isWide),
      _reviewRow(Icons.phone, 'Phone', d.phoneController.text, isWide),
      _reviewRow(Icons.badge, 'CNIC', d.cnicController.text, isWide),
      _reviewRow(Icons.email, 'Email', d.emailController.text, isWide),
      _reviewRow(
        Icons.photo,
        'CNIC Photos',
        '${d.cnicFront != null ? '✓' : '✗'} Front  ${d.cnicBack != null ? '✓' : '✗'} Back',
        isWide,
      ),
    ]);
    final card2 = _reviewCard('Hall Details', 1, widget.onEditStep, isWide, [
      _reviewRow(Icons.store, 'Hall Name', d.hallNameController.text, isWide),
      _reviewRow(
        Icons.location_on,
        'Location',
        d.locationController.text,
        isWide,
      ),
      _reviewRow(
        Icons.groups,
        'Capacity',
        '${d.minController.text} – ${d.maxController.text} Guests',
        isWide,
      ),
      _reviewRow(
        Icons.payments,
        'Rent',
        'Rs. ${d.rentController.text}/Event',
        isWide,
      ),
    ]);
    final card3 = _reviewCard('Uploads & Payouts', 2, widget.onEditStep, isWide, [
      _reviewRow(
        Icons.photo_library,
        'Hall Photos',
        '${d.hallPhotos.length} photo(s) selected',
        isWide,
      ),
      _reviewRow(
        Icons.account_balance,
        'Bank',
        '${d.bankNameController.text} • ${d.bankAccController.text}',
        isWide,
      ),
      _reviewRow(
        Icons.assignment,
        'Documents',
        '${d.ntnFile != null ? '✓' : '✗'} NTN  ${d.licenseFile != null ? '✓' : '✗'} License',
        isWide,
      ),
    ]);
    final card4 = _reviewCard('Menu & Services', 3, widget.onEditStep, isWide, [
      if (d.menuItems.isEmpty && d.serviceItems.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'No items added.',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: isWide ? 12 : 14,
            ),
          ),
        ),
      if (d.menuItems.isNotEmpty) ...[
        Text(
          'Menu Items',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            fontSize: isWide ? 11 : 13,
          ),
        ),
        SizedBox(height: isWide ? 4 : 6),
        ...d.menuItems.map(
          (i) => _itemRow(
            i['name'] ?? '',
            'Rs. ${i['price']}/${i['priceUnit']}',
            isWide,
          ),
        ),
        SizedBox(height: isWide ? 8 : 12),
      ],
      if (d.serviceItems.isNotEmpty) ...[
        Text(
          'Services',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            fontSize: isWide ? 11 : 13,
          ),
        ),
        SizedBox(height: isWide ? 4 : 6),
        ...d.serviceItems.map(
          (s) => _itemRow(s['name'] ?? '', 'Rs. ${s['price']}', isWide),
        ),
      ],
    ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Review & Submit',
          'Please review all your information before submitting.',
          isWide,
        ),
        SizedBox(height: isWide ? 16 : 24),
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [card1, const SizedBox(height: 12), card3],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [card2, const SizedBox(height: 12), card4],
                ),
              ),
            ],
          )
        else ...[
          card1,
          const SizedBox(height: 16),
          card2,
          const SizedBox(height: 16),
          card3,
          const SizedBox(height: 16),
          card4,
        ],
        SizedBox(height: isWide ? 28 : 40),
        GestureDetector(
          onTap: () => setState(() => _isConfirmed = !_isConfirmed),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: isWide ? 20 : 24,
                width: isWide ? 20 : 24,
                decoration: BoxDecoration(
                  color:
                      _isConfirmed
                          ? const Color(0xFFF47C20)
                          : Colors.transparent,
                  border: Border.all(
                    color: _isConfirmed ? const Color(0xFFF47C20) : Colors.grey,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(isWide ? 5 : 6),
                ),
                child:
                    _isConfirmed
                        ? Icon(
                          Icons.check,
                          size: isWide ? 13 : 16,
                          color: Colors.white,
                        )
                        : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'I confirm that the information provided is accurate.',
                  style: TextStyle(
                    fontSize: isWide ? 12 : 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isWide ? 16 : 24),
        SizedBox(
          width: double.infinity,
          height: isWide ? 42 : 52,
          child: ElevatedButton(
            onPressed:
                (_isConfirmed && !widget.isSubmitting) ? widget.onSubmit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF47C20),
              disabledBackgroundColor: Colors.grey[300],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isWide ? 8 : 12),
              ),
            ),
            child:
                widget.isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                      'Submit for Verification',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isWide ? 14 : 16,
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _itemRow(String name, String price, bool isWide) => Padding(
    padding: EdgeInsets.only(bottom: isWide ? 3 : 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: isWide ? 12 : 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          price,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: const Color(0xFFF47C20),
            fontSize: isWide ? 12 : 14,
          ),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  SHARED HELPERS
// ══════════════════════════════════════════════════════════════════════════════
Widget _sectionTitle(String title, String subtitle, bool isWide) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      title,
      style: TextStyle(fontSize: isWide ? 18 : 24, fontWeight: FontWeight.w700),
    ),
    const SizedBox(height: 4),
    Text(
      subtitle,
      style: TextStyle(
        color: Colors.grey[400],
        fontSize: isWide ? 11 : 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  ],
);

Widget _field(
  String label,
  TextEditingController ctrl,
  String hint, {
  TextInputType? type,
  int maxLines = 1,
  List<TextInputFormatter>? formatters,
  bool isWide = false,
}) {
  return Padding(
    padding: EdgeInsets.only(bottom: isWide ? 12 : 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isWide ? 12 : 13,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: isWide ? 6 : 8),
        TextFormField(
          controller: ctrl,
          keyboardType: type,
          maxLines: maxLines,
          inputFormatters: formatters,
          style: TextStyle(fontSize: isWide ? 13 : 14),
          decoration: _inputDec(hint, isWide: isWide),
        ),
      ],
    ),
  );
}

Widget _uploadBox(
  String label,
  _PickedFile? file,
  VoidCallback onTap, {
  bool isWide = false,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: isWide ? 90 : 105,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(isWide ? 8 : 10),
        border: Border.all(
          color: file != null ? const Color(0xFFF47C20) : Colors.grey[300]!,
          width: file != null ? 2 : 1,
        ),
      ),
      child:
          file != null
              ? ClipRRect(
                borderRadius: BorderRadius.circular(isWide ? 8 : 10),
                child: Image.memory(file.bytes, fit: BoxFit.cover),
              )
              : FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: isWide ? 24 : 30,
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
              ),
    ),
  );
}

Widget _docUploadBox(
  String label,
  _PickedFile? file,
  VoidCallback onTap, {
  bool isWide = false,
}) {
  final isPdf = file != null && file.name.toLowerCase().endsWith('.pdf');
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: isWide ? 96 : 110,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(isWide ? 8 : 10),
        border: Border.all(
          color: file != null ? const Color(0xFFF47C20) : Colors.grey[300]!,
          width: file != null ? 2 : 1,
        ),
      ),
      child:
          file == null
              ? FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: isWide ? 24 : 30,
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
                  ),
                ),
              )
              : isPdf
              ? FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.picture_as_pdf,
                        size: isWide ? 26 : 32,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        file.name.length > 20
                            ? '${file.name.substring(0, 17)}...'
                            : file.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
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
                ),
              )
              : ClipRRect(
                borderRadius: BorderRadius.circular(isWide ? 8 : 10),
                child: Image.memory(
                  file.bytes,
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
  bool isWide,
  List<Widget> children,
) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(isWide ? 16 : 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(isWide ? 12 : 16),
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
              style: TextStyle(
                fontSize: isWide ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            GestureDetector(
              onTap: () => onEdit(stepIndex),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 10 : 12,
                  vertical: isWide ? 5 : 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: isWide ? 11 : 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF47C20),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.edit,
                      size: isWide ? 11 : 12,
                      color: const Color(0xFFF47C20),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Divider(height: isWide ? 18 : 24),
        ...children,
      ],
    ),
  );
}

Widget _reviewRow(IconData icon, String label, String value, bool isWide) =>
    Padding(
      padding: EdgeInsets.only(bottom: isWide ? 8 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isWide ? 6 : 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: isWide ? 15 : 18, color: Colors.grey[600]),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isWide ? 11 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isWide ? 12 : 14,
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

InputDecoration _inputDec(String hint, {bool isWide = false}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: isWide ? 13 : 14),
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
      contentPadding: EdgeInsets.symmetric(
        horizontal: isWide ? 12 : 14,
        vertical: isWide ? 10 : 12,
      ),
    );
