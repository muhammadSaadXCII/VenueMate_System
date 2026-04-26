import 'package:flutter/material.dart';
import 'package:venuemate_system/Services/menu_service.dart';
import 'package:venuemate_system/Services/package_service.dart';
import '../../Models/menu_item_model.dart';
import '../../Models/package_model.dart';
import '../../Models/service_item_model.dart';
import '../../Services/service_item_service.dart';

const double _kPkgCreateWebBreak = 900;

/// Create a new package OR edit an existing one.
class CreatePackageScreen extends StatefulWidget {
  final String hallId;
  final PackageModel? existing;
  const CreatePackageScreen({super.key, required this.hallId, this.existing});
  @override
  State<CreatePackageScreen> createState() => _CreatePackageScreenState();
}

class _CreatePackageScreenState extends State<CreatePackageScreen> {
  int _currentStep = 0;

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _minController = TextEditingController();
  final _maxController = TextEditingController();
  final _priceController = TextEditingController();

  Set<String> _selectedMenuIds = {};
  Set<String> _selectedServiceIds = {};
  List<MenuItemModel> _menuItems = [];
  List<ServiceItemModel> _services = [];
  bool _loadingItems = true;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _prefill();
    _loadItems();
  }

  void _prefill() {
    if (!_isEditing) return;
    final e = widget.existing!;
    _nameController.text = e.name;
    _descController.text = e.description;
    _minController.text = e.capacityMin.toString();
    _maxController.text = e.capacityMax.toString();
    _priceController.text = e.price.toStringAsFixed(0);
    _selectedMenuIds = Set.from(e.menuItemIds);
    _selectedServiceIds = Set.from(e.serviceItemIds);
  }

  Future<void> _loadItems() async {
    final items = await MenuService.getMenuItems(widget.hallId);
    final services = await ServiceItemService.getServices(widget.hallId);
    if (mounted) {
      setState(() {
        _menuItems = items;
        _services = services;
        _loadingItems = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _minController.dispose();
    _maxController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) setState(() => _currentStep++);
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  void _goTo(int step) => setState(() => _currentStep = step);

  bool _validateStep1() {
    if (_nameController.text.trim().isEmpty) {
      _snack('Package Name is required.');
      return false;
    }
    final priceText = _priceController.text.trim();
    if (priceText.isEmpty) {
      _snack('Price is required.');
      return false;
    }
    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      _snack('Please enter a valid price.');
      return false;
    }

    if (_descController.text.trim().isEmpty) {
      _snack('Package Description is required.');
      return false;
    }
    if (_descController.text.trim().length < 10) {
      _snack('Package description must be at least 10 characters.');
      return false;
    }

    final minText = _minController.text.trim();
    final maxText = _maxController.text.trim();
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
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    String? error;
    if (_isEditing) {
      error = await PackageService.updatePackage(
        hallId: widget.hallId,
        packageId: widget.existing!.packageId,
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        capacityMin: int.tryParse(_minController.text.trim()) ?? 0,
        capacityMax: int.tryParse(_maxController.text.trim()) ?? 0,
        menuItemIds: _selectedMenuIds.toList(),
        serviceItemIds: _selectedServiceIds.toList(),
      );
    } else {
      error = await PackageService.createPackage(
        hallId: widget.hallId,
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        capacityMin: int.tryParse(_minController.text.trim()) ?? 0,
        capacityMax: int.tryParse(_maxController.text.trim()) ?? 0,
        menuItemIds: _selectedMenuIds.toList(),
        serviceItemIds: _selectedServiceIds.toList(),
      );
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (error != null) {
      _snack(error, isError: true);
    } else {
      _snack(_isEditing ? 'Package updated!' : 'Package created!');
      Navigator.pop(context);
    }
  }

  void _snack(String msg, {bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isError ? Colors.red : const Color(0xFFF47C20),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= _kPkgCreateWebBreak;
    final steps = [
      _buildStep1(isWide),
      _buildStep2(isWide),
      _buildReview(isWide),
    ];
    return isWide ? _buildWebLayout(steps) : _buildMobileLayout(steps);
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  WEB LAYOUT — improved design matching hall_registration_screen
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout(List<Widget> steps) {
    final stepTitles = ['Package Details', 'Items & Services', 'Review & Save'];
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      body: Row(
        children: [
          // ── Left sidebar (width 240, tighter spacing) ──────────────────
          Container(
            width: 240,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header height 56
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFF47C20), Color(0xFFFFD166)],
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.card_giftcard,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isEditing ? 'Edit Package' : 'Create Package',
                        style: const TextStyle(
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

                ...List.generate(3, (i) {
                  final isActive = i == _currentStep;
                  final isCompleted = i < _currentStep;
                  final color =
                      isActive
                          ? const Color(0xFFF47C20)
                          : isCompleted
                          ? const Color(0xFF10B981)
                          : Colors.grey[400]!;

                  return InkWell(
                    onTap: i <= _currentStep ? () => _goTo(i) : null,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      // Tighter padding: horizontal 14→12, vertical 12→10
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
                          // Circle size 28→24
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
                              stepTitles[i],
                              // Font size 14→13
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    isActive
                                        ? FontWeight.w600
                                        : FontWeight.normal,
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
          ),

          // ── Right content area ─────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Top header bar — height 64→52
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
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        stepTitles[_currentStep],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      // Orange pill instead of plain text
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
                          'Step ${_currentStep + 1} of 3',
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

                // Scrollable content — padding & max-width tightened
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
                            // White card wrapping step content
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

                            // Compact right-aligned Prev / Next
                            if (_currentStep < 2)
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
                                        if (_currentStep == 0 &&
                                            !_validateStep1()) {
                                          return;
                                        }
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

  // ════════════════════════════════════════════════════════════════════════════
  //  MOBILE LAYOUT (completely unchanged)
  // ════════════════════════════════════════════════════════════════════════════
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
        title: Text(
          _isEditing ? 'Edit Package' : 'Create Package',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
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
                                      if (_currentStep == 0 &&
                                          !_validateStep1()) {
                                        return;
                                      }
                                      _nextStep();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF47C20),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Next',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white,
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
    final titles = ['Package Details', 'Items & Services', 'Review'];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Row(
                children:
                    titles.asMap().entries.map((e) {
                      final isActive = e.key == _currentStep;
                      return Expanded(
                        child: Center(
                          child: Text(
                            e.value,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isActive ? FontWeight.w700 : FontWeight.w400,
                              color: isActive ? Colors.black : Colors.grey[400],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(3, (index) {
                  final isActive = index == _currentStep;
                  final isCompleted = index < _currentStep;
                  return Expanded(
                    child: Column(
                      children: [
                        Container(
                          height: 4,
                          margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
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

  // ── Step 1: Package Details ────────────────────────────────────────────────
  Widget _buildStep1(bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _webSectionTitle(
          'Package Details',
          'Name, price and capacity.',
          isWide,
        ),
        SizedBox(height: isWide ? 16 : 25),
        if (isWide) ...[
          Row(
            children: [
              Expanded(
                child: _field(
                  'Package Name',
                  _nameController,
                  'e.g. Wedding Gold Package',
                  isWide: isWide,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _field(
                  'Total Price (Rs.)',
                  _priceController,
                  'Enter price',
                  inputType: TextInputType.number,
                  isWide: isWide,
                ),
              ),
            ],
          ),
          _field(
            'Description',
            _descController,
            'Describe what makes this package special...',
            maxLines: 4,
            isWide: isWide,
          ),
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
                child: _simpleField(
                  _minController,
                  'Min Guests',
                  isWide: isWide,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _simpleField(
                  _maxController,
                  'Max Guests',
                  isWide: isWide,
                ),
              ),
            ],
          ),
        ] else ...[
          _field('Package Name', _nameController, 'e.g. Wedding Gold Package'),
          _field(
            'Description',
            _descController,
            'Describe what makes this package special...',
            maxLines: 4,
          ),
          const Text(
            'Guest Capacity',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _simpleField(_minController, 'Min Guests')),
              const SizedBox(width: 20),
              Expanded(child: _simpleField(_maxController, 'Max Guests')),
            ],
          ),
          const SizedBox(height: 16),
          _field(
            'Total Price (Rs.)',
            _priceController,
            'Enter price',
            inputType: TextInputType.number,
          ),
        ],
      ],
    );
  }

  // ── Step 2: Items & Services ───────────────────────────────────────────────
  Widget _buildStep2(bool isWide) {
    if (_loadingItems) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: Color(0xFFF47C20)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _webSectionTitle(
          'Items & Services',
          'Choose items for this bundle.',
          isWide,
        ),
        SizedBox(height: isWide ? 16 : 25),
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Menu Items',
                      style: TextStyle(
                        fontSize: isWide ? 12 : 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: isWide ? 6 : 10),
                    _menuItems.isEmpty
                        ? Text(
                          'No menu items found. Add items in Manage Menu first.',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        )
                        : _selectionBox(
                          items:
                              _menuItems
                                  .map(
                                    (i) => (
                                      id: i.itemId,
                                      title: i.name,
                                      sub: i.priceLabel,
                                    ),
                                  )
                                  .toList(),
                          selected: _selectedMenuIds,
                          onToggle:
                              (id) => setState(
                                () =>
                                    _selectedMenuIds.contains(id)
                                        ? _selectedMenuIds.remove(id)
                                        : _selectedMenuIds.add(id),
                              ),
                          isWide: isWide,
                        ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Additional Services',
                      style: TextStyle(
                        fontSize: isWide ? 12 : 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: isWide ? 6 : 10),
                    _services.isEmpty
                        ? Text(
                          'No services found. Add services in Manage Services first.',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        )
                        : _selectionBox(
                          items:
                              _services
                                  .map(
                                    (s) => (
                                      id: s.serviceId,
                                      title: s.name,
                                      sub: s.priceLabel,
                                    ),
                                  )
                                  .toList(),
                          selected: _selectedServiceIds,
                          onToggle:
                              (id) => setState(
                                () =>
                                    _selectedServiceIds.contains(id)
                                        ? _selectedServiceIds.remove(id)
                                        : _selectedServiceIds.add(id),
                              ),
                          isWide: isWide,
                        ),
                  ],
                ),
              ),
            ],
          )
        else ...[
          const Text(
            'Select Menu Items',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          _menuItems.isEmpty
              ? Text(
                'No menu items found.',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              )
              : _selectionBox(
                items:
                    _menuItems
                        .map(
                          (i) => (
                            id: i.itemId,
                            title: i.name,
                            sub: i.priceLabel,
                          ),
                        )
                        .toList(),
                selected: _selectedMenuIds,
                onToggle:
                    (id) => setState(
                      () =>
                          _selectedMenuIds.contains(id)
                              ? _selectedMenuIds.remove(id)
                              : _selectedMenuIds.add(id),
                    ),
              ),
          const SizedBox(height: 25),
          const Text(
            'Select Additional Services',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          _services.isEmpty
              ? Text(
                'No services found.',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              )
              : _selectionBox(
                items:
                    _services
                        .map(
                          (s) => (
                            id: s.serviceId,
                            title: s.name,
                            sub: s.priceLabel,
                          ),
                        )
                        .toList(),
                selected: _selectedServiceIds,
                onToggle:
                    (id) => setState(
                      () =>
                          _selectedServiceIds.contains(id)
                              ? _selectedServiceIds.remove(id)
                              : _selectedServiceIds.add(id),
                    ),
              ),
        ],
      ],
    );
  }

  Widget _selectionBox({
    required List<({String id, String title, String sub})> items,
    required Set<String> selected,
    required void Function(String id) onToggle,
    bool isWide = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isWide ? 12 : 15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(isWide ? 10 : 12),
      ),
      child: Column(
        children:
            items.asMap().entries.map((e) {
              final item = e.value;
              final isAdded = selected.contains(item.id);
              final isLast = e.key == items.length - 1;
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: isWide ? 13 : 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.sub,
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: isWide ? 12 : 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => onToggle(item.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          // Button size 80×35 → 70×30 on web
                          width: isWide ? 70 : 80,
                          height: isWide ? 30 : 35,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color:
                                isAdded
                                    ? Colors.redAccent
                                    : const Color(0xFFF47C20),
                            borderRadius: BorderRadius.circular(isWide ? 6 : 8),
                          ),
                          child: Text(
                            isAdded ? 'Remove' : 'Add',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isWide ? 12 : 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!isLast) Divider(height: isWide ? 16 : 20),
                ],
              );
            }).toList(),
      ),
    );
  }

  // ── Step 3: Review ─────────────────────────────────────────────────────────
  Widget _buildReview(bool isWide) {
    final selectedMenu =
        _menuItems.where((i) => _selectedMenuIds.contains(i.itemId)).toList();
    final selectedSvc =
        _services
            .where((s) => _selectedServiceIds.contains(s.serviceId))
            .toList();

    final summaryCard = _reviewCard('Package Summary', 0, isWide, [
      _reviewRow(
        Icons.card_giftcard,
        'Package Name',
        _nameController.text.trim().isEmpty ? '—' : _nameController.text.trim(),
        isWide: isWide,
      ),
      _reviewRow(
        Icons.monetization_on_outlined,
        'Total Price',
        'Rs. ${_priceController.text.trim()}',
        valueColor: const Color(0xFFF47C20),
        isWide: isWide,
      ),
      _reviewRow(
        Icons.groups_outlined,
        'Capacity',
        '${_minController.text} – ${_maxController.text} Guests',
        isWide: isWide,
      ),
      if (_descController.text.trim().isNotEmpty)
        _reviewRow(
          Icons.description_outlined,
          'Description',
          _descController.text.trim(),
          isWide: isWide,
        ),
    ]);

    final includesCard = _reviewCard('Includes', 1, isWide, [
      if (selectedMenu.isNotEmpty) ...[
        Text(
          'MENU ITEMS',
          style: TextStyle(
            fontSize: isWide ? 10 : 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: isWide ? 6 : 8),
        ...selectedMenu.map(
          (i) => _itemRow(i.name, i.priceLabel, isWide: isWide),
        ),
        SizedBox(height: isWide ? 12 : 16),
      ],
      if (selectedSvc.isNotEmpty) ...[
        Text(
          'SERVICES',
          style: TextStyle(
            fontSize: isWide ? 10 : 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: isWide ? 6 : 8),
        ...selectedSvc.map(
          (s) => _itemRow(s.name, s.priceLabel, isWide: isWide),
        ),
      ],
      if (selectedMenu.isEmpty && selectedSvc.isEmpty)
        Text(
          'No items or services selected.',
          style: TextStyle(color: Colors.grey[400], fontSize: isWide ? 12 : 14),
        ),
    ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _webSectionTitle(
          'Review & Save',
          'Review your new package and save it.',
          isWide,
        ),
        SizedBox(height: isWide ? 16 : 25),
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: summaryCard),
              const SizedBox(width: 12),
              Expanded(child: includesCard),
            ],
          )
        else ...[
          summaryCard,
          const SizedBox(height: 20),
          includesCard,
        ],
        SizedBox(height: isWide ? 24 : 40),
        // Save button — reduced on web (52→42, font 16→14, radius 12→8)
        SizedBox(
          width: double.infinity,
          height: isWide ? 42 : 52,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF47C20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isWide ? 8 : 12),
              ),
            ),
            child:
                _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                      _isEditing ? 'Save Changes' : 'Create Package',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isWide ? 14 : 16,
                        color: Colors.white,
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  SHARED HELPERS (all isWide-aware)
  // ════════════════════════════════════════════════════════════════════════════

  /// Section title — 24→18px on web
  Widget _webSectionTitle(String title, String subtitle, bool isWide) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: isWide ? 18 : 24,
          fontWeight: FontWeight.w700,
        ),
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

  /// Review card — padding 20→16, radius 16→12, title font 16→14 on web
  Widget _reviewCard(
    String title,
    int step,
    bool isWide,
    List<Widget> children,
  ) => Container(
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
              onTap: () => _goTo(step),
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

  /// Review row — icon 18→15, fonts 14→11/12, gap 12→8 on web
  Widget _reviewRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    bool isWide = false,
  }) => Padding(
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
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  /// Item row in review card — font 14→12 on web
  Widget _itemRow(String name, String price, {bool isWide = false}) => Padding(
    padding: EdgeInsets.only(bottom: isWide ? 3 : 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: isWide ? 12 : 14,
          ),
        ),
        Text(
          price,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isWide ? 12 : 14,
            color: const Color(0xFFF47C20),
          ),
        ),
      ],
    ),
  );

  /// Labelled form field — label 13→12, input 14→13, gap 16→12 on web
  Widget _field(
    String label,
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
    TextInputType? inputType,
    bool isWide = false,
  }) => Padding(
    padding: EdgeInsets.only(bottom: isWide ? 12 : 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isWide ? 12 : 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: isWide ? 6 : 8),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: inputType,
          style: TextStyle(fontSize: isWide ? 13 : 14),
          decoration: _inputDec(hint, isWide: isWide),
        ),
      ],
    ),
  );

  /// Bare field (no label) — used for capacity min/max
  Widget _simpleField(
    TextEditingController ctrl,
    String hint, {
    bool isWide = false,
  }) => TextFormField(
    controller: ctrl,
    keyboardType: TextInputType.number,
    style: TextStyle(fontSize: isWide ? 13 : 14),
    decoration: _inputDec(hint, isWide: isWide),
  );

  /// Input decoration — content padding & hint font scale with isWide
  InputDecoration _inputDec(String hint, {bool isWide = false}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: isWide ? 13 : 14,
        ),
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
}
