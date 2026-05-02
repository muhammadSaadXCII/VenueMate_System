import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:venuemate_system/Models/booking_model.dart';
import 'package:venuemate_system/Models/hall_model.dart';
import 'package:venuemate_system/Services/booking_service.dart';
import 'package:venuemate_system/Services/hall_service.dart';
import 'package:venuemate_system/Widgets/common_button.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  BREAKPOINT — matches the root layout's _kHallWebBreak = 950
// ══════════════════════════════════════════════════════════════════════════════

const double _kBookingsWebBreak = 950;

// ══════════════════════════════════════════════════════════════════════════════
//  HALL ADMIN BOOKINGS SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class HallAdminBookingsScreen extends StatefulWidget {
  const HallAdminBookingsScreen({super.key});

  @override
  State<HallAdminBookingsScreen> createState() =>
      _HallAdminBookingsScreenState();
}

class _HallAdminBookingsScreenState extends State<HallAdminBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  HallModel? _hall;
  bool _loadingHall = true;
  Stream<HallModel?>? _hallStream;

  // ── Cached streams — created ONCE when hall loads, never recreated on rebuild
  Stream<List<BookingModel>>? _upcomingStream;
  Stream<List<BookingModel>>? _pendingStream;
  Stream<List<BookingModel>>? _completedStream;
  Stream<List<BookingModel>>? _cancelledStream;

  static const _tabs = ['Upcoming', 'Pending', 'Completed', 'Cancelled'];

  static const _tabColors = [
    Color(0xFF059669), // Upcoming  — green
    Color(0xFFFBC02D), // Pending   — amber
    Color(0xFF388E3C), // Completed — dark-green
    Color(0xFFD32F2F), // Cancelled — red
  ];

  static const _tabIcons = [
    Icons.event_available_outlined,
    Icons.hourglass_empty_outlined,
    Icons.check_circle_outline,
    Icons.cancel_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadHall();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHall() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loadingHall = false);
      return;
    }

    // Use a one-time fetch to initialise booking streams, then keep a
    // real-time stream so isVisible changes are reflected immediately.
    final hall = await HallService.getHallByOwnerId(uid);
    if (mounted) {
      setState(() {
        _hall = hall;
        _loadingHall = false;
        if (hall != null) {
          _upcomingStream = BookingService.streamUpcomingBookings(hall.hallId);
          _pendingStream = BookingService.streamPendingBookings(hall.hallId);
          _completedStream = BookingService.streamCompletedBookings(
            hall.hallId,
          );
          _cancelledStream = BookingService.streamCancelledBookings(
            hall.hallId,
          );
          // Keep watching for isVisible / status changes in real-time
          _hallStream = HallService.streamHallByOwnerId(uid);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingHall) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF47C20)),
      );
    }
    if (_hall == null) return _buildNoHall();

    // Wrap in a StreamBuilder so the UI reacts instantly when the system
    // admin toggles isVisible without requiring a restart.
    return StreamBuilder<HallModel?>(
      stream: _hallStream,
      initialData: _hall,
      builder: (context, snap) {
        final hall = snap.data ?? _hall!;

        // ── Hall is disabled: show a full-screen blocked state ───────────────
        if (!hall.isVisible) {
          return _buildDisabledState(hall);
        }

        // ── Hall is active: normal bookings UI ───────────────────────────────
        final isWide = MediaQuery.of(context).size.width >= _kBookingsWebBreak;
        return isWide ? _buildWebLayout() : _buildMobileLayout();
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  WEB LAYOUT  —  top bar + left filter panel + content grid
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildWebLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // ── Top bar ───────────────────────────────────────────────────────
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: Color(0xFFF47C20),
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Bookings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF47C20).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _hall?.hallName ?? '',
                    style: const TextStyle(
                      color: Color(0xFFF47C20),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Body: side panel + content ────────────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWebSidePanel(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _BookingTab(
                        stream: _upcomingStream!,
                        tabLabel: 'Upcoming',
                        hall: _hall!,
                        emptyMessage: 'No upcoming confirmed bookings yet.',
                        isWeb: true,
                      ),
                      _BookingTab(
                        stream: _pendingStream!,
                        tabLabel: 'Pending',
                        hall: _hall!,
                        emptyMessage: 'No pending receipts to verify.',
                        isWeb: true,
                      ),
                      _BookingTab(
                        stream: _completedStream!,
                        tabLabel: 'Completed',
                        hall: _hall!,
                        emptyMessage: 'No completed events yet.',
                        isWeb: true,
                      ),
                      _BookingTab(
                        stream: _cancelledStream!,
                        tabLabel: 'Cancelled',
                        hall: _hall!,
                        emptyMessage: 'No cancelled bookings.',
                        isWeb: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebSidePanel() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        final selected = _tabController.index;
        return Container(
          width: 220,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  'FILTER BY STATUS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[400],
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              ...List.generate(_tabs.length, (i) {
                final isActive = selected == i;
                final color = _tabColors[i];
                return InkWell(
                  onTap: () => _tabController.animateTo(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 3,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isActive
                              ? color.withOpacity(0.10)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border:
                          isActive
                              ? Border.all(color: color.withOpacity(0.25))
                              : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _tabIcons[i],
                          size: 18,
                          color: isActive ? color : Colors.grey[500],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _tabs[i],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  isActive
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                              color: isActive ? color : Colors.grey[600],
                            ),
                          ),
                        ),
                        if (isActive)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  MOBILE LAYOUT  —  original design, unchanged
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Bookings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildTabBar(),
          const SizedBox(height: 20),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _BookingTab(
                  stream: _upcomingStream!,
                  tabLabel: 'Upcoming',
                  hall: _hall!,
                  emptyMessage: 'No upcoming confirmed bookings yet.',
                  isWeb: false,
                ),
                _BookingTab(
                  stream: _pendingStream!,
                  tabLabel: 'Pending',
                  hall: _hall!,
                  emptyMessage: 'No pending receipts to verify.',
                  isWeb: false,
                ),
                _BookingTab(
                  stream: _completedStream!,
                  tabLabel: 'Completed',
                  hall: _hall!,
                  emptyMessage: 'No completed events yet.',
                  isWeb: false,
                ),
                _BookingTab(
                  stream: _cancelledStream!,
                  tabLabel: 'Cancelled',
                  hall: _hall!,
                  emptyMessage: 'No cancelled bookings.',
                  isWeb: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: const Color(0xFFF47C20),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade700,
        labelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        padding: EdgeInsets.zero,
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  // ── Hall disabled by system admin ─────────────────────────────────────────
  Widget _buildDisabledState(HallModel hall) {
    final reason = hall.disabledReason.trim();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD92D20).withOpacity(0.15),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.block_rounded,
                  size: 52,
                  color: Color(0xFFD92D20),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Bookings Disabled',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your hall has been disabled by the system administrator. '
                'You cannot receive or manage bookings at this time.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.6,
                ),
              ),
              if (reason.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFFD166).withOpacity(0.6),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Color(0xFF856404),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Reason given by admin',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF856404),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reason,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF533F03),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Please contact support if you believe this is a mistake.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoHall() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.store_outlined, size: 60, color: Colors.grey[400]),
        const SizedBox(height: 12),
        Text(
          'No hall registered.',
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  BOOKING TAB  (one per tab)
// ══════════════════════════════════════════════════════════════════════════════

class _BookingTab extends StatelessWidget {
  final Stream<List<BookingModel>> stream;
  final String tabLabel;
  final HallModel hall;
  final String emptyMessage;
  final bool isWeb;

  const _BookingTab({
    required this.stream,
    required this.tabLabel,
    required this.hall,
    required this.emptyMessage,
    required this.isWeb,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BookingModel>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFF47C20)),
          );
        }
        final bookings = snap.data ?? [];
        if (bookings.isEmpty) return _emptyState();

        if (isWeb) {
          // Two-column self-sizing layout — cards grow to fit content, no
          // fixed aspect ratio, so there is never empty space at the bottom.
          return LayoutBuilder(
            builder: (context, constraints) {
              final twoCol = constraints.maxWidth > 800;
              return ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount:
                    twoCol ? (bookings.length / 2).ceil() : bookings.length,
                itemBuilder: (_, rowIdx) {
                  if (!twoCol) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _AdminBookingCard(
                        booking: bookings[rowIdx],
                        tabLabel: tabLabel,
                        hall: hall,
                        isWeb: true,
                      ),
                    );
                  }
                  // Two-column row — IntrinsicHeight lets both cards share the
                  // height of whichever is taller; no blank space at the bottom.
                  final left = rowIdx * 2;
                  final right = left + 1;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _AdminBookingCard(
                              booking: bookings[left],
                              tabLabel: tabLabel,
                              hall: hall,
                              isWeb: true,
                            ),
                          ),
                          if (right < bookings.length) ...[
                            const SizedBox(width: 20),
                            Expanded(
                              child: _AdminBookingCard(
                                booking: bookings[right],
                                tabLabel: tabLabel,
                                hall: hall,
                                isWeb: true,
                              ),
                            ),
                          ] else
                            const Expanded(child: SizedBox()),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        }

        // Mobile: original ListView
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: bookings.length,
          itemBuilder:
              (_, i) => _AdminBookingCard(
                booking: bookings[i],
                tabLabel: tabLabel,
                hall: hall,
                isWeb: false,
              ),
        );
      },
    );
  }

  Widget _emptyState() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[400]),
        const SizedBox(height: 12),
        Text(
          emptyMessage,
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  ADMIN BOOKING CARD
// ══════════════════════════════════════════════════════════════════════════════

class _AdminBookingCard extends StatelessWidget {
  final BookingModel booking;
  final String tabLabel;
  final HallModel hall;
  final bool isWeb;

  const _AdminBookingCard({
    required this.booking,
    required this.tabLabel,
    required this.hall,
    required this.isWeb,
  });

  Color get _badgeBg {
    switch (tabLabel) {
      case 'Pending':
        return const Color(0xFFFFF9C4);
      case 'Upcoming':
        return const Color(0xFFD1FAE5);
      case 'Completed':
        return const Color(0xFFC8E6C9);
      case 'Cancelled':
        return const Color(0xFFFFCDD2);
      default:
        return Colors.grey.shade200;
    }
  }

  Color get _badgeColor {
    switch (tabLabel) {
      case 'Pending':
        return const Color(0xFFFBC02D);
      case 'Upcoming':
        return const Color(0xFF059669);
      case 'Completed':
        return const Color(0xFF388E3C);
      case 'Cancelled':
        return const Color(0xFFD32F2F);
      default:
        return Colors.grey;
    }
  }

  String get _badgeLabel {
    if (tabLabel == 'Upcoming') {
      final days = booking.daysUntilEvent;
      if (days == 0) return 'Today';
      if (days <= 3) return 'In $days day${days > 1 ? 's' : ''}';
      return 'Upcoming';
    }
    return tabLabel;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: isWeb ? EdgeInsets.zero : const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header row ──────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child:
                    hall.imageUrls.isNotEmpty
                        ? Image.network(
                          hall.imageUrls.first,
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imageFallback(),
                        )
                        : _imageFallback(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.eventName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: Color(0xFFF47C20),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              booking.shortDateLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _badgeBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _badgeLabel,
                            style: TextStyle(
                              color: _badgeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${booking.timeSlot} Slot',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFF97316),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _richText('Customer: ', booking.customerName),
                    const SizedBox(height: 2),
                    _richText('Guests: ', '${booking.guestCount}'),
                    const SizedBox(height: 2),
                    _richText(
                      'Total: ',
                      'Rs. ${booking.grandTotal.toStringAsFixed(0)}',
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Action buttons per tab ───────────────────────────────────────
          if (tabLabel == 'Pending')
            _buildPendingActions(context)
          else if (tabLabel == 'Upcoming')
            _buildUpcomingActions(context)
          else if (tabLabel == 'Completed')
            _buildCompletedActions(context)
          else
            _buildCancelledActions(context),
        ],
      ),
    );
  }

  // ── Pending ────────────────────────────────────────────────────────────────

  Widget _buildPendingActions(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        onPressed: () => _showReceiptView(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF47C20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        icon: const Icon(
          Icons.receipt_long_outlined,
          color: Colors.white,
          size: 18,
        ),
        label: const Text(
          'View & Verify Receipt',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ── Upcoming ───────────────────────────────────────────────────────────────

  Widget _buildUpcomingActions(BuildContext context) {
    final days = booking.daysUntilEvent;

    // "Mark Complete" is only allowed the day AFTER the event date.
    // daysUntilEvent < 0 means the event date is in the past.
    final canMarkComplete = days < 0;

    return Column(
      children: [
        if (days <= 3 && days >= 0)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  days == 0 ? const Color(0xFFFFE4E4) : const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  days == 0 ? Icons.today : Icons.access_alarm,
                  size: 16,
                  color: days == 0 ? Colors.red : const Color(0xFFD97706),
                ),
                const SizedBox(width: 8),
                Text(
                  days == 0
                      ? 'Event is TODAY!'
                      : 'Event in $days day${days > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: days == 0 ? Colors.red : const Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),

        // Info banner shown on the event day telling admin they can mark
        // complete starting tomorrow.
        if (days == 0)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF388E3C).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 15,
                  color: Color(0xFF388E3C),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'You can mark this as completed from tomorrow onwards.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
          ),

        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: () => _showBookingDetailView(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Colors.black54,
                  ),
                  label: const Text(
                    'View Details',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Tooltip(
                message:
                    canMarkComplete
                        ? ''
                        : 'Available the day after the event date',
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed:
                        canMarkComplete
                            ? () => _confirmMarkAsComplete(context)
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF388E3C),
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    icon: Icon(
                      Icons.check_circle_outline,
                      color:
                          canMarkComplete ? Colors.white : Colors.grey.shade500,
                      size: 18,
                    ),
                    label: Text(
                      'Mark Complete',
                      style: TextStyle(
                        color:
                            canMarkComplete
                                ? Colors.white
                                : Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Completed ──────────────────────────────────────────────────────────────

  Widget _buildCompletedActions(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        onPressed: () => _showBookingDetailView(context),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(Icons.info_outline, size: 18, color: Colors.black54),
        label: const Text(
          'View Details',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ── Cancelled ──────────────────────────────────────────────────────────────

  Widget _buildCancelledActions(BuildContext context) {
    final showRefund = booking.isCancelled && booking.hasRefundApplicable;

    if (showRefund) {
      return Column(
        children: [
          _buildAdminRefundBadge(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: () => _showBookingDetailView(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Colors.black54,
                    ),
                    label: const Text(
                      'View Details',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed:
                        booking.refundStatus == 'accepted'
                            ? null
                            : () => _showAdminRefundView(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          booking.refundStatus == 'accepted'
                              ? Colors.green
                              : const Color(0xFFF47C20),
                      disabledBackgroundColor: Colors.green,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: Icon(
                      booking.refundStatus == 'accepted'
                          ? Icons.check_circle_outline
                          : Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      booking.refundStatus == 'accepted'
                          ? 'Refund Done'
                          : 'Manage Refund',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        onPressed: () => _showBookingDetailView(context),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(Icons.info_outline, size: 18, color: Colors.black54),
        label: const Text(
          'View Details',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildAdminRefundBadge() {
    String msg;
    Color bg;
    Color textColor;

    switch (booking.refundStatus) {
      case 'pending_upload':
        msg =
            'Refund Rs. ${booking.refundAmount.toStringAsFixed(0)} — Upload refund receipt';
        bg = const Color(0xFFFFF9C4);
        textColor = const Color(0xFF7B6000);
        break;
      case 'uploaded':
        msg = 'Receipt uploaded — Waiting for customer to verify';
        bg = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1565C0);
        break;
      case 'rejected_by_customer':
        msg = 'Customer rejected receipt — Re-upload required';
        bg = const Color(0xFFFFECB3);
        textColor = const Color(0xFFE65100);
        break;
      case 'accepted':
        msg =
            '✅ Refund of Rs. ${booking.refundAmount.toStringAsFixed(0)} accepted by customer';
        bg = const Color(0xFFC8E6C9);
        textColor = const Color(0xFF1B5E20);
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        msg,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Mark as Complete dialog ────────────────────────────────────────────────

  void _confirmMarkAsComplete(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder:
          (dialogCtx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF388E3C),
                  size: 50,
                ),
                SizedBox(height: 12),
                Text(
                  'Mark as Completed?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            content: Text(
              'Mark "${booking.eventName}" as completed?\n\nThis will move it to the Completed tab for both you and the customer.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogCtx);
                  final error = await BookingService.markBookingAsCompleted(
                    booking.bookingId,
                  );
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        error == null
                            ? '✅ Booking marked as completed!'
                            : 'Error: $error',
                      ),
                      backgroundColor:
                          error == null ? Colors.green : Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF388E3C),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Yes, Complete',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // ── Panel / Dialog launchers ───────────────────────────────────────────────

  void _showReceiptView(BuildContext context) {
    if (isWeb) {
      _showWebDialog(
        context,
        _ReceiptVerificationContent(booking: booking, isWeb: true),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:
            (_) => _ReceiptVerificationContent(booking: booking, isWeb: false),
      );
    }
  }

  void _showBookingDetailView(BuildContext context) {
    if (isWeb) {
      _showWebDialog(
        context,
        _BookingDetailContent(booking: booking, isWeb: true),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _BookingDetailContent(booking: booking, isWeb: false),
      );
    }
  }

  void _showAdminRefundView(BuildContext context) {
    if (isWeb) {
      _showWebDialog(
        context,
        _AdminRefundContent(booking: booking, isWeb: true),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _AdminRefundContent(booking: booking, isWeb: false),
      );
    }
  }

  /// Centred, max-width dialog for web.
  void _showWebDialog(BuildContext context, Widget content) {
    showDialog(
      context: context,
      barrierColor: Colors.black38,
      builder:
          (_) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 60,
              vertical: 40,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: content,
              ),
            ),
          ),
    );
  }

  // ── Micro helpers ──────────────────────────────────────────────────────────

  Widget _imageFallback() => Container(
    height: 80,
    width: 80,
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(Icons.store, color: Colors.grey[400], size: 32),
  );

  Widget _richText(String label, String value) => RichText(
    text: TextSpan(
      style: const TextStyle(fontSize: 12, color: Colors.black87),
      children: [
        TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(text: value),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  RECEIPT VERIFICATION CONTENT
//  Shared widget: isWeb=true → shown inside Dialog
//                isWeb=false → shown inside ModalBottomSheet
// ══════════════════════════════════════════════════════════════════════════════

class _ReceiptVerificationContent extends StatefulWidget {
  final BookingModel booking;
  final bool isWeb;
  const _ReceiptVerificationContent({
    required this.booking,
    required this.isWeb,
  });

  @override
  State<_ReceiptVerificationContent> createState() =>
      _ReceiptVerificationContentState();
}

class _ReceiptVerificationContentState
    extends State<_ReceiptVerificationContent> {
  bool _processingConfirm = false;

  Future<void> _confirm() async {
    setState(() => _processingConfirm = true);
    final error = await BookingService.confirmBooking(widget.booking.bookingId);
    if (!mounted) return;
    setState(() => _processingConfirm = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? '✅ Booking confirmed! Customer has been notified.'
              : 'Error: $error',
        ),
        backgroundColor: error == null ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openRejectScreen() {
    Navigator.pop(context);
    if (widget.isWeb) {
      showDialog(
        context: context,
        barrierColor: Colors.black38,
        builder:
            (_) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 60,
                vertical: 40,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _RejectPaymentContent(
                    bookingId: widget.booking.bookingId,
                    isWeb: true,
                  ),
                ),
              ),
            ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => _RejectPaymentScreen(bookingId: widget.booking.bookingId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;

    final scrollable = SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Verify Payment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Event summary
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.person_outline,
                    color: Color(0xFFF47C20),
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.eventName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: Color(0xFFF47C20),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              b.eventDateLabel,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Customer: ${b.customerName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'Guests: ${b.guestCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Divider(thickness: 4, color: Colors.grey.shade200),
              const SizedBox(height: 16),

              _financialRow(
                'Advance Due (25%)',
                'Rs. ${b.advancePayment.toStringAsFixed(0)}',
              ),
              const SizedBox(height: 12),
              _financialRow(
                'Remaining Amount',
                'Rs. ${b.remainingPayment.toStringAsFixed(0)}',
              ),
              const SizedBox(height: 12),
              _financialRow(
                'Grand Total',
                'Rs. ${b.grandTotal.toStringAsFixed(0)}',
                isBold: true,
              ),

              const SizedBox(height: 20),
              const Text(
                'Uploaded Receipt',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              b.receiptImageUrl.isNotEmpty
                  ? GestureDetector(
                    onTap: () => _showFullImage(context, b.receiptImageUrl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        b.receiptImageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder:
                            (_, child, progress) =>
                                progress == null
                                    ? child
                                    : Container(
                                      height: 200,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFFF47C20),
                                        ),
                                      ),
                                    ),
                        errorBuilder: (_, __, ___) => _receiptPlaceholder(),
                      ),
                    ),
                  )
                  : _receiptPlaceholder(),

              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Tap receipt image to view full size',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ),
              const SizedBox(height: 25),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _openRejectScreen,
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD6D1C4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Reject Payment',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child:
                        _processingConfirm
                            ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFF47C20),
                              ),
                            )
                            : CommonButton(
                              text: 'Confirm Payment',
                              onTap: _confirm,
                            ),
                  ),
                ],
              ),

              SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
            ],
          ),
        ),
      ),
    );

    if (!widget.isWeb) {
      // Mobile: bottom-sheet drag handle + content
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Flexible(child: scrollable),
          ],
        ),
      );
    }
    return scrollable; // Web: plain white scrollable
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            backgroundColor: Colors.black,
            insetPadding: EdgeInsets.zero,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
          ),
    );
  }

  Widget _receiptPlaceholder() => Container(
    height: 150,
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.grey[300],
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.receipt_long_outlined, size: 32, color: Colors.black54),
        SizedBox(height: 8),
        Text(
          'Receipt Image',
          style: TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );

  Widget _financialRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 17 : 16,
            fontWeight: FontWeight.bold,
            color: isBold ? const Color(0xFFF47C20) : Colors.black,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  REJECT PAYMENT CONTENT
//  isWeb=true → inside Dialog   |   isWeb=false → inside Scaffold
// ══════════════════════════════════════════════════════════════════════════════

class _RejectPaymentContent extends StatefulWidget {
  final String bookingId;
  final bool isWeb;
  const _RejectPaymentContent({required this.bookingId, required this.isWeb});

  @override
  State<_RejectPaymentContent> createState() => _RejectPaymentContentState();
}

class _RejectPaymentContentState extends State<_RejectPaymentContent> {
  String? _selectedReason = 'Incorrect Amount';
  final TextEditingController _customController = TextEditingController();
  bool _submitting = false;

  final List<String> _reasons = [
    'Incorrect Amount',
    'Blurry / Unreadable Image',
    'Invalid Receipt',
    'Payment Not Received',
    'Another reason',
  ];

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason =
        _selectedReason == 'Another reason'
            ? _customController.text.trim()
            : _selectedReason ?? '';
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a reason for rejection'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    final error = await BookingService.rejectBookingPayment(
      bookingId: widget.bookingId,
      reason: reason,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? '❌ Payment rejected. Customer has been notified.'
              : 'Error: $error',
        ),
        backgroundColor: error == null ? Colors.orange : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Reason for Rejection',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._reasons.map(_buildOption),
          const SizedBox(height: 24),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _selectedReason == 'Another reason' ? 150 : 0,
            curve: Curves.easeInOut,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Container(
                height: 140,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFF47C20),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF47C20).withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _customController,
                  enabled: _selectedReason == 'Another reason',
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: 'Please describe the specific reason…',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF47C20),
                disabledBackgroundColor: const Color(
                  0xFFF47C20,
                ).withOpacity(0.6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child:
                  _submitting
                      ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                      : const Text(
                        'Submit Reason',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );

    if (widget.isWeb) {
      return Container(color: Colors.white, child: body);
    }
    return Scaffold(backgroundColor: Colors.white, body: body);
  }

  Widget _buildOption(String label) {
    final isSelected = _selectedReason == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedReason = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF8EC) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFF47C20) : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isSelected ? const Color(0xFFF47C20) : Colors.transparent,
                border: Border.all(
                  color:
                      isSelected
                          ? const Color(0xFFF47C20)
                          : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child:
                  isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.black87 : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  REJECT PAYMENT SCREEN  —  mobile-only full-screen wrapper
// ══════════════════════════════════════════════════════════════════════════════

class _RejectPaymentScreen extends StatelessWidget {
  final String bookingId;
  const _RejectPaymentScreen({required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Reject Payment',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _RejectPaymentContent(bookingId: bookingId, isWeb: false),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  BOOKING DETAIL CONTENT
//  isWeb=true → dialog   |   isWeb=false → DraggableScrollableSheet
// ══════════════════════════════════════════════════════════════════════════════

class _BookingDetailContent extends StatelessWidget {
  final BookingModel booking;
  final bool isWeb;
  const _BookingDetailContent({required this.booking, required this.isWeb});

  @override
  Widget build(BuildContext context) {
    final b = booking;

    List<Widget> children = [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Booking Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      const SizedBox(height: 20),
      _section('Customer Information', [
        _row('Name', b.customerName),
        _row('Phone', b.customerPhone),
        _row('Email', b.customerEmail),
        _row('CNIC', b.customerCnic),
      ]),
      const SizedBox(height: 16),
      _section('Event Details', [
        _row('Event', b.eventName),
        _row('Date', b.eventDateLabel),
        _row('Guests', '${b.guestCount}'),
        _row('Booking', b.invoiceId),
      ]),
      const SizedBox(height: 16),
      _section('Payment Summary', [
        _row('Hall Rent', 'Rs. ${b.hallRent.toStringAsFixed(0)}'),
        if (b.menuSubtotal > 0)
          _row('Menu', 'Rs. ${b.menuSubtotal.toStringAsFixed(0)}'),
        if (b.servicesSubtotal > 0)
          _row('Services', 'Rs. ${b.servicesSubtotal.toStringAsFixed(0)}'),
        _row(
          'Grand Total',
          'Rs. ${b.grandTotal.toStringAsFixed(0)}',
          highlight: true,
        ),
        _row(
          'Advance Paid (25%)',
          'Rs. ${b.advancePayment.toStringAsFixed(0)}',
        ),
        _row('Remaining', 'Rs. ${b.remainingPayment.toStringAsFixed(0)}'),
      ]),
      if (b.selectedMenuItems.isNotEmpty) ...[
        const SizedBox(height: 16),
        _section(
          'Menu Items (${b.selectedMenuItems.length})',
          b.selectedMenuItems.map((m) => _row(m.name, m.priceLabel)).toList(),
        ),
      ],
      if (b.selectedServices.isNotEmpty) ...[
        const SizedBox(height: 16),
        _section(
          'Services (${b.selectedServices.length})',
          b.selectedServices.map((s) => _row(s.name, s.priceLabel)).toList(),
        ),
      ],
      if (b.isRejected && b.rejectionReason.isNotEmpty) ...[
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rejection Reason:',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                b.rejectionReason,
                style: TextStyle(color: Colors.red[700], fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    ];

    if (isWeb) {
      return Container(
        color: Colors.white,
        constraints: const BoxConstraints(maxHeight: 680),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      );
    }

    // Mobile: DraggableScrollableSheet
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder:
          (_, controller) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                ...children,
              ],
            ),
          ),
    );
  }

  Widget _section(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF47C20),
            ),
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: highlight ? const Color(0xFFF47C20) : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ADMIN REFUND CONTENT
//  isWeb=true → dialog   |   isWeb=false → DraggableScrollableSheet
//
//  Web-safe image picking: stores Uint8List bytes; never imports dart:io.
//  BookingService needs two methods:
//    • uploadRefundReceipt(bookingId, receiptFile)       — mobile (existing)
//    • uploadRefundReceiptBytes(bookingId, bytes, name)  — web (new)
// ══════════════════════════════════════════════════════════════════════════════

class _AdminRefundContent extends StatefulWidget {
  final BookingModel booking;
  final bool isWeb;
  const _AdminRefundContent({required this.booking, required this.isWeb});

  @override
  State<_AdminRefundContent> createState() => _AdminRefundContentState();
}

class _AdminRefundContentState extends State<_AdminRefundContent> {
  Uint8List? _refundReceiptBytes;
  String? _pickedFileName;
  bool _uploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _refundReceiptBytes = bytes;
        _pickedFileName = picked.name;
      });
    }
  }

  Future<void> _uploadRefund() async {
    if (_refundReceiptBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a refund receipt image first'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _uploading = true);

    String? error;
    if (kIsWeb) {
      error = await BookingService.uploadRefundReceiptBytes(
        bookingId: widget.booking.bookingId,
        receiptBytes: _refundReceiptBytes!,
        fileName: _pickedFileName ?? 'refund_receipt.jpg',
      );
    } else {
      // On mobile XFile.readAsBytes() gave us the bytes; write them to a
      // temp file via the bytes-based helper so dart:io never appears here.
      error = await BookingService.uploadRefundReceiptBytes(
        bookingId: widget.booking.bookingId,
        receiptBytes: _refundReceiptBytes!,
        fileName: _pickedFileName ?? 'refund_receipt.jpg',
      );
    }

    if (!mounted) return;
    setState(() => _uploading = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? '✅ Refund receipt uploaded. Waiting for customer verification.'
              : 'Error: $error',
        ),
        backgroundColor: error == null ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BookingModel?>(
      stream: BookingService.streamBookingById(widget.booking.bookingId),
      builder: (context, snap) {
        final booking = snap.data ?? widget.booking;

        final innerContent = _buildInnerContent(booking, context);

        if (widget.isWeb) {
          return Container(
            color: Colors.white,
            constraints: const BoxConstraints(maxHeight: 700),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: innerContent,
            ),
          );
        }

        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder:
              (_, controller) => Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    innerContent,
                  ],
                ),
              ),
        );
      },
    );
  }

  Widget _buildInnerContent(BookingModel booking, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Expanded(
              child: Text(
                'Manage Refund',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        Text(
          '${booking.customerName} · ${booking.eventName}',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),

        // Refund amount gradient card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF47C20), Color(0xFFFFD166)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rs. ${booking.refundAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Amount to refund to customer',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildAdminStatusCard(booking),
        const SizedBox(height: 16),

        // Customer's original receipt
        const Text(
          "Customer's Original Payment Receipt",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Use the account number in this receipt to send the refund',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        const SizedBox(height: 8),
        _buildNetworkImageBox(booking.receiptImageUrl, context),
        const SizedBox(height: 20),

        // Customer rejection reason
        if (booking.refundStatus == 'rejected_by_customer' &&
            booking.refundRejectionReason.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer rejection reason:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  booking.refundRejectionReason,
                  style: TextStyle(fontSize: 13, color: Colors.red.shade800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Accepted success banner
        if (booking.refundStatus == 'accepted') ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green.shade600,
                  size: 48,
                ),
                const SizedBox(height: 10),
                Text(
                  'Refund Successfully Completed!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Customer has accepted the refund receipt.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.green.shade700),
                ),
              ],
            ),
          ),
        ],

        // Upload section
        if (booking.refundStatus == 'pending_upload' ||
            booking.refundStatus == 'rejected_by_customer') ...[
          Text(
            booking.refundStatus == 'rejected_by_customer'
                ? 'Upload New Refund Receipt'
                : 'Upload Refund Receipt',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Send Rs. ${booking.refundAmount.toStringAsFixed(0)} to the account in the receipt above, then upload proof here.',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 10),

          // Web-safe image picker (uses Uint8List, never File)
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      _refundReceiptBytes != null
                          ? const Color(0xFFF47C20)
                          : Colors.grey.shade300,
                  width: _refundReceiptBytes != null ? 2 : 1,
                ),
              ),
              child:
                  _refundReceiptBytes != null
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(
                              _refundReceiptBytes!,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.upload_file_outlined,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Tap to select refund receipt',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Choose from gallery',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed:
                  (_refundReceiptBytes != null && !_uploading)
                      ? _uploadRefund
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF47C20),
                disabledBackgroundColor: Colors.grey[300],
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  _uploading
                      ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                      : const Text(
                        'Upload Refund Receipt',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
            ),
          ),
        ],

        // Waiting for customer
        if (booking.refundStatus == 'uploaded') ...[
          const Text(
            'Uploaded Refund Receipt',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildNetworkImageBox(booking.refundReceiptUrl, context),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.hourglass_empty_outlined,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Waiting for customer to verify and accept the refund receipt.',
                    style: TextStyle(fontSize: 13, color: Colors.blue.shade800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAdminStatusCard(BookingModel booking) {
    String title;
    String subtitle;
    Color color;
    IconData icon;

    switch (booking.refundStatus) {
      case 'pending_upload':
        title = 'Action Required: Upload Refund Receipt';
        subtitle =
            'Send Rs. ${booking.refundAmount.toStringAsFixed(0)} to the account in the receipt below, then upload proof.';
        color = Colors.amber.shade800;
        icon = Icons.upload_outlined;
        break;
      case 'uploaded':
        title = 'Waiting for Customer Verification';
        subtitle = 'Customer will accept or reject your receipt.';
        color = Colors.blue.shade700;
        icon = Icons.hourglass_empty_outlined;
        break;
      case 'rejected_by_customer':
        title = 'Customer Rejected — Re-upload Required';
        subtitle = 'See reason below and upload a corrected receipt.';
        color = Colors.red.shade700;
        icon = Icons.refresh_outlined;
        break;
      case 'accepted':
        title = 'Refund Complete ✅';
        subtitle = 'Customer confirmed the refund receipt.';
        color = Colors.green.shade700;
        icon = Icons.check_circle_outline;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkImageBox(String url, BuildContext context) {
    if (url.isEmpty) {
      return Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 32,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Not available',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }
    return GestureDetector(
      onTap: () => _showFullImage(context, url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder:
              (_, child, progress) =>
                  progress == null
                      ? child
                      : Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFF47C20),
                          ),
                        ),
                      ),
          errorBuilder:
              (_, __, ___) => Container(
                height: 140,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.broken_image_outlined, size: 36),
                ),
              ),
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            backgroundColor: Colors.black,
            insetPadding: EdgeInsets.zero,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
          ),
    );
  }
}
