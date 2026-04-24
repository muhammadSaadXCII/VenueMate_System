import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:venuemate_system/Services/booking_service.dart';
import 'package:venuemate_system/Services/hall_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  BREAKPOINT
// ══════════════════════════════════════════════════════════════════════════════

const double _kFeedbackWebBreak = 950;

// ══════════════════════════════════════════════════════════════════════════════
//  HALL FEEDBACKS SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class HallFeedbacksScreen extends StatefulWidget {
  const HallFeedbacksScreen({super.key});

  @override
  State<HallFeedbacksScreen> createState() => _HallFeedbacksScreenState();
}

class _HallFeedbacksScreenState extends State<HallFeedbacksScreen> {
  String _selectedFilter = 'All';
  String? _hallId;
  bool _loadingHall = true;

  final List<String> _filters = [
    'All',
    '5 Stars',
    '4 Stars',
    '3 Stars',
    '2 Stars',
    '1 Star',
  ];

  @override
  void initState() {
    super.initState();
    _loadHall();
  }

  Future<void> _loadHall() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loadingHall = false);
      return;
    }
    final hall = await HallService.getHallByOwnerId(uid);
    if (mounted) {
      setState(() {
        _hallId = hall?.hallId;
        _loadingHall = false;
      });
    }
  }

  int _filterToRating(String filter) {
    switch (filter) {
      case '5 Stars':
        return 5;
      case '4 Stars':
        return 4;
      case '3 Stars':
        return 3;
      case '2 Stars':
        return 2;
      case '1 Star':
        return 1;
      default:
        return 0;
    }
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> all) {
    if (_selectedFilter == 'All') return all;
    final star = _filterToRating(_selectedFilter);
    return all
        .where((f) => (f['rating'] as num? ?? 0).toInt() == star)
        .toList();
  }

  double _computeAverage(List<Map<String, dynamic>> all) {
    if (all.isEmpty) return 0.0;
    final sum = all.fold<double>(
      0,
      (prev, f) => prev + (f['rating'] as num? ?? 0).toDouble(),
    );
    return sum / all.length;
  }

  Map<int, int> _computeDistribution(List<Map<String, dynamic>> all) {
    final dist = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final f in all) {
      final r = (f['rating'] as num? ?? 0).toInt().clamp(1, 5);
      dist[r] = (dist[r] ?? 0) + 1;
    }
    return dist;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 14) return '1 week ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= _kFeedbackWebBreak;

    if (_loadingHall) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFF47C20)),
        ),
      );
    }

    if (_hallId == null) return _buildNoHall(isWide);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: BookingService.streamHallFeedbacks(_hallId!),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: const Color(0xFFF9FAFB),
            body: const Center(
              child: CircularProgressIndicator(color: Color(0xFFF47C20)),
            ),
          );
        }
        final allFeedbacks = snap.data ?? [];
        final filtered = _applyFilter(allFeedbacks);
        final average = _computeAverage(allFeedbacks);
        final dist = _computeDistribution(allFeedbacks);

        return isWide
            ? _buildWebLayout(allFeedbacks, filtered, average, dist)
            : _buildMobileLayout(allFeedbacks, filtered, average);
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  WEB LAYOUT
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildWebLayout(
    List<Map<String, dynamic>> allFeedbacks,
    List<Map<String, dynamic>> filtered,
    double average,
    Map<int, int> dist,
  ) {
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
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Back',
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFF47C20),
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Feedbacks',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                if (allFeedbacks.isNotEmpty)
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
                      '${allFeedbacks.length} review${allFeedbacks.length == 1 ? '' : 's'}',
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

          // ── Body ──────────────────────────────────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Left panel: summary + filters ────────────────────────
                Container(
                  width: 300,
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rating hero
                        _buildWebRatingSummary(average, allFeedbacks.length),
                        const SizedBox(height: 24),

                        // Star distribution bars
                        if (allFeedbacks.isNotEmpty) ...[
                          _buildDistributionBars(dist, allFeedbacks.length),
                          const SizedBox(height: 28),
                        ],

                        // Filter section
                        Text(
                          'FILTER BY RATING',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[400],
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._filters.map(
                          (f) => _WebFilterTile(
                            label: f,
                            isSelected: _selectedFilter == f,
                            count:
                                f == 'All'
                                    ? allFeedbacks.length
                                    : allFeedbacks
                                        .where(
                                          (fb) =>
                                              (fb['rating'] as num? ?? 0)
                                                  .toInt() ==
                                              _filterToRating(f),
                                        )
                                        .length,
                            onTap: () => setState(() => _selectedFilter = f),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Right panel: review list ──────────────────────────────
                Expanded(
                  child:
                      filtered.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                            padding: const EdgeInsets.all(28),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final f = filtered[i];
                              final int rating =
                                  (f['rating'] as num? ?? 0).toInt();
                              final String name =
                                  f['customerName'] as String? ?? 'Customer';
                              final String comment =
                                  f['reviewText'] as String? ?? '';
                              final Timestamp? ts =
                                  f['submittedAt'] as Timestamp?;
                              final String dateStr =
                                  ts != null ? _formatDate(ts.toDate()) : '';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _ReviewCard(
                                  name: name,
                                  date: dateStr,
                                  rating: rating,
                                  comment: comment,
                                  isWeb: true,
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebRatingSummary(double average, int total) {
    final filledStars = average.round();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF47C20), Color(0xFFFFD166)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF47C20).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            total == 0 ? '--' : average.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1,
            ),
          ),
          const Text(
            'OUT OF 5',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < filledStars ? Icons.star : Icons.star_outline,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            total == 0
                ? 'No reviews yet'
                : 'Based on $total review${total == 1 ? '' : 's'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionBars(Map<int, int> dist, int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RATING BREAKDOWN',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey[400],
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(5, (i) {
          final star = 5 - i;
          final count = dist[star] ?? 0;
          final fraction = total > 0 ? count / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 13),
                const SizedBox(width: 4),
                Text(
                  '$star',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 7,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFF47C20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 22,
                  child: Text(
                    '$count',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  MOBILE LAYOUT  —  original design, unchanged
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildMobileLayout(
    List<Map<String, dynamic>> allFeedbacks,
    List<Map<String, dynamic>> filtered,
    double average,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
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
          'Feedbacks',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRatingSummaryCard(average, allFeedbacks.length),
            const SizedBox(height: 25),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    _filters
                        .map(
                          (filter) => _FilterChip(
                            label: filter,
                            isSelected: _selectedFilter == filter,
                            onTap:
                                () => setState(() => _selectedFilter = filter),
                          ),
                        )
                        .toList(),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'Reviews',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            if (filtered.isEmpty)
              _buildEmptyState()
            else
              ...filtered.map((f) {
                final int rating = (f['rating'] as num? ?? 0).toInt();
                final String name = f['customerName'] as String? ?? 'Customer';
                final String comment = f['reviewText'] as String? ?? '';
                final Timestamp? ts = f['submittedAt'] as Timestamp?;
                final String dateStr =
                    ts != null ? _formatDate(ts.toDate()) : '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: _ReviewCard(
                    name: name,
                    date: dateStr,
                    rating: rating,
                    comment: comment,
                    isWeb: false,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ── Shared widgets ─────────────────────────────────────────────────────────

  Widget _buildRatingSummaryCard(double average, int total) {
    final displayAvg = average.toStringAsFixed(1);
    final int filledStars = average.round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF47C20), Color(0xFFFFD166)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF47C20).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                total == 0 ? '--' : displayAvg,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const Text(
                'OUT OF 5',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < filledStars ? Icons.star : Icons.star_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  total == 0
                      ? 'No reviews yet'
                      : 'Based on $total review${total == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(Icons.rate_review_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'All'
                ? 'No feedback yet.'
                : 'No $_selectedFilter reviews.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildNoHall(bool isWide) => Scaffold(
    backgroundColor: isWide ? const Color(0xFFF5F7FA) : const Color(0xFFF9FAFB),
    appBar:
        isWide
            ? null
            : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Feedbacks',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    body: const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.store_outlined, size: 60, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No hall registered.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  WEB FILTER TILE
// ══════════════════════════════════════════════════════════════════════════════

class _WebFilterTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final int count;
  final VoidCallback onTap;

  const _WebFilterTile({
    required this.label,
    required this.isSelected,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF47C20);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? orange.withOpacity(0.09) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border:
              isSelected ? Border.all(color: orange.withOpacity(0.25)) : null,
        ),
        child: Row(
          children: [
            // Star icon for star filters
            if (label != 'All')
              const Icon(Icons.star, color: Colors.amber, size: 15)
            else
              Icon(
                Icons.all_inclusive,
                size: 15,
                color: isSelected ? orange : Colors.grey[500],
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  color: isSelected ? orange : Colors.grey[600],
                ),
              ),
            ),
            // Count badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? orange.withOpacity(0.12)
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? orange : Colors.grey[500],
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: orange,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  MOBILE FILTER CHIP  (horizontal scroll row — mobile only)
// ══════════════════════════════════════════════════════════════════════════════

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF47C20) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey.shade300),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: const Color(0xFFF47C20).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                  : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  REVIEW CARD
// ══════════════════════════════════════════════════════════════════════════════

class _ReviewCard extends StatelessWidget {
  final String name;
  final String date;
  final int rating;
  final String comment;
  final bool isWeb;

  const _ReviewCard({
    required this.name,
    required this.date,
    required this.rating,
    required this.comment,
    required this.isWeb,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(isWeb ? 0.06 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isWeb ? Colors.grey.shade200 : Colors.grey.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFFFF7ED),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'C',
                  style: const TextStyle(
                    color: Color(0xFFF47C20),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    if (date.isNotEmpty)
                      Text(
                        date,
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                  ],
                ),
              ),
              // Star rating badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Star row (web only — gives a richer visual on wider cards)
          if (isWeb) ...[
            const SizedBox(height: 10),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < rating ? Icons.star : Icons.star_outline,
                  color: Colors.amber,
                  size: 15,
                ),
              ),
            ),
          ],

          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              comment,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
