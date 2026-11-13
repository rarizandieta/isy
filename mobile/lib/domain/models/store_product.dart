/// Unidad de venta del catálogo (`/catalogs/units`). Ids como STRING desde el
/// backend; se normalizan a int.
class ProductUnit {
  final int id;
  final String code;
  final String name;

  const ProductUnit({required this.id, required this.code, required this.name});

  factory ProductUnit.fromJson(Map<String, dynamic> json) {
    return ProductUnit(
      id: _toInt(json['id']),
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

/// Etiqueta del catálogo (`/catalogs/tags`).
class ProductTag {
  final int id;
  final String code;
  final String name;

  const ProductTag({required this.id, required this.code, required this.name});

  factory ProductTag.fromJson(Map<String, dynamic> json) {
    return ProductTag(
      id: _toInt(json['id']),
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

/// Producto de una Mini Tienda. El backend devuelve ids y precios como STRING;
/// este modelo los normaliza. `imageUrl` es una URL relativa (`/media/files/...`)
/// o null; para mostrarla usa [MediaImage] / `mediaAbsoluteUrl`.
class StoreProduct {
  final int id;
  final String name;
  final String? description;
  final double price;
  final double? offerPrice;
  final int unitId;
  final ProductUnit? unit;

  /// 'available' | 'sold_out' | 'made_to_order'
  final String stock;

  /// 'draft' | 'published' | 'archived'
  final String status;
  final bool isFeatured;
  final String? imageUrl;
  final int? sectionId;
  final List<ProductTag> tags;

  const StoreProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.offerPrice,
    required this.unitId,
    required this.unit,
    required this.stock,
    required this.status,
    required this.isFeatured,
    required this.imageUrl,
    required this.sectionId,
    required this.tags,
  });

  double get effectivePrice => offerPrice ?? price;
  bool get hasOffer => offerPrice != null && offerPrice! < price;
  bool get isPublished => status == 'published';

  factory StoreProduct.fromJson(Map<String, dynamic> json) {
    final unitJson = json['unit'];
    final tagsJson = json['tags'];
    return StoreProduct(
      id: _toInt(json['id']),
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      price: _toDouble(json['price']),
      offerPrice: json['offerPrice'] == null ? null : _toDouble(json['offerPrice']),
      unitId: _toInt(json['unitId']),
      unit: unitJson is Map<String, dynamic> ? ProductUnit.fromJson(unitJson) : null,
      stock: json['stock'] as String? ?? 'available',
      status: json['status'] as String? ?? 'draft',
      isFeatured: json['isFeatured'] as bool? ?? false,
      imageUrl: json['imageUrl'] as String?,
      sectionId: json['sectionId'] == null ? null : _toInt(json['sectionId']),
      tags: tagsJson is List
          ? tagsJson.whereType<Map<String, dynamic>>().map(ProductTag.fromJson).toList()
          : const [],
    );
  }
}

int _toInt(dynamic v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

/// Datos del formulario de producto para crear/actualizar.
class ProductDraft {
  final String name;
  final String? description;
  final double price;
  final double? offerPrice;
  final int unitId;
  final List<int> tagIds;
  final String stock;
  final String status;
  final bool isFeatured;

  // Imagen: setImage=false -> se omite (deja igual). setImage=true + valor ->
  // establece; setImage=true + null -> limpia.
  final String? imageBase64;
  final bool setImage;

  // Sección de vitrina: setSection=false -> se omite (deja igual).
  // setSection=true + valor -> asigna; setSection=true + null -> quita la sección.
  final int? sectionId;
  final bool setSection;

  const ProductDraft({
    required this.name,
    required this.price,
    required this.unitId,
    this.description,
    this.offerPrice,
    this.tagIds = const [],
    this.stock = 'available',
    this.status = 'published',
    this.isFeatured = false,
    this.imageBase64,
    this.setImage = false,
    this.sectionId,
    this.setSection = false,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'price': price,
      'unitId': unitId,
      'offerPrice': offerPrice, // valor o null (null = sin oferta / limpiar)
      'tagIds': tagIds,
      'stock': stock,
      'status': status,
      'isFeatured': isFeatured,
    };
    if (description != null && description!.trim().isNotEmpty) {
      map['description'] = description!.trim();
    }
    if (setImage) map['imageBase64'] = imageBase64;
    if (setSection) map['sectionId'] = sectionId;
    return map;
  }
}
