import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:venuemate_system/Models/hall_model.dart';
import 'package:venuemate_system/Services/hall_service.dart';

class ManageHallDetailsScreen extends StatefulWidget {
  final HallModel hall;
  final bool inlineMode;
  final ValueChanged<HallModel>? onHallUpdated;

  const ManageHallDetailsScreen({
    super.key,
    required this.hall,
    this.inlineMode = false,
    this.onHallUpdated,
  });

  @override
  State<ManageHallDetailsScreen> createState() =>
      _ManageHallDetailsScreenState();
}

class _ManageHallDetailsScreenState extends State<ManageHallDetailsScreen> {
  int _currentImageIndex = 0;
  bool _isUpdating = false;

  late Stream<HallModel?> _hallStream;
  HallModel? _hall;

  @override
  void initState() {
    super.initState();
    _hall = widget.hall;
    _hallStream = HallService.streamHallByOwnerId(widget.hall.ownerId);
  }

  @override
  void didUpdateWidget(ManageHallDetailsScreen old) {
    super.didUpdateWidget(old);
    if (old.hall.hallId != widget.hall.hallId) {
      setState(() {
        _hall = widget.hall;
        _currentImageIndex = 0;
        _hallStream = HallService.streamHallByOwnerId(widget.hall.ownerId);
      });
    }
  }

  Future<Map<String, int>> _fetchBookingStats() async {
    try {
      final snap =
          await FirebaseFirestore.instance
              .collection('bookings')
              .where('hallId', isEqualTo: widget.hall.hallId)
              .get();
      int completed = 0, upcoming = 0, cancelled = 0;
      for (final d in snap.docs) {
        final s = d.data()['status'] as String? ?? '';
        if (s == 'completed') completed++;
        if (s == 'confirmed') upcoming++;
        if (s == 'cancelled') cancelled++;
      }
      return {
        'total': snap.docs.length,
        'completed': completed,
        'upcoming': upcoming,
        'cancelled': cancelled,
      };
    } catch (_) {
      return {'total': 0, 'completed': 0, 'upcoming': 0, 'cancelled': 0};
    }
  }

