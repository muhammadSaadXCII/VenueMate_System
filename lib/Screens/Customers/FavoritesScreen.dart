import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:venuemate_system/Models/hall_model.dart';
import 'package:venuemate_system/Services/auth_service.dart';
import 'package:venuemate_system/Services/hall_service.dart';
import 'VenueDetailScreen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final String _uid = AuthService.currentUid ?? '';

  Stream<List<HallModel>> _streamFavHalls() {
    if (_uid.isEmpty) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('favorites')
        .doc(_uid)
        .collection('halls')
        .snapshots()
        .asyncMap((snap) async {
          final ids = snap.docs.map((d) => d.id).toList();
          final halls = await Future.wait(
            ids.map((id) => HallService.getHallById(id)),
          );
          return halls.whereType<HallModel>().toList();
        });
  }

  Future<void> _removeFav(String hallId) async {
    await FirebaseFirestore.instance
        .collection('favorites')
        .doc(_uid)
        .collection('halls')
        .doc(hallId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE8650A), Color(0xFFF47C20), Color(0xFFFAA94E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33F47C20),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              child: const Center(
                child: Text(
                  'My Favorites',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),

            // ── List ────────────────────────────────────────────────────
            Expanded(
              child: _uid.isEmpty
                  ? _emptyState()
                  : StreamBuilder<List<HallModel>>(
                      stream: _streamFavHalls(),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: Color(0xFFF47C20)),
                          );
                        }
                        final halls = snap.data ?? [];
                        if (halls.isEmpty) return _emptyState();
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          itemCount: halls.length,
                          itemBuilder: (_, i) => _buildFavoriteCard(halls[i]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────
  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0E0),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.favorite_border_rounded, size: 56, color: Color(0xFFF47C20)),
        ),
        const SizedBox(height: 20),
        const Text(
          'No favorites yet',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
        ),
        const SizedBox(height: 8),
        Text(
          'Save venues you love and\nfind them here anytime.',
          style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.5),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  // ── Favorite card ──────────────────────────────────────────────────────
  Widget _buildFavoriteCard(HallModel h) {
    final img = h.imageUrls.isNotEmpty ? h.imageUrls.first : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => VenueDetailsScreen(hallId: h.hallId)),
                  ),
                  child: img.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: img,
                          height: 210,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(height: 210, color: Colors.grey[200]),
                          errorWidget: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
              // Remove (filled heart)
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () => _removeFav(h.hallId),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6),
                      ],
                    ),
                    child: const Icon(Icons.favorite_rounded, color: Colors.red, size: 18),
                  ),
                ),
              ),
              // Rating badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 6),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        h.ratingCount == 0 ? 'New' : h.ratingAvg.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Info section
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + review count badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        h.hallName,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0E0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${h.ratingCount} reviews',
                        style: const TextStyle(fontSize: 11, color: Color(0xFFF47C20), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Address
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        h.address.isNotEmpty ? h.address : '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Capacity
                Row(
                  children: [
                    const Icon(Icons.people_alt_outlined, size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${h.capacityMin}–${h.capacityMax} Guests',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 10),
                // Price + View button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Starting from', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text(
                          h.priceLabel,
                          style: const TextStyle(
                            color: Color(0xFFF47C20),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => VenueDetailsScreen(hallId: h.hallId)),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF47C20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'View Details',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    height: 210,
    width: double.infinity,
    color: Colors.grey[200],
    child: const Center(child: Icon(Icons.business, color: Colors.grey, size: 40)),
  );
}