import 'dart:io';
import 'storage_service.dart';
import '../Models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Handles all Firestore operations for the `users` collection.
/// Use [AuthService] for login/signup. Use [UserService] for profile data.
class UserService {
  static final _firestore = FirebaseFirestore.instance;
  static final _usersRef = FirebaseFirestore.instance.collection('users');

  // ════════════════════════════════════════════════════════════════════════════
  //  GET USER
  // ════════════════════════════════════════════════════════════════════════════

  /// Get a single user by UID. Returns null if not found.
  static Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromDoc(doc);
    } catch (e) {
      return null;
    }
  }

  /// Stream a user's document — auto-updates the UI when Firestore changes.
  /// Use this in screens that show profile info (ProfileScreen, HallAdminHome).
  static Stream<UserModel?> streamUser(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromDoc(doc);
    });
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  UPDATE PROFILE
  // ════════════════════════════════════════════════════════════════════════════

  /// Update name and/or phone number.
  /// Returns null on success, error string on failure.
  static Future<String?> updateProfile({
    required String uid,
    String? name,
    String? phone,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (name != null && name.trim().isNotEmpty) updates['name'] = name.trim();
      if (phone != null && phone.trim().isNotEmpty) {
        updates['phone'] = phone.trim();
      }

      if (updates.isEmpty) return 'No changes to save.';

      await _usersRef.doc(uid).update(updates);
      return null; // success
    } catch (e) {
      return 'Failed to update profile. Please try again.';
    }
  }

  /// Upload a new profile picture and save the download URL to Firestore.
  /// Returns null on success, error string on failure.
  static Future<String?> updateProfileImage({
    required String uid,
    required File imageFile,
  }) async {
    try {
      // 1. Upload to Firebase Storage
      final String? downloadUrl = await StorageService.uploadProfileImage(
        uid: uid,
        imageFile: imageFile,
      );

      if (downloadUrl == null) {
        return 'Failed to upload image. Please try again.';
      }

      // 2. Save URL to Firestore
      await _usersRef.doc(uid).update({'profileImageUrl': downloadUrl});

      return null; // success
    } catch (e) {
      return 'Failed to update profile image.';
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  SYSTEM ADMIN — Get all users
  // ════════════════════════════════════════════════════════════════════════════

  /// Fetch all users. Used by SystemAdmin's ManageAllUsers screen.
  static Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot =
          await _usersRef.orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) => UserModel.fromDoc(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Stream all users in real time. Used by SystemAdmin dashboard.
  static Stream<List<UserModel>> streamAllUsers() {
    return _usersRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => UserModel.fromDoc(doc)).toList());
  }

  /// Fetch all users with a specific role.
  static Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      final snapshot =
          await _usersRef
              .where('role', isEqualTo: role)
              .orderBy('createdAt', descending: true)
              .get();
      return snapshot.docs.map((doc) => UserModel.fromDoc(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  // ── Disable a user (System Admin) ──────────────────────────────────────────
  /// Sets users/{uid}.isDisabled = true in Firestore.
  /// Returns null on success, error string on failure.
  static Future<String?> disableUser(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isDisabled': true,
      });
      return null;
    } catch (e) {
      return 'Failed to disable user: $e';
    }
  }

  // ── Enable a user (System Admin) ───────────────────────────────────────────
  /// Sets users/{uid}.isDisabled = false in Firestore.
  /// Returns null on success, error string on failure.
  static Future<String?> enableUser(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isDisabled': false,
      });
      return null;
    } catch (e) {
      return 'Failed to enable user: $e';
    }
  }

  // ── Stream all users filtered by role ──────────────────────────────────────
  /// Stream all users. Optionally filter by role.
  /// Used in ManageAllUsersScreen with live filter chips.
  static Stream<List<UserModel>> streamAllUsersFiltered({String? role}) {
    Query query = FirebaseFirestore.instance
        .collection('users')
        .orderBy('createdAt', descending: true);
    if (role != null) query = query.where('role', isEqualTo: role);
    return query.snapshots().map(
      (s) => s.docs.map((d) => UserModel.fromDoc(d)).toList(),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  NOTIFICATIONS BADGE COUNT
  // ════════════════════════════════════════════════════════════════════════════

  /// Returns the count of unread notifications for a user.
  static Future<int> getUnreadNotificationCount(String uid) async {
    try {
      final snap =
          await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: uid)
              .where('isRead', isEqualTo: false)
              .get();
      return snap.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Stream unread notification count (for live badge in AppBar).
  static Stream<int> streamUnreadNotificationCount(String uid) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}