  Future<void> _toggleVisibility() async {
    final hall = _hall;
    if (hall == null) return;
    final willDisable = hall.isVisible;
    final action = willDisable ? 'Disable' : 'Enable';

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Column(
              children: [
                Icon(
                  willDisable ? Icons.block : Icons.check_circle_outline,
                  color: willDisable ? Colors.red : Colors.green,
                  size: 52,
                ),
                const SizedBox(height: 12),
                Text(
                  '$action Hall?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            content: Text(
              willDisable
                  ? 'This hall will be hidden from customers.'
                  : 'This hall will become visible to customers again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], height: 1.5),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            willDisable
                                ? const Color(0xFFD92D20)
                                : Colors.green,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        action,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
    );

    if (confirmed != true) return;
    setState(() => _isUpdating = true);
    final error =
        await (willDisable ? _disable(hall.hallId) : _enable(hall.hallId));
    if (!mounted) return;
    setState(() => _isUpdating = false);
    _snack(
      error ??
          (willDisable
              ? 'Hall disabled. Hidden from customers.'
              : 'Hall enabled. Visible to customers again.'),
      isError: error != null,
    );
  }

  static Future<String?> _disable(String id) async {
    try {
      await FirebaseFirestore.instance.collection('halls').doc(id).update({
        'isVisible': false,
      });
      return null;
    } catch (e) {
      return 'Failed: $e';
    }
  }

  static Future<String?> _enable(String id) async {
    try {
      await FirebaseFirestore.instance.collection('halls').doc(id).update({
        'isVisible': true,
      });
      return null;
    } catch (e) {
      return 'Failed: $e';
    }
  }

  void _snack(String msg, {bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isError ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<HallModel?>(
      stream: _hallStream,
      builder: (context, snap) {
        if (snap.hasData && snap.data != null) {
          final updatedHall = snap.data!;

          // Only trigger update if the hall data actually changed to avoid infinite loops
          if (_hall?.isVisible != updatedHall.isVisible ||
              _hall?.status != updatedHall.status) {
            _hall = updatedHall;

            // FIX: Schedule the callback to run after the build is complete
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                widget.onHallUpdated?.call(updatedHall);
              }
            });
          }
        }
        final hall = _hall ?? widget.hall;

        // Inline mode — no Scaffold, column layout for right pane
        if (widget.inlineMode) {
          return Column(
            children: [Expanded(child: _inlineContent(hall)), _bottomBar(hall)],
          );
        }

        // Full-screen (mobile) — Scaffold with SliverAppBar
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  _sliverAppBar(hall),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                      child: _bodyContent(hall),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: _actionButton(hall),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Inline scrollable content ────────────────────────────────────────────
  Widget _inlineContent(HallModel hall) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal image strip
        if (hall.imageUrls.isNotEmpty)
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              itemCount: hall.imageUrls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder:
                  (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: hall.imageUrls[i],
                      width: 260,
                      height: 188,
                      fit: BoxFit.cover,
                      placeholder:
                          (_, __) =>
                              Container(color: Colors.grey[200], width: 260),
                      errorWidget:
                          (_, __, ___) => Container(
                            color: Colors.grey[200],
                            width: 260,
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                          ),
                    ),
                  ),
            ),
          ),
        Padding(padding: const EdgeInsets.all(20), child: _bodyContent(hall)),
      ],
    ),
  );

  // ── Shared body content ──────────────────────────────────────────────────
  Widget _bodyContent(HallModel hall) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _header(hall),
      const SizedBox(height: 20),
      FutureBuilder<Map<String, int>>(
        future: _fetchBookingStats(),
        builder: (context, s) {
          final b = s.data;
          return Row(
            children: [
              Expanded(
                child: _statCard(
                  Icons.people,
                  hall.capacityLabel
                      .split('–')
                      .last
                      .trim()
                      .replaceAll(' Guests', ''),
                  'Max Guests',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  Icons.star,
                  hall.ratingCount == 0
                      ? '—'
                      : hall.ratingAvg.toStringAsFixed(1),
                  'Rating',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  Icons.event,
                  b == null ? '—' : '${b['total']}',
                  'Bookings',
                ),
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 28),
      _sectionTitle('Hall Details'),
      _infoCard(
        children: [
          _infoRow(
            Icons.location_on_outlined,
            'Location',
            hall.address.isNotEmpty ? hall.address : '—',
          ),
          const SizedBox(height: 16),
          _infoRow(
            Icons.groups,
            'Capacity',
            '${hall.capacityMin} – ${hall.capacityMax} Guests',
          ),
          const SizedBox(height: 16),
          _infoRow(Icons.payments, 'Price Per Event', hall.priceLabel),
          const SizedBox(height: 16),
          _infoRow(
            Icons.phone,
            'Contact',
            hall.contactPhone.isNotEmpty ? hall.contactPhone : '—',
          ),
          if (hall.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DESCRIPTION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[500],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hall.description,
                    style: const TextStyle(height: 1.5, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: 24),
      _sectionTitle('Payout Information'),
      _infoCard(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueGrey.shade100),
                ),
                child: Icon(
                  Icons.account_balance,
                  color: Colors.blueGrey[700],
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hall.bankName.isNotEmpty ? hall.bankName : '—',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hall.bankAccountNumber.isNotEmpty
                          ? hall.bankAccountNumber
                          : '—',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 24),
      FutureBuilder<Map<String, int>>(
        future: _fetchBookingStats(),
        builder: (context, s) {
          final b =
              s.data ??
              {'completed': 0, 'upcoming': 0, 'cancelled': 0, 'total': 0};
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Booking Stats'),
              _infoCard(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Bookings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${b['total']}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    children: [
                      _miniStat(
                        Icons.check_circle_outline,
                        '${b['completed']}',
                        'Completed',
                        Colors.green,
                      ),
                      _miniStat(
                        Icons.calendar_today,
                        '${b['upcoming']}',
                        'Upcoming',
                        const Color(0xFFF47C20),
                      ),
                      _miniStat(
                        Icons.cancel_outlined,
                        '${b['cancelled']}',
                        'Cancelled',
                        Colors.redAccent,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 20),
    ],
  );

  Widget _bottomBar(HallModel hall) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, -4),
        ),
      ],
    ),
    child: _actionButton(hall),
  );

  Widget _actionButton(HallModel hall) {
    if (_isUpdating) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF47C20)),
      );
    }
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _toggleVisibility,
        icon: Icon(hall.isVisible ? Icons.block : Icons.check_circle_outline),
        label: Text(hall.isVisible ? 'Disable Hall' : 'Enable Hall'),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              hall.isVisible
                  ? const Color(0xFFD92D20)
                  : const Color(0xFFF47C20),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _sliverAppBar(HallModel hall) {
    final images = hall.imageUrls;
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            images.isEmpty
                ? Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.business,
                    size: 80,
                    color: Colors.grey,
                  ),
                )
                : CarouselSlider(
                  options: CarouselOptions(
                    height: double.infinity,
                    viewportFraction: 1.0,
                    autoPlay: images.length > 1,
                    onPageChanged:
                        (i, _) => setState(() => _currentImageIndex = i),
                  ),
                  items:
                      images
                          .map(
                            (url) => CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              placeholder:
                                  (_, __) => Container(color: Colors.grey[300]),
                              errorWidget:
                                  (_, __, ___) =>
                                      Container(color: Colors.grey[300]),
                            ),
                          )
                          .toList(),
                ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                ),
              ),
            ),
            if (images.isNotEmpty)
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentImageIndex + 1}/${images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _header(HallModel hall) {
    final (_, bg, fg) =
        hall.isVisible
            ? ('Active', const Color(0xFFE6F7ED), const Color(0xFF00B85E))
            : ('Disabled', const Color(0xFFFFF0F1), const Color(0xFFD92D20));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            hall.hallName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
              color: Color(0xFF2D3436),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hall.isVisible ? Icons.check_circle : Icons.block,
                size: 14,
                color: fg,
              ),
              const SizedBox(width: 4),
              Text(
                hall.isVisible ? 'Active' : 'Disabled',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D3436),
      ),
    ),
  );

  Widget _infoCard({required List<Widget> children}) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );

  Widget _infoRow(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, size: 18, color: Colors.grey[400]),
      const SizedBox(width: 10),
      Text('$label: ', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );

  Widget _statCard(IconData icon, String value, String label) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      children: [
        Icon(icon, color: const Color(0xFFF47C20), size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    ),
  );

  Widget _miniStat(IconData icon, String count, String label, Color color) =>
      Expanded(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              count,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      );
}
