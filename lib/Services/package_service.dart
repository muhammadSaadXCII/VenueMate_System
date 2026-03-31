import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../Models/package_model.dart';

const _uuid = Uuid();

// ══════════════════════════════════════════════════════════════════════════════
//  PACKAGE SERVICE  →  halls/{hallId}/packages
// ══════════════════════════════════════════════════════════════════════════════
class PackageService {
  static CollectionReference _ref(String hallId) => FirebaseFirestore.instance
      .collection('halls')
      .doc(hallId)
      .collection('packages');

  // ── CREATE ─────────────────────────────────────────────────────────────────
  static Future<String?> createPackage({
    required String hallId,
    required String name,
    required double price,
    required int capacityMin,
    required int capacityMax,
    String description = '',
    List<String> menuItemIds = const [],
    List<String> serviceItemIds = const [],
  }) async {
    try {
      final String packageId = _uuid.v4();
      final PackageModel pkg = PackageModel(
        packageId: packageId,
        hallId: hallId,
        name: name,
        description: description,
        price: price,
        capacityMin: capacityMin,
        capacityMax: capacityMax,
        menuItemIds: menuItemIds,
        serviceItemIds: serviceItemIds,
        isActive: true,
        createdAt: DateTime.now(),
      );
      await _ref(hallId).doc(packageId).set(pkg.toMap());
      return null; // success
    } catch (_) {
      return 'Failed to create package. Please try again.';
    }
  }

  // ── READ ───────────────────────────────────────────────────────────────────

  /// Stream all packages for a hall.
  /// Used in ManagePackagesScreen and VenueDetailScreen (Packages tab).
  static Stream<List<PackageModel>> streamPackages(String hallId) {
    return _ref(hallId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => PackageModel.fromDoc(d)).toList());
  }

  static Future<List<PackageModel>> getPackages(String hallId) async {
    try {
      final snap = await _ref(hallId).get();
      return snap.docs.map((d) => PackageModel.fromDoc(d)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── UPDATE ─────────────────────────────────────────────────────────────────
  static Future<String?> updatePackage({
    required String hallId,
    required String packageId,
    String? name,
    double? price,
    String? description,
    int? capacityMin,
    int? capacityMax,
    List<String>? menuItemIds,
    List<String>? serviceItemIds,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (price != null) updates['price'] = price;
      if (description != null) updates['description'] = description;
      if (menuItemIds != null) updates['menuItemIds'] = menuItemIds;
      if (serviceItemIds != null) updates['serviceItemIds'] = serviceItemIds;
      if (capacityMin != null || capacityMax != null) {
        final snap = await _ref(hallId).doc(packageId).get();
        final current = (snap.data() as Map?)?.cast<String, dynamic>() ?? {};
        final currentCap = current['capacity'] as Map? ?? {};
        updates['capacity'] = {
          'min': capacityMin ?? currentCap['min'],
          'max': capacityMax ?? currentCap['max'],
        };
      }
      if (updates.isEmpty) return 'No changes provided.';
      await _ref(hallId).doc(packageId).update(updates);
      return null;
    } catch (_) {
      return 'Failed to update package.';
    }
  }

  /// Toggle a package between active and inactive.
  static Future<String?> togglePackageStatus({
    required String hallId,
    required String packageId,
    required bool isActive,
  }) async {
    try {
      await _ref(hallId).doc(packageId).update({'isActive': isActive});
      return null;
    } catch (_) {
      return 'Failed to update package status.';
    }
  }

  // ── DELETE ─────────────────────────────────────────────────────────────────
  static Future<String?> deletePackage({
    required String hallId,
    required String packageId,
  }) async {
    try {
      await _ref(hallId).doc(packageId).delete();
      return null;
    } catch (_) {
      return 'Failed to delete package.';
    }
  }
}
