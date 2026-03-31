import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role; // 'customer' | 'venue_owner' | 'system_admin'
  final String profileImageUrl;
  final bool isEmailVerified;
  final String authProvider; // 'email' | 'google'
  final bool isDisabled;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.profileImageUrl = '',
    this.isEmailVerified = false,
    this.authProvider = 'email',
    this.isDisabled = false,
    required this.createdAt,
  });

  // ── Firestore → Model ──────────────────────────────────────────────────────
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'customer',
      profileImageUrl: map['profileImageUrl'] ?? '',
      isEmailVerified: map['isEmailVerified'] ?? false,
      authProvider: map['authProvider'] ?? 'email',
      isDisabled: map['isDisabled'] ?? false,
      createdAt:
          map['createdAt'] != null
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
    );
  }

  factory UserModel.fromDoc(DocumentSnapshot doc) {
    return UserModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  // ── Model → Firestore ──────────────────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'profileImageUrl': profileImageUrl,
      'isEmailVerified': isEmailVerified,
      'authProvider': authProvider,
      'isDisabled': isDisabled,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // ── Copy with updated fields ───────────────────────────────────────────────
  UserModel copyWith({
    String? name,
    String? phone,
    String? profileImageUrl,
    bool? isEmailVerified,
    bool? isDisabled,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      authProvider: authProvider,
      isDisabled: isDisabled ?? this.isDisabled,
      createdAt: createdAt,
    );
  }

  // ── Helper getters ─────────────────────────────────────────────────────────
  bool get isCustomer => role == 'customer';
  bool get isVenueOwner => role == 'venue_owner';
  bool get isSystemAdmin => role == 'system_admin';
  bool get isActive => !isDisabled;
}
