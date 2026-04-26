import 'package:cloud_firestore/cloud_firestore.dart';

/// Maps to the `halls/{hallId}` Firestore document.
class HallModel {
  final String hallId;
  final String ownerId;
  final String hallName;
  final String description;
  final String contactPhone;
  final String address;
  final double latitude;
  final double longitude;
  final int capacityMin;
  final int capacityMax;
  final double pricePerEvent;
  final List<String> imageUrls;
  final String bankName;
  final String bankAccountNumber;
  final String cnicFrontUrl;
  final String cnicBackUrl;
  final String ntnDocUrl;
  final String businessLicenseUrl;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String rejectionReason;
  final String disabledReason; // set by system admin when disabling
  final double ratingAvg;
  final int ratingCount;
  final bool isVisible;
  final DateTime createdAt;

  HallModel({
    required this.hallId,
    required this.ownerId,
    required this.hallName,
    this.description = '',
    this.contactPhone = '',
    this.address = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.capacityMin = 0,
    this.capacityMax = 0,
    this.pricePerEvent = 0.0,
    this.imageUrls = const [],
    this.bankName = '',
    this.bankAccountNumber = '',
    this.cnicFrontUrl = '',
    this.cnicBackUrl = '',
    this.ntnDocUrl = '',
    this.businessLicenseUrl = '',
    this.status = 'pending',
    this.rejectionReason = '',
    this.disabledReason = '',
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
    this.isVisible = false,
    required this.createdAt,
  });

  // ── Firestore → Model ──────────────────────────────────────────────────────
  factory HallModel.fromMap(Map<String, dynamic> map) {
    final location = map['location'] as Map<String, dynamic>? ?? {};
    final capacity = map['capacity'] as Map<String, dynamic>? ?? {};
    final rating = map['rating'] as Map<String, dynamic>? ?? {};

    return HallModel(
      hallId: map['hallId'] ?? '',
      ownerId: map['ownerId'] ?? '',
      hallName: map['hallName'] ?? '',
      description: map['description'] ?? '',
      contactPhone: map['contactPhone'] ?? '',
      address: location['address'] ?? '',
      latitude: (location['lat'] ?? 0).toDouble(),
      longitude: (location['lng'] ?? 0).toDouble(),
      capacityMin: (capacity['min'] ?? 0).toInt(),
      capacityMax: (capacity['max'] ?? 0).toInt(),
      pricePerEvent: (map['pricePerEvent'] ?? 0).toDouble(),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      bankName: map['bankName'] ?? '',
      bankAccountNumber: map['bankAccountNumber'] ?? '',
      cnicFrontUrl: map['cnicFrontUrl'] ?? '',
      cnicBackUrl: map['cnicBackUrl'] ?? '',
      ntnDocUrl: map['ntnDocUrl'] ?? '',
      businessLicenseUrl: map['businessLicenseUrl'] ?? '',
      status: map['status'] ?? 'pending',
      rejectionReason: map['rejectionReason'] ?? '',
      disabledReason: map['disabledReason'] ?? '',
      ratingAvg: (rating['avg'] ?? 0).toDouble(),
      ratingCount: (rating['count'] ?? 0).toInt(),
      isVisible: map['isVisible'] ?? false,
      createdAt:
          map['createdAt'] != null
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
    );
  }

  factory HallModel.fromDoc(DocumentSnapshot doc) =>
      HallModel.fromMap(doc.data() as Map<String, dynamic>);

  // ── Model → Firestore ──────────────────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'hallId': hallId,
      'ownerId': ownerId,
      'hallName': hallName,
      'description': description,
      'contactPhone': contactPhone,
      'location': {'address': address, 'lat': latitude, 'lng': longitude},
      'capacity': {'min': capacityMin, 'max': capacityMax},
      'pricePerEvent': pricePerEvent,
      'imageUrls': imageUrls,
      'bankName': bankName,
      'bankAccountNumber': bankAccountNumber,
      'cnicFrontUrl': cnicFrontUrl,
      'cnicBackUrl': cnicBackUrl,
      'ntnDocUrl': ntnDocUrl,
      'businessLicenseUrl': businessLicenseUrl,
      'status': status,
      'rejectionReason': rejectionReason,
      'disabledReason': disabledReason,
      'rating': {'avg': ratingAvg, 'count': ratingCount},
      'isVisible': isVisible,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // ── Copy with changes ──────────────────────────────────────────────────────
  HallModel copyWith({
    String? hallName,
    String? description,
    String? contactPhone,
    String? address,
    double? latitude,
    double? longitude,
    int? capacityMin,
    int? capacityMax,
    double? pricePerEvent,
    List<String>? imageUrls,
    String? bankName,
    String? bankAccountNumber,
    String? status,
    String? rejectionReason,
    String? disabledReason,
    double? ratingAvg,
    int? ratingCount,
    bool? isVisible,
  }) {
    return HallModel(
      hallId: hallId,
      ownerId: ownerId,
      hallName: hallName ?? this.hallName,
      description: description ?? this.description,
      contactPhone: contactPhone ?? this.contactPhone,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      capacityMin: capacityMin ?? this.capacityMin,
      capacityMax: capacityMax ?? this.capacityMax,
      pricePerEvent: pricePerEvent ?? this.pricePerEvent,
      imageUrls: imageUrls ?? this.imageUrls,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      cnicFrontUrl: cnicFrontUrl,
      cnicBackUrl: cnicBackUrl,
      ntnDocUrl: ntnDocUrl,
      businessLicenseUrl: businessLicenseUrl,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      disabledReason: disabledReason ?? this.disabledReason,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      ratingCount: ratingCount ?? this.ratingCount,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  String get capacityLabel => '$capacityMin – $capacityMax Guests';
  String get priceLabel => 'Rs. ${pricePerEvent.toStringAsFixed(0)}/Event';
}
