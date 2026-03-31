import 'package:cloud_firestore/cloud_firestore.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  MENU ITEM  →  halls/{hallId}/menu/{itemId}
// ══════════════════════════════════════════════════════════════════════════════
class MenuItemModel {
  final String itemId;
  final String hallId;
  final String name;
  final String description;
  final double price;
  final String priceUnit; // '/Plate' | '/Serving' | '/Head' | '/Pcs'
  final String imageUrl;
  final bool isAvailable;
  final DateTime createdAt;

  MenuItemModel({
    required this.itemId,
    required this.hallId,
    required this.name,
    this.description = '',
    required this.price,
    this.priceUnit = '/Serving',
    this.imageUrl = '',
    this.isAvailable = true,
    required this.createdAt,
  });

  factory MenuItemModel.fromMap(Map<String, dynamic> map) {
    return MenuItemModel(
      itemId:      map['itemId']      ?? '',
      hallId:      map['hallId']      ?? '',
      name:        map['name']        ?? '',
      description: map['description'] ?? '',
      price:       (map['price']      ?? 0).toDouble(),
      priceUnit:   map['priceUnit']   ?? '/Serving',
      imageUrl:    map['imageUrl']    ?? '',
      isAvailable: map['isAvailable'] ?? true,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory MenuItemModel.fromDoc(DocumentSnapshot doc) =>
      MenuItemModel.fromMap(doc.data() as Map<String, dynamic>);

  Map<String, dynamic> toMap() => {
    'itemId':      itemId,
    'hallId':      hallId,
    'name':        name,
    'description': description,
    'price':       price,
    'priceUnit':   priceUnit,
    'imageUrl':    imageUrl,
    'isAvailable': isAvailable,
    'createdAt':   Timestamp.fromDate(createdAt),
  };

  MenuItemModel copyWith({
    String? name, String? description, double? price,
    String? priceUnit, String? imageUrl, bool? isAvailable,
  }) => MenuItemModel(
    itemId:      itemId,
    hallId:      hallId,
    name:        name        ?? this.name,
    description: description ?? this.description,
    price:       price       ?? this.price,
    priceUnit:   priceUnit   ?? this.priceUnit,
    imageUrl:    imageUrl    ?? this.imageUrl,
    isAvailable: isAvailable ?? this.isAvailable,
    createdAt:   createdAt,
  );

  String get priceLabel => 'Rs. ${price.toStringAsFixed(0)}$priceUnit';
}