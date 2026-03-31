import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../Models/service_item_model.dart';

const _uuid = Uuid();

// ══════════════════════════════════════════════════════════════════════════════
//  SERVICE ITEM SERVICE  →  halls/{hallId}/services
// ══════════════════════════════════════════════════════════════════════════════
class ServiceItemService {
  static CollectionReference _ref(String hallId) => FirebaseFirestore.instance
      .collection('halls')
      .doc(hallId)
      .collection('services');

  // ── CREATE ─────────────────────────────────────────────────────────────────
  static Future<String?> addService({
    required String hallId,
    required String name,
    required double price,
    String description = '',
  }) async {
    try {
      final String serviceId = _uuid.v4();
      final ServiceItemModel service = ServiceItemModel(
        serviceId: serviceId,
        hallId: hallId,
        name: name,
        description: description,
        price: price,
        createdAt: DateTime.now(),
      );
      await _ref(hallId).doc(serviceId).set(service.toMap());
      return null; // success
    } catch (_) {
      return 'Failed to add service. Please try again.';
    }
  }

  // ── READ ───────────────────────────────────────────────────────────────────

  /// Stream all services for a hall in real-time.
  /// Used in ManageServicesScreen and VenueDetailScreen (Services tab).
  static Stream<List<ServiceItemModel>> streamServices(String hallId) {
    return _ref(hallId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => ServiceItemModel.fromDoc(d)).toList(),
        );
  }

  /// One-time fetch. Used in CreatePackage service picker.
  static Future<List<ServiceItemModel>> getServices(String hallId) async {
    try {
      final snap =
          await _ref(hallId).orderBy('createdAt', descending: false).get();
      return snap.docs.map((d) => ServiceItemModel.fromDoc(d)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── UPDATE ─────────────────────────────────────────────────────────────────
  static Future<String?> updateService({
    required String hallId,
    required String serviceId,
    String? name,
    double? price,
    String? description,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (price != null) updates['price'] = price;
      if (description != null) updates['description'] = description;
      if (updates.isEmpty) return 'No changes provided.';
      await _ref(hallId).doc(serviceId).update(updates);
      return null;
    } catch (_) {
      return 'Failed to update service.';
    }
  }

  // ── DELETE ─────────────────────────────────────────────────────────────────
  static Future<String?> deleteService({
    required String hallId,
    required String serviceId,
  }) async {
    try {
      await _ref(hallId).doc(serviceId).delete();
      return null;
    } catch (_) {
      return 'Failed to delete service.';
    }
  }
}
