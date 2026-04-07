import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../Models/menu_item_model.dart';
import 'storage_service.dart';

/// Handles all CRUD for the `halls/{hallId}/menu` sub-collection.
class MenuService {
  static const _uuid = Uuid();

  static CollectionReference _menuRef(String hallId) => FirebaseFirestore
      .instance
      .collection('halls')
      .doc(hallId)
      .collection('menu');

  // ════════════════════════════════════════════════════════════════════════════
  //  CREATE
  // ════════════════════════════════════════════════════════════════════════════

  /// Add a new menu item.
  /// If [imageFile] is provided it is uploaded to Storage first.
  /// Returns null on success, error string on failure.
  static Future<String?> addMenuItem({
    required String hallId,
    required String name,
    required double price,
    required String priceUnit,
    String description = '',
    File? imageFile,
  }) async {
    try {
      final String itemId = _uuid.v4();
      String imageUrl = '';

      if (imageFile != null) {
        imageUrl =
            await StorageService.uploadHallImage(
              hallId: hallId,
              imageFile: imageFile,
            ) ??
            '';
      }

      final MenuItemModel item = MenuItemModel(
        itemId: itemId,
        hallId: hallId,
        name: name,
        description: description,
        price: price,
        priceUnit: priceUnit,
        imageUrl: imageUrl,
        isAvailable: true,
        createdAt: DateTime.now(),
      );

      await _menuRef(hallId).doc(itemId).set(item.toMap());
      return null; // success
    } catch (_) {
      return 'Failed to add menu item. Please try again.';
    }
  }

  /// Web-safe: add menu item using XFile (works on web + mobile).
  static Future<String?> addMenuItemXFile({
    required String hallId,
    required String name,
    required double price,
    required String priceUnit,
    String description = '',
    XFile? imageXFile,
  }) async {
    try {
      final String itemId = _uuid.v4();
      String imageUrl = '';
      if (imageXFile != null) {
        imageUrl =
            await StorageService.uploadHallImageXFile(
              hallId: hallId,
              xFile: imageXFile,
            ) ??
            '';
      }
      final MenuItemModel item = MenuItemModel(
        itemId: itemId,
        hallId: hallId,
        name: name,
        description: description,
        price: price,
        priceUnit: priceUnit,
        imageUrl: imageUrl,
        isAvailable: true,
        createdAt: DateTime.now(),
      );
      await _menuRef(hallId).doc(itemId).set(item.toMap());
      return null;
    } catch (_) {
      return 'Failed to add menu item. Please try again.';
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  READ
  // ════════════════════════════════════════════════════════════════════════════

  /// Stream all menu items for a hall in real-time.
  /// Used in ManageMenuScreen and VenueDetailScreen (Menu tab).
  static Stream<List<MenuItemModel>> streamMenuItems(String hallId) {
    return _menuRef(hallId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => MenuItemModel.fromDoc(d)).toList());
  }

  /// One-time fetch. Used in CreatePackage step 2 (item picker).
  static Future<List<MenuItemModel>> getMenuItems(String hallId) async {
    try {
      final snap =
          await _menuRef(hallId).orderBy('createdAt', descending: false).get();
      return snap.docs.map((d) => MenuItemModel.fromDoc(d)).toList();
    } catch (_) {
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  UPDATE
  // ════════════════════════════════════════════════════════════════════════════

  /// Update name, price, description, unit, or availability.
  static Future<String?> updateMenuItem({
    required String hallId,
    required String itemId,
    String? name,
    double? price,
    String? priceUnit,
    String? description,
    bool? isAvailable,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (price != null) updates['price'] = price;
      if (priceUnit != null) updates['priceUnit'] = priceUnit;
      if (description != null) updates['description'] = description;
      if (isAvailable != null) updates['isAvailable'] = isAvailable;
      if (updates.isEmpty) return 'No changes provided.';
      await _menuRef(hallId).doc(itemId).update(updates);
      return null;
    } catch (_) {
      return 'Failed to update menu item.';
    }
  }

  /// Toggle availability (sold out / available).
  static Future<String?> toggleAvailability({
    required String hallId,
    required String itemId,
    required bool isAvailable,
  }) async {
    try {
      await _menuRef(hallId).doc(itemId).update({'isAvailable': isAvailable});
      return null;
    } catch (_) {
      return 'Failed to update availability.';
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  DELETE
  // ════════════════════════════════════════════════════════════════════════════

  static Future<String?> deleteMenuItem({
    required String hallId,
    required String itemId,
    String? imageUrl,
  }) async {
    try {
      // Delete from Storage if it has an image
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await StorageService.deleteHallImage(imageUrl);
      }
      await _menuRef(hallId).doc(itemId).delete();
      return null;
    } catch (_) {
      return 'Failed to delete menu item.';
    }
  }
}
