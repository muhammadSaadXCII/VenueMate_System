import 'package:flutter/material.dart';
import 'package:venuemate_system/Models/hall_model.dart';
import 'package:venuemate_system/Models/menu_item_model.dart';
import 'package:venuemate_system/Models/service_item_model.dart';
import 'package:venuemate_system/Services/menu_service.dart';
import 'package:venuemate_system/Services/service_item_service.dart';

import 'PaymentScreen.dart';

class CustomizeEventScreen extends StatefulWidget {
  final HallModel hall;

  // ── Data from Step 1 ──────────────────────────────────────────────────────
  final String customerName;
  final String customerPhone;
  final String customerCnic;
  final String customerEmail;

  // ── Data from Step 2 ──────────────────────────────────────────────────────
  final String eventName;
  final int guestCount;
  final String timeSlot;
  final DateTime eventDate;

  const CustomizeEventScreen({
    super.key,
    required this.hall,
    required this.customerName,
    required this.customerPhone,
    required this.customerCnic,
    required this.customerEmail,
    required this.eventName,
    required this.guestCount,
    required this.timeSlot,
    required this.eventDate,
  });

  @override
  State<CustomizeEventScreen> createState() => _CustomizeEventScreenState();
}

class _CustomizeEventScreenState extends State<CustomizeEventScreen> {
  // ── Firebase data ──────────────────────────────────────────────────────────
  List<MenuItemModel> _menuItems = [];
  List<ServiceItemModel> _services = [];
  bool _loadingMenu = true;
  bool _loadingServ = true;

  // ── Selected items (toggled by customer) ──────────────────────────────────
  final Set<String> _selectedMenuIds = {};
  final Set<String> _selectedServiceIds = {};

  // ── View more toggle ───────────────────────────────────────────────────────
  bool _showAllMenu = false;
  bool _showAllServices = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final hallId = widget.hall.hallId;

    final menuItems = await MenuService.getMenuItems(hallId);
    final services = await ServiceItemService.getServices(hallId);

