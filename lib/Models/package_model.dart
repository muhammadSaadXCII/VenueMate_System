import 'package:cloud_firestore/cloud_firestore.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  PACKAGE  →  halls/{hallId}/packages/{packageId}
// ══════════════════════════════════════════════════════════════════════════════
class PackageModel {
  final String packageId;
  final String hallId;
  final String name;
  final String description;
  final double price;
  final int capacityMin;
  final int capacityMax;
  final List<String> menuItemIds; // references to halls/{hallId}/menu
  final List<String> serviceItemIds; // references to halls/{hallId}/services
  final bool isActive;
  final DateTime createdAt;

  PackageModel({
    required this.packageId,
    required this.hallId,
    required this.name,
    this.description = '',
    required this.price,
    this.capacityMin = 0,
    this.capacityMax = 0,
    this.menuItemIds = const [],
    this.serviceItemIds = const [],
    this.isActive = true,
    required this.createdAt,
  });

  factory PackageModel.fromMap(Map<String, dynamic> map) {
    final capacity = map['capacity'] as Map<String, dynamic>? ?? {};
    return PackageModel(
      packageId: map['packageId'] ?? '',
      hallId: map['hallId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      capacityMin: (capacity['min'] ?? 0).toInt(),
      capacityMax: (capacity['max'] ?? 0).toInt(),
      menuItemIds: List<String>.from(map['menuItemIds'] ?? []),
      serviceItemIds: List<String>.from(map['serviceItemIds'] ?? []),
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory PackageModel.fromDoc(DocumentSnapshot doc) =>
      PackageModel.fromMap(doc.data() as Map<String, dynamic>);

  Map<String, dynamic> toMap() => {
    'packageId': packageId,
    'hallId': hallId,
    'name': name,
    'description': description,
    'price': price,
    'capacity': {'min': capacityMin, 'max': capacityMax},
    'menuItemIds': menuItemIds,
    'serviceItemIds': serviceItemIds,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  PackageModel copyWith({
    String? name,
    String? description,
    double? price,
    int? capacityMin,
    int? capacityMax,
    List<String>? menuItemIds,
    List<String>? serviceItemIds,
    bool? isActive,
  }) => PackageModel(
    packageId: packageId,
    hallId: hallId,
    name: name ?? this.name,
    description: description ?? this.description,
    price: price ?? this.price,
    capacityMin: capacityMin ?? this.capacityMin,
    capacityMax: capacityMax ?? this.capacityMax,
    menuItemIds: menuItemIds ?? this.menuItemIds,
    serviceItemIds: serviceItemIds ?? this.serviceItemIds,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt,
  );

  String get priceLabel => 'Rs. ${price.toStringAsFixed(0)}';
  String get capacityLabel => '$capacityMin – $capacityMax Guests';
  String get menuCount => '${menuItemIds.length} Menu Items';
  String get serviceCount => '${serviceItemIds.length} Services';
}
