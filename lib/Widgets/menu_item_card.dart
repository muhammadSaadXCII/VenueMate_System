import 'dart:io';
import 'package:flutter/material.dart';

/// Smart image-aware MenuItemCard.
/// [imageUrl] can be:
///   - A local file path (starts with '/' or contains '/data/') → Image.file
///   - A Firebase Storage https:// URL → Image.network
///   - Empty string → grey placeholder
class MenuItemCard extends StatelessWidget {
  final String name;
  final String price;
  final String priceUnit;
  final String description;
  final String imageUrl;

  const MenuItemCard({
    super.key,
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.priceUnit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Smart image ──────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildImage(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                    children: [
                      TextSpan(
                        text: '$name ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: '\nRs. $price/$priceUnit',
                        style: const TextStyle(
                          color: Color(0xFFF47C20),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    const double size = 60;

    // Empty → placeholder
    if (imageUrl.isEmpty) {
      return _placeholder(size);
    }

    // Local file path (picked from gallery, not yet uploaded)
    if (imageUrl.startsWith('/') || imageUrl.startsWith('file://')) {
      final file = File(imageUrl.replaceFirst('file://', ''));
      if (file.existsSync()) {
        return Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(size),
        );
      }
      return _placeholder(size);
    }

    // Remote URL (Firebase Storage)
    return Image.network(
      imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(size),
    );
  }

  Widget _placeholder(double size) => Container(
    width: size,
    height: size,
    color: Colors.grey[200],
    child: Icon(Icons.fastfood, color: Colors.grey[400], size: 28),
  );
}