    if (mounted) {
      setState(() {
        _menuItems = menuItems.where((m) => m.isAvailable).toList();
        _services = services;
        _loadingMenu = false;
        _loadingServ = false;
      });
    }
  }

  /// Price per guest × guest count = total for that menu item
  double _menuItemTotal(MenuItemModel item) => item.price * widget.guestCount;

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _navigateToNext() {
    final selectedMenuItems =
        _menuItems.where((m) => _selectedMenuIds.contains(m.itemId)).toList();
    final selectedServices =
        _services
            .where((s) => _selectedServiceIds.contains(s.serviceId))
            .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PaymentScreen(
              hall: widget.hall,
              customerName: widget.customerName,
              customerPhone: widget.customerPhone,
              customerCnic: widget.customerCnic,
              customerEmail: widget.customerEmail,
              eventName: widget.eventName,
              guestCount: widget.guestCount,
              timeSlot: widget.timeSlot,
              eventDate: widget.eventDate,
              selectedMenuItems: selectedMenuItems,
              selectedServices: selectedServices,
            ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Customize event',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildStepIndicator(3),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customize Event',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select items from ${widget.hall.hallName}\'s menu and services',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),

                  // ── Guest count info banner ────────────────────────────────
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.people_outline,
                          color: Color(0xFFF97316),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Menu prices shown for ${widget.guestCount} guests',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF92400E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Menu Items ─────────────────────────────────────────────
                  const Text(
                    'Select Menu Items',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMenuSection(),

                  const SizedBox(height: 24),

                  // ── Services ───────────────────────────────────────────────
                  const Text(
                    'Select Additional Services',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildServicesSection(),

                  const SizedBox(height: 24),

                  // ── Selection Summary ──────────────────────────────────────
                  if (_selectedMenuIds.isNotEmpty ||
                      _selectedServiceIds.isNotEmpty)
                    _buildSelectionSummary(),

                  const SizedBox(height: 32),

                  // ── Navigation Buttons ─────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFF97316)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Prev',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFF97316),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _navigateToNext,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF97316),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Next',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
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

  // ── Menu Section ───────────────────────────────────────────────────────────

  Widget _buildMenuSection() {
    if (_loadingMenu) return _buildLoader();

    if (_menuItems.isEmpty) {
      return _buildEmptyState('No menu items added by this hall yet.');
    }

    final visible = _showAllMenu ? _menuItems : _menuItems.take(3).toList();

    return Column(
      children: [
        ...visible.map((item) => _buildMenuCard(item)),
        if (_menuItems.length > 3)
          TextButton(
            onPressed: () => setState(() => _showAllMenu = !_showAllMenu),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              _showAllMenu
                  ? 'Show less'
                  : 'View ${_menuItems.length - 3} more items...',
              style: const TextStyle(
                color: Color(0xFFF97316),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMenuCard(MenuItemModel item) {
    final isAdded = _selectedMenuIds.contains(item.itemId);
    final totalPrice = _menuItemTotal(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isAdded ? const Color(0xFFFFF7ED) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAdded ? const Color(0xFFFED7AA) : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          // ── Image thumbnail ────────────────────────────────────────────
          if (item.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                item.imageUrl,
                width: 46,
                height: 46,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          if (item.imageUrl.isNotEmpty) const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                if (item.description.isNotEmpty)
                  Text(
                    item.description,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                // ── Per-guest price ────────────────────────────────────
                Text(
                  'Rs. ${item.price.toStringAsFixed(0)} × ${widget.guestCount} guests',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                const SizedBox(height: 2),
                // ── Total price for all guests ─────────────────────────
                Text(
                  'Rs. ${totalPrice.toStringAsFixed(0)} total',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFF97316),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 65,
            height: 30,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  if (isAdded) {
                    _selectedMenuIds.remove(item.itemId);
                  } else {
                    _selectedMenuIds.add(item.itemId);
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isAdded ? const Color(0xFF10B981) : const Color(0xFFF97316),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: EdgeInsets.zero,
                elevation: 0,
              ),
              child: Text(
                isAdded ? 'Added' : 'Add',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Services Section ───────────────────────────────────────────────────────

  Widget _buildServicesSection() {
    if (_loadingServ) return _buildLoader();

    if (_services.isEmpty) {
      return _buildEmptyState('No additional services added by this hall.');
    }

    final visible = _showAllServices ? _services : _services.take(3).toList();

    return Column(
      children: [
        ...visible.map((svc) => _buildServiceCard(svc)),
        if (_services.length > 3)
          TextButton(
            onPressed:
                () => setState(() => _showAllServices = !_showAllServices),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              _showAllServices
                  ? 'Show less'
                  : 'View ${_services.length - 3} more services...',
              style: const TextStyle(
                color: Color(0xFFF97316),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildServiceCard(ServiceItemModel svc) {
    final isAdded = _selectedServiceIds.contains(svc.serviceId);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isAdded ? const Color(0xFFFFF7ED) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAdded ? const Color(0xFFFED7AA) : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.room_service_outlined,
              color: Color(0xFFF97316),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  svc.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                if (svc.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    svc.description,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                // Services are flat per-event price, not multiplied by guests
                Text(
                  'Rs. ${svc.price.toStringAsFixed(0)} / Event',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFF97316),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 65,
            height: 30,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  if (isAdded) {
                    _selectedServiceIds.remove(svc.serviceId);
                  } else {
                    _selectedServiceIds.add(svc.serviceId);
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isAdded ? const Color(0xFF10B981) : const Color(0xFFF97316),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: EdgeInsets.zero,
                elevation: 0,
              ),
              child: Text(
                isAdded ? 'Added' : 'Add',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Selection Summary Card ─────────────────────────────────────────────────

  Widget _buildSelectionSummary() {
    // Menu total = price per guest × guest count × number of selected items
    final menuTotal = _menuItems
        .where((m) => _selectedMenuIds.contains(m.itemId))
        .fold(0.0, (s, m) => s + _menuItemTotal(m));

    // Services are flat per-event prices — no guest multiplication
    final svcTotal = _services
        .where((s) => _selectedServiceIds.contains(s.serviceId))
        .fold(0.0, (s, svc) => s + svc.price);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        children: [
          if (_selectedMenuIds.isNotEmpty)
            _buildSummaryRow(
              'Menu (${_selectedMenuIds.length} item${_selectedMenuIds.length > 1 ? 's' : ''} × ${widget.guestCount} guests)',
              'Rs. ${menuTotal.toStringAsFixed(0)}',
            ),
          if (_selectedServiceIds.isNotEmpty)
            _buildSummaryRow(
              'Services (${_selectedServiceIds.length})',
              'Rs. ${svcTotal.toStringAsFixed(0)}',
            ),
          const Divider(height: 16),
          _buildSummaryRow(
            'Extras Subtotal',
            'Rs. ${(menuTotal + svcTotal).toStringAsFixed(0)}',
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: const Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }

  // ── Utilities ──────────────────────────────────────────────────────────────

  Widget _buildLoader() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 24),
    child: Center(child: CircularProgressIndicator(color: Color(0xFFF97316))),
  );

  Widget _buildEmptyState(String message) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline, color: Colors.grey[400], size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ),
      ],
    ),
  );

  Widget _buildStepIndicator(int currentStep) {
    final steps = [
      'Basic Details',
      'Event Details',
      'Customize event',
      'Payment',
    ];
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children:
                steps.asMap().entries.map((e) {
                  final isActive = (e.key + 1) == currentStep;
                  return Expanded(
                    child: Center(
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
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
            children: List.generate(steps.length, (index) {
              final stepNum = index + 1;
              final isActive = stepNum == currentStep;
              final isDone = stepNum < currentStep;
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 3,
                      margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                      decoration: BoxDecoration(
                        color:
                            (isActive || isDone)
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
                            isDone
                                ? const Color(0xFF10B981)
                                : isActive
                                ? const Color(0xFFF97316)
                                : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child:
                            isDone
                                ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 14,
                                )
                                : Text(
                                  '$stepNum',
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
        const SizedBox(height: 16),
      ],
    );
  }
}
