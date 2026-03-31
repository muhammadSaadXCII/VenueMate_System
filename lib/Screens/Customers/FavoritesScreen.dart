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

  // Stream hallIds from favorites/{uid}/halls, then load HallModels
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
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // ── Header (identical to original) ──────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFF47C20),
                    Color.fromARGB(255, 233, 184, 69),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'My Favorites',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── Live favorites list ──────────────────────────────────────────
            Expanded(
              child:
                  _uid.isEmpty
                      ? _emptyState()
                      : StreamBuilder<List<HallModel>>(
                        stream: _streamFavHalls(),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFF47C20),
                              ),
                            );
                          }
                          final halls = snap.data ?? [];
                          if (halls.isEmpty) return _emptyState();
                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
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

  // ── Empty state (identical to original) ───────────────────────────────
  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          'No favorites yet',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Start adding venues and packages to your favorites!',
          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  // ── Favorite card (identical design to original) ───────────────────────
  Widget _buildFavoriteCard(HallModel h) {
    final img = h.imageUrls.isNotEmpty ? h.imageUrls.first : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              // Image — tap to open venue
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: InkWell(
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VenueDetailsScreen(hallId: h.hallId),
                        ),
                      ),
                  child:
                      img.isNotEmpty
                          ? CachedNetworkImage(
                            imageUrl: img,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder:
                                (_, __) => Container(
                                  height: 200,
                                  color: Colors.grey[200],
                                ),
                            errorWidget: (_, __, ___) => _placeholder(),
                          )
                          : _placeholder(),
                ),
              ),
              // Filled heart — tap to remove
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () => _removeFav(h.hallId),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                ),
              ),
              // Rating badge (top left — same as original venue card)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 3),
                      Text(
                        h.ratingCount == 0
                            ? 'New'
                            : h.ratingAvg.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Info section (same design as original)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h.hallName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  h.address.isNotEmpty ? h.address : '—',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '${h.capacityMin}–${h.capacityMax} Capacity',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  h.priceLabel,
                  style: const TextStyle(
                    color: Color(0xFFF47C20),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    height: 200,
    width: double.infinity,
    color: Colors.grey[200],
    child: const Center(
      child: Icon(Icons.business, color: Colors.grey, size: 40),
    ),
  );
}
