import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Smart image-aware MenuItemCard.
/// [imageUrl] can be:
///   - A base64 data-URI  (starts with 'data:image') → Image.memory  ✅ web+mobile
///   - A Firebase Storage https:// URL               → Image.network  ✅ web+mobile
///   - A local file path  (starts with '/')          → Image.file     ✅ mobile only
///   - Empty string                                   → grey placeholder
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
    if (imageUrl.isEmpty) return _placeholder(size);

    // Base64 data-URI — works on web + mobile (set by AddMenuItemSheet)
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64Str = imageUrl.substring(imageUrl.indexOf(',') + 1);
        final Uint8List bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(size),
        );
      } catch (_) {
        return _placeholder(size);
      }
    }

    // Remote Firebase Storage URL — works on web + mobile
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(size),
      );
    }

    // Local file path — mobile only (legacy path from before web support)
    if (!kIsWeb &&
        (imageUrl.startsWith('/') || imageUrl.startsWith('file://'))) {
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
    }

    return _placeholder(size);
  }

  Widget _placeholder(double size) => Container(
    width: size,
    height: size,
    color: Colors.grey[200],
    child: Icon(Icons.fastfood, color: Colors.grey[400], size: 28),
  );
}
