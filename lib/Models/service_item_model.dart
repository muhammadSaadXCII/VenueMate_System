import 'package:cloud_firestore/cloud_firestore.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  SERVICE ITEM  →  halls/{hallId}/services/{serviceId}
// ══════════════════════════════════════════════════════════════════════════════
class ServiceItemModel {
  final String serviceId;
  final String hallId;
  final String name;
  final String description;
  final double price;
  final DateTime createdAt;

  ServiceItemModel({
    required this.serviceId,
    required this.hallId,
    required this.name,
    this.description = '',
    required this.price,
    required this.createdAt,
  });

  factory ServiceItemModel.fromMap(Map<String, dynamic> map) {
    return ServiceItemModel(
      serviceId:   map['serviceId']   ?? '',
      hallId:      map['hallId']      ?? '',
      name:        map['name']        ?? '',
      description: map['description'] ?? '',
      price:       (map['price']      ?? 0).toDouble(),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory ServiceItemModel.fromDoc(DocumentSnapshot doc) =>
      ServiceItemModel.fromMap(doc.data() as Map<String, dynamic>);

  Map<String, dynamic> toMap() => {
    'serviceId':   serviceId,
    'hallId':      hallId,
    'name':        name,
    'description': description,
    'price':       price,
    'createdAt':   Timestamp.fromDate(createdAt),
  };

  ServiceItemModel copyWith({
    String? name, String? description, double? price,
  }) => ServiceItemModel(
    serviceId:   serviceId,
    hallId:      hallId,
    name:        name        ?? this.name,
    description: description ?? this.description,
    price:       price       ?? this.price,
    createdAt:   createdAt,
  );

  String get priceLabel => 'Rs. ${price.toStringAsFixed(0)}';
}