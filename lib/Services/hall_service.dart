import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../Models/hall_model.dart';
import 'notification_service.dart';
import 'storage_service.dart';

/// Handles all Firestore and Storage operations for the `halls` collection.
class HallService {
  static final _db = FirebaseFirestore.instance;
  static final _halls = _db.collection('halls');
  static const _uuid = Uuid();

  // ════════════════════════════════════════════════════════════════════════════
  //  REGISTER A NEW HALL (5-step form submit)
  // ════════════════════════════════════════════════════════════════════════════
  /// Creates the hall document in Firestore and uploads all files to Storage.
  ///
  /// Call this when the venue owner clicks "Submit for Verification"
  /// in ReviewSubmitStep. Returns the new [hallId] on success, or null on error.
  static Future<String?> registerHall({
    required String ownerId,
    // Step 1 – Basic Details
    required String ownerName,
    required String contactPhone,
    required File cnicFront,
    required File cnicBack,
    // Step 2 – Hall Details
    required String hallName,
    required double pricePerEvent,
    required String address,
    required double latitude,
    required double longitude,
    required int capacityMin,
    required int capacityMax,
    required String description,
    // Step 3 – Uploads & Payouts
    required List<File> hallPhotos,
    required String bankName,
    required String bankAccountNumber,
    required File ntnDoc,
    required File businessLicense,
  }) async {
    try {
      final String hallId = _uuid.v4();

      // 1. Upload CNIC images
      final String? cnicFrontUrl = await StorageService.uploadHallDocument(
        hallId: hallId,
        documentFile: cnicFront,
        docType: 'cnic_front',
      );
      final String? cnicBackUrl = await StorageService.uploadHallDocument(
        hallId: hallId,
        documentFile: cnicBack,
        docType: 'cnic_back',
      );

      // 2. Upload hall photos
      final List<String> imageUrls =
          await StorageService.uploadMultipleHallImages(
            hallId: hallId,
            imageFiles: hallPhotos,
          );

      // 3. Upload legal documents
      final String? ntnUrl = await StorageService.uploadHallDocument(
        hallId: hallId,
        documentFile: ntnDoc,
        docType: 'ntn',
      );
      final String? licenseUrl = await StorageService.uploadHallDocument(
        hallId: hallId,
        documentFile: businessLicense,
        docType: 'business_license',
      );

      // 4. Build HallModel
      final HallModel hall = HallModel(
        hallId: hallId,
        ownerId: ownerId,
        hallName: hallName,
        description: description,
        contactPhone: contactPhone,
        address: address,
        latitude: latitude,
        longitude: longitude,
        capacityMin: capacityMin,
        capacityMax: capacityMax,
        pricePerEvent: pricePerEvent,
        imageUrls: imageUrls,
        bankName: bankName,
        bankAccountNumber: bankAccountNumber,
        cnicFrontUrl: cnicFrontUrl ?? '',
        cnicBackUrl: cnicBackUrl ?? '',
        ntnDocUrl: ntnUrl ?? '',
        businessLicenseUrl: licenseUrl ?? '',
        status: 'pending', // system admin must approve
        isVisible: false, // hidden until approved
        createdAt: DateTime.now(),
      );

      // 5. Save to Firestore
      await _halls.doc(hallId).set(hall.toMap());

      return hallId; // success
    } catch (e) {
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  REGISTER HALL — XFile variant (web-safe, works on all platforms)
  // ════════════════════════════════════════════════════════════════════════════

  static Future<String?> registerHallXFile({
    required String ownerId,
    required String ownerName,
    required String contactPhone,
    required XFile cnicFront,
    required XFile cnicBack,
    required String hallName,
    required double pricePerEvent,
    required String address,
    required double latitude,
    required double longitude,
    required int capacityMin,
    required int capacityMax,
    required String description,
    required List<XFile> hallPhotos,
    required String bankName,
    required String bankAccountNumber,
    required XFile ntnDoc,
    required XFile businessLicense,
  }) async {
    try {
      final String hallId = _uuid.v4();

      final String? cnicFrontUrl = await StorageService.uploadHallDocumentXFile(
        hallId: hallId,
        xFile: cnicFront,
        docType: 'cnic_front',
      );
      final String? cnicBackUrl = await StorageService.uploadHallDocumentXFile(
        hallId: hallId,
        xFile: cnicBack,
        docType: 'cnic_back',
      );
      final List<String> imageUrls =
          await StorageService.uploadMultipleHallImagesXFile(
            hallId: hallId,
            xFiles: hallPhotos,
          );
      final String? ntnUrl = await StorageService.uploadHallDocumentXFile(
        hallId: hallId,
        xFile: ntnDoc,
        docType: 'ntn',
      );
      final String? licenseUrl = await StorageService.uploadHallDocumentXFile(
        hallId: hallId,
        xFile: businessLicense,
        docType: 'business_license',
      );

      final HallModel hall = HallModel(
        hallId: hallId,
        ownerId: ownerId,
        hallName: hallName,
        description: description,
        contactPhone: contactPhone,
        address: address,
        latitude: latitude,
        longitude: longitude,
        capacityMin: capacityMin,
        capacityMax: capacityMax,
        pricePerEvent: pricePerEvent,
        imageUrls: imageUrls,
        bankName: bankName,
        bankAccountNumber: bankAccountNumber,
        cnicFrontUrl: cnicFrontUrl ?? '',
        cnicBackUrl: cnicBackUrl ?? '',
        ntnDocUrl: ntnUrl ?? '',
        businessLicenseUrl: licenseUrl ?? '',
        status: 'pending',
        isVisible: false,
        createdAt: DateTime.now(),
      );

      await _halls.doc(hallId).set(hall.toMap());
      return hallId;
    } catch (e) {
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  READ HALL
  // ════════════════════════════════════════════════════════════════════════════

  static Future<HallModel?> getHallById(String hallId) async {
    try {
      final doc = await _halls.doc(hallId).get();
      if (!doc.exists) return null;
      return HallModel.fromDoc(doc);
    } catch (_) {
      return null;
    }
  }

  /// Get the hall owned by a specific venue owner.
  /// (Each venue owner registers ONE hall in this system.)
  static Future<HallModel?> getHallByOwnerId(String ownerId) async {
    try {
      final snap =
          await _halls.where('ownerId', isEqualTo: ownerId).limit(1).get();
      if (snap.docs.isEmpty) return null;
      return HallModel.fromDoc(snap.docs.first);
    } catch (_) {
      return null;
    }
  }

  /// Stream a hall in real-time. Used in ManageHallScreen header.
  static Stream<HallModel?> streamHallByOwnerId(String ownerId) {
    return _halls
        .where('ownerId', isEqualTo: ownerId)
        .limit(1)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.isEmpty ? null : HallModel.fromDoc(snap.docs.first),
        );
  }

  /// Stream all approved + visible halls. Used on Customer HomeScreen.
  static Stream<List<HallModel>> streamApprovedHalls() {
    return _halls
        .where('status', isEqualTo: 'approved')
        .where('isVisible', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => HallModel.fromDoc(d)).toList());
  }

  /// Get all halls regardless of status. Used by SystemAdmin.
  static Stream<List<HallModel>> streamAllHalls() {
    return _halls
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => HallModel.fromDoc(d)).toList());
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  UPDATE HALL DETAILS
  // ════════════════════════════════════════════════════════════════════════════

  /// Update public-facing info (description, capacity, price).
  static Future<String?> updateHallDetails({
    required String hallId,
    String? hallName,
    String? description,
    String? contactPhone,
    String? address,
    double? latitude,
    double? longitude,
    int? capacityMin,
    int? capacityMax,
    double? pricePerEvent,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (hallName != null) updates['hallName'] = hallName;
      if (description != null) updates['description'] = description;
      if (contactPhone != null) updates['contactPhone'] = contactPhone;
      if (pricePerEvent != null) updates['pricePerEvent'] = pricePerEvent;
      if (address != null || latitude != null || longitude != null) {
        final locSnap = await _halls.doc(hallId).get();
        final current = (locSnap.data()?['location'] as Map?) ?? {};
        updates['location'] = {
          'address': address ?? current['address'],
          'lat': latitude ?? current['lat'],
          'lng': longitude ?? current['lng'],
        };
      }
      if (capacityMin != null || capacityMax != null) {
        final capSnap = await _halls.doc(hallId).get();
        final current = (capSnap.data()?['capacity'] as Map?) ?? {};
        updates['capacity'] = {
          'min': capacityMin ?? current['min'],
          'max': capacityMax ?? current['max'],
        };
      }
      if (updates.isEmpty) return 'No changes to save.';
      await _halls.doc(hallId).update(updates);
      return null;
    } catch (_) {
      return 'Failed to update hall details.';
    }
  }

  /// Add a new hall photo to the existing list.
  static Future<String?> addHallPhoto({
    required String hallId,
    required File imageFile,
  }) async {
    try {
      final url = await StorageService.uploadHallImage(
        hallId: hallId,
        imageFile: imageFile,
      );
      if (url == null) return 'Failed to upload image.';
      await _halls.doc(hallId).update({
        'imageUrls': FieldValue.arrayUnion([url]),
      });
      return null;
    } catch (_) {
      return 'Failed to add photo.';
    }
  }

  /// Web-safe: add hall photo from XFile (works on web + mobile).
  static Future<String?> addHallPhotoXFile({
    required String hallId,
    required XFile xFile,
  }) async {
    try {
      final url = await StorageService.uploadHallImageXFile(
        hallId: hallId,
        xFile: xFile,
      );
      if (url == null) return 'Failed to upload image.';
      await _halls.doc(hallId).update({
        'imageUrls': FieldValue.arrayUnion([url]),
      });
      return null;
    } catch (_) {
      return 'Failed to add photo.';
    }
  }

  /// Remove a hall photo by its download URL.
  static Future<String?> removeHallPhoto({
    required String hallId,
    required String imageUrl,
  }) async {
    try {
      await StorageService.deleteHallImage(imageUrl);
      await _halls.doc(hallId).update({
        'imageUrls': FieldValue.arrayRemove([imageUrl]),
      });
      return null;
    } catch (_) {
      return 'Failed to remove photo.';
    }
  }

  /// Completely wipes a hall from Firestore AND Firebase Storage.
  ///
  /// Called when an admin rejects a registration and the hall owner
  /// wants to start over. Deletes:
  ///   Firestore:
  ///     • halls/{hallId}                     (main doc)
  ///     • halls/{hallId}/menu/{*}            (all menu items)
  ///     • halls/{hallId}/services/{*}        (all services)
  ///     • halls/{hallId}/packages/{*}        (all packages)
  ///     • halls/{hallId}/reviews/{*}         (any reviews)
  ///   Firebase Storage:
  ///     • halls/{hallId}/images/{*}          (hall photos)
  ///     • halls/{hallId}/documents/{*}       (CNIC, NTN, license)
  ///
  /// Returns null on success, error string on failure.
  static Future<String?> deleteHall(String hallId) async {
    try {
      // ── 1. Delete Storage folder halls/{hallId}/ ──────────────────────────
      // List and delete every file under halls/{hallId}/
      final storageRef = FirebaseStorage.instance.ref().child('halls/$hallId');
      try {
        await _deleteStorageFolder(storageRef);
      } catch (_) {
        // Storage folder may not exist if images failed to upload — not fatal
      }

      // ── 2. Delete Firestore sub-collections ───────────────────────────────
      for (final subCol in ['menu', 'services', 'packages', 'reviews']) {
        final snap = await _halls.doc(hallId).collection(subCol).get();
        for (final doc in snap.docs) {
          await doc.reference.delete();
        }
      }

      // ── 3. Delete the main hall document ──────────────────────────────────
      await _halls.doc(hallId).delete();

      return null; // success
    } catch (e) {
      return 'Failed to delete hall data: $e';
    }
  }

  /// Recursively deletes all files inside a Firebase Storage folder reference.
  static Future<void> _deleteStorageFolder(Reference folderRef) async {
    final ListResult result = await folderRef.listAll();
    // Delete all items (files) in this folder
    for (final item in result.items) {
      await item.delete();
    }
    // Recurse into sub-folders
    for (final prefix in result.prefixes) {
      await _deleteStorageFolder(prefix);
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  SYSTEM ADMIN — Approve / Reject
  // ════════════════════════════════════════════════════════════════════════════

  static Future<String?> approveHall(String hallId) async {
    try {
      await _halls.doc(hallId).update({
        'status': 'approved',
        'isVisible': true,
        'rejectionReason': '',
      });
      // Notify venue owner
      try {
        final doc = await _halls.doc(hallId).get();
        final data = doc.data() ?? {};
        final ownerId = (data['ownerId'] as String?) ?? '';
        final hallName = (data['hallName'] as String?) ?? 'your hall';
        if (ownerId.isNotEmpty) {
          unawaited(
            NotificationService.sendHallApproved(
              venueOwnerUid: ownerId,
              hallId: hallId,
              hallName: hallName,
            ),
          );
        }
      } catch (_) {}
      return null;
    } catch (_) {
      return 'Failed to approve hall.';
    }
  }

  static Future<String?> rejectHall({
    required String hallId,
    required String reason,
  }) async {
    try {
      await _halls.doc(hallId).update({
        'status': 'rejected',
        'isVisible': false,
        'rejectionReason': reason,
      });
      // Notify venue owner
      try {
        final doc = await _halls.doc(hallId).get();
        final data = doc.data() ?? {};
        final ownerId = (data['ownerId'] as String?) ?? '';
        final hallName = (data['hallName'] as String?) ?? 'your hall';
        if (ownerId.isNotEmpty) {
          unawaited(
            NotificationService.sendHallRejected(
              venueOwnerUid: ownerId,
              hallId: hallId,
              hallName: hallName,
              reason: reason,
            ),
          );
        }
      } catch (_) {}
      return null;
    } catch (_) {
      return 'Failed to reject hall.';
    }
  }

  /// Get all pending halls for the system admin's review queue.
  static Stream<List<HallModel>> streamPendingHalls() {
    return _halls
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map((d) => HallModel.fromDoc(d)).toList());
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  SEARCH
  // ════════════════════════════════════════════════════════════════════════════

  /// Simple in-memory search on hall name. For production, use Algolia.
  static Future<List<HallModel>> searchHalls(String query) async {
    try {
      final snap =
          await _halls
              .where('status', isEqualTo: 'approved')
              .where('isVisible', isEqualTo: true)
              .get();
      final all = snap.docs.map((d) => HallModel.fromDoc(d)).toList();
      if (query.trim().isEmpty) return all;
      final q = query.toLowerCase();
      return all.where((h) => h.hallName.toLowerCase().contains(q)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Disable/Enable a hall (System Admin) ──────────────────────────────────────────
  // Sets halls/{hallId}.isVisible = false without changing status.

  static Future<String?> disableHall(String hallId) async {
    try {
      await FirebaseFirestore.instance.collection('halls').doc(hallId).update({
        'isVisible': false,
      });
      return null;
    } catch (e) {
      return 'Failed to disable hall: $e';
    }
  }

  static Future<String?> enableHall(String hallId) async {
    try {
      await FirebaseFirestore.instance.collection('halls').doc(hallId).update({
        'isVisible': true,
      });
      return null;
    } catch (e) {
      return 'Failed to enable hall: $e';
    }
  }
}
