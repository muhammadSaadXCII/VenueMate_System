import 'package:flutter/material.dart';
import 'package:venuemate_system/Models/hall_model.dart';
import 'package:venuemate_system/Services/booking_service.dart';
import 'CustomizeEventScreen.dart';

class EventDetailsScreen extends StatefulWidget {
  final HallModel hall;
  final String customerName;
  final String customerPhone;
  final String customerCnic;
  final String customerEmail;

  const EventDetailsScreen({
    Key? key,
    required this.hall,
    required this.customerName,
    required this.customerPhone,
    required this.customerCnic,
    required this.customerEmail,
  }) : super(key: key);

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _guestCountController = TextEditingController();

  String _selectedTimeSlot = 'Morning';
  DateTime? _selectedDate;

  /// Availability fetched after user picks date+slot.
  SlotAvailability? _availability;
  bool _checkingAvailability = false;

  @override
  void dispose() {
    _eventNameController.dispose();
    _guestCountController.dispose();
    super.dispose();
  }

  // ── Date Picker ────────────────────────────────────────────────────────────

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime(DateTime.now().year + 2),
      builder:
          (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFFF97316),
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _availability = null; // reset when date changes
      });
      await _fetchAvailability();
    }
  }

  // ── Slot button tap also refreshes availability ─────────────────────────

  void _onSlotChanged(String slot) {
    setState(() {
      _selectedTimeSlot = slot;
      _availability = null;
    });
    if (_selectedDate != null) _fetchAvailability();
  }

  Future<void> _fetchAvailability() async {
    if (_selectedDate == null) return;
    setState(() => _checkingAvailability = true);
    final avail = await BookingService.checkSlotAvailability(
      hallId: widget.hall.hallId,
      date: _selectedDate!,
      timeSlot: _selectedTimeSlot,
      hallCapacityMax: widget.hall.capacityMax,
    );
    if (mounted) {
      setState(() {
        _availability = avail;
        _checkingAvailability = false;
      });
    }
  }

  // ── Validators ─────────────────────────────────────────────────────────────

  String? _validateEventName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Event name is required';
    if (v.trim().length < 3) return 'Please enter a descriptive event name';
    return null;
  }

  String? _validateGuestCount(String? v) {
    if (v == null || v.trim().isEmpty) return 'Guest count is required';
    final n = int.tryParse(v.trim());
    if (n == null) return 'Enter a valid number';
    if (n < widget.hall.capacityMin) {
      return 'Minimum capacity for this hall is ${widget.hall.capacityMin} guests';
    }
    if (n > widget.hall.capacityMax) {
      return 'Maximum capacity for this hall is ${widget.hall.capacityMax} guests';
    }
    if (_availability != null && n > _availability!.remainingSlots) {
      return 'Only ${_availability!.remainingSlots} guest slots remain for this date & slot';
    }
    return null;
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  Future<void> _navigateToNext() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      _showSnack('Please select an event date', Colors.red);
      return;
    }

    // Re-fetch availability before proceeding
    setState(() => _checkingAvailability = true);
    final avail = await BookingService.checkSlotAvailability(
      hallId: widget.hall.hallId,
      date: _selectedDate!,
      timeSlot: _selectedTimeSlot,
      hallCapacityMax: widget.hall.capacityMax,
    );
    if (!mounted) return;
    setState(() {
      _availability = avail;
      _checkingAvailability = false;
    });

    final guests = int.tryParse(_guestCountController.text.trim()) ?? 0;
    if (avail.isFullyBooked) {
      _showSnack(
        'Sorry! This slot is fully booked for the selected date.',
        Colors.red,
      );
      return;
    }
    if (guests > avail.remainingSlots) {
      _showSnack(
        'Only ${avail.remainingSlots} guest slots remain for the $_selectedTimeSlot slot on this date.',
        Colors.red,
      );
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => CustomizeEventScreen(
              hall: widget.hall,
              customerName: widget.customerName,
              customerPhone: widget.customerPhone,
              customerCnic: widget.customerCnic,
              customerEmail: widget.customerEmail,
              eventName: _eventNameController.text.trim(),
              guestCount: guests,
              timeSlot: _selectedTimeSlot,
              eventDate: _selectedDate!,
            ),
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
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
          'Event Details',
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
          _buildStepIndicator(2),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Event Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Capacity info
                    _infoBox(
                      icon: Icons.people_outline,
                      text:
                          '${widget.hall.hallName} handles up to ${widget.hall.capacityMax} guests per slot. '
                          'Each slot (Morning & Evening) is tracked independently.',
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Event Name'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _eventNameController,
                      hintText: 'Birthday, Marriage, Corporate etc.',
                      validator: _validateEventName,
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Number of Guests'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _guestCountController,
                      hintText: 'e.g. 150',
                      keyboardType: TextInputType.number,
                      validator: _validateGuestCount,
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Select Time Slot'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildSlotButton('Morning')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildSlotButton('Evening')),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Select Date'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDate != null
                                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                  : 'Select event date',
                              style: TextStyle(
                                color:
                                    _selectedDate != null
                                        ? Colors.black
                                        : Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                            Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Availability chip
                    if (_selectedDate != null) ...[
                      const SizedBox(height: 12),
                      _buildAvailabilityChip(),
                    ],

                    if (_selectedDate != null) ...[
                      const SizedBox(height: 16),
                      _buildCalendarPreview(),
                    ],

                    const SizedBox(height: 32),

                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFF97316),
                                ),
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
                              onPressed:
                                  _checkingAvailability
                                      ? null
                                      : _navigateToNext,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF97316),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child:
                                  _checkingAvailability
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Text(
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
          ),
        ],
      ),
    );
  }

  // ── Availability Chip ──────────────────────────────────────────────────────

  Widget _buildAvailabilityChip() {
    if (_checkingAvailability) {
      return const Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFF97316),
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Checking availability…',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      );
    }
    if (_availability == null) return const SizedBox.shrink();

    final a = _availability!;
    final isFull = a.isFullyBooked;
    final bgColor = isFull ? const Color(0xFFFFE4E4) : const Color(0xFFE4F9ED);
    final txtColor = isFull ? Colors.red[700]! : Colors.green[700]!;
    final icon = isFull ? Icons.block_outlined : Icons.check_circle_outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: txtColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isFull
                  ? 'This slot is fully booked for the selected date.'
                  : '${a.remainingSlots} of ${a.hallCapacityMax} guest slots still available for this date & slot.',
              style: TextStyle(
                fontSize: 12,
                color: txtColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Slot Button ────────────────────────────────────────────────────────────

  Widget _buildSlotButton(String label) {
    final isSelected = _selectedTimeSlot == label;
    return GestureDetector(
      onTap: () => _onSlotChanged(label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF97316) : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  // ── Info box ───────────────────────────────────────────────────────────────

  Widget _infoBox({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFF97316), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Calendar Preview ───────────────────────────────────────────────────────

  Widget _buildCalendarPreview() {
    final current = _selectedDate!;
    final daysInMonth = DateTime(current.year, current.month + 1, 0).day;
    final firstWeekday = DateTime(current.year, current.month, 1).weekday;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed:
                    () => setState(() {
                      _selectedDate = DateTime(
                        current.year,
                        current.month - 1,
                        1,
                      );
                      _availability = null;
                    }),
              ),
              Text(
                '${_monthName(current.month)} ${current.year}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed:
                    () => setState(() {
                      _selectedDate = DateTime(
                        current.year,
                        current.month + 1,
                        1,
                      );
                      _availability = null;
                    }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
                ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
                    .map(
                      (d) => SizedBox(
                        width: 28,
                        child: Center(
                          child: Text(
                            d,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 8),
          ...List.generate(6, (week) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (day) {
                  final dayNum = week * 7 + day + 1 - (firstWeekday - 1);
                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return const SizedBox(width: 28, height: 28);
                  }
                  final isSel = _selectedDate?.day == dayNum;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = DateTime(
                          current.year,
                          current.month,
                          dayNum,
                        );
                        _availability = null;
                      });
                      _fetchAvailability();
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color:
                            isSel
                                ? const Color(0xFFF97316)
                                : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$dayNum',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isSel ? FontWeight.bold : FontWeight.normal,
                            color: isSel ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────

  Widget _buildLabel(String label) => Text(
    label,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    ),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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
          borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      validator: validator,
    );
  }

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

  String _monthName(int m) =>
      const [
        '',
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ][m];
}
