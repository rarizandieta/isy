import 'package:flutter/material.dart';

/// Estado de publicación de un producto: borrador (solo lo ve el dueño) o
/// publicado (visible en la vitrina y en el Feed).
enum ProductStatus { draft, published }

extension ProductStatusX on ProductStatus {
  String get label => switch (this) {
        ProductStatus.draft => 'Borrador',
        ProductStatus.published => 'Publicado',
      };
}

/// Disponibilidad de un producto (clave para perecederos y comida del día).
enum StockStatus { available, soldOut, madeToOrder }

extension StockStatusX on StockStatus {
  String get label => switch (this) {
        StockStatus.available => 'Disponible',
        StockStatus.soldOut => 'Agotado',
        StockStatus.madeToOrder => 'Por encargo',
      };

  Color get color => switch (this) {
        StockStatus.available => const Color(0xFF2E7D32),
        StockStatus.soldOut => const Color(0xFF9E9E9E),
        StockStatus.madeToOrder => const Color(0xFFEF6C00),
      };
}

/// Unidades de venta comunes. La unidad es el "comodín" que adapta la vitrina
/// a cualquier giro (pieza, kg, docena, manojo, porción…).
const List<String> kSaleUnits = [
  'pieza',
  'docena',
  'media docena',
  'kg',
  'libra',
  'manojo',
  'porción',
  'litro',
  'bolsa',
  'caja',
];

/// Etiquetas opcionales para resaltar atributos del producto.
const List<String> kProductTags = [
  'Nuevo',
  'Popular',
  'Oferta',
  'Picante',
  'Vegano',
  'Sin gluten',
  'Hecho a mano',
  'Orgánico',
];

const Object _sentinel = Object();

/// Producto de una Mini Tienda.
class StoreProduct {
  final String id;
  final String storeId;
  final String? sectionId;
  final String name;
  final String description;
  final double price;
  final double? offerPrice;
  final String unit;
  final int imageSeed;
  final StockStatus stock;
  final bool isFeatured;
  final List<String> tags;
  final ProductStatus status;

  const StoreProduct({
    required this.id,
    required this.storeId,
    required this.name,
    required this.price,
    required this.unit,
    required this.imageSeed,
    this.sectionId,
    this.description = '',
    this.offerPrice,
    this.stock = StockStatus.available,
    this.isFeatured = false,
    this.tags = const [],
    this.status = ProductStatus.published,
  });

  double get effectivePrice => offerPrice ?? price;
  bool get hasOffer => offerPrice != null && offerPrice! < price;

  StoreProduct copyWith({
    Object? sectionId = _sentinel,
    String? name,
    String? description,
    double? price,
    Object? offerPrice = _sentinel,
    String? unit,
    int? imageSeed,
    StockStatus? stock,
    bool? isFeatured,
    List<String>? tags,
    ProductStatus? status,
  }) {
    return StoreProduct(
      id: id,
      storeId: storeId,
      sectionId:
          identical(sectionId, _sentinel) ? this.sectionId : sectionId as String?,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      offerPrice: identical(offerPrice, _sentinel)
          ? this.offerPrice
          : offerPrice as double?,
      unit: unit ?? this.unit,
      imageSeed: imageSeed ?? this.imageSeed,
      stock: stock ?? this.stock,
      isFeatured: isFeatured ?? this.isFeatured,
      tags: tags ?? this.tags,
      status: status ?? this.status,
    );
  }
}
