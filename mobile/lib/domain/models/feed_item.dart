import 'store_product.dart';

/// Referencia ligera de la tienda dueña de un producto del feed, para pintar el
/// encabezado de la tarjeta. El backend la envía en `store` dentro de cada ítem.
class FeedStoreRef {
  final int id;
  final String name;
  final String slug;

  /// URL (relativa, `/media/files/...`) del logo, o null.
  final String? logoUrl;

  /// Color de acento `#RRGGBB`.
  final String accentColor;

  const FeedStoreRef({
    required this.id,
    required this.name,
    required this.slug,
    required this.logoUrl,
    required this.accentColor,
  });

  factory FeedStoreRef.fromJson(Map<String, dynamic> json) {
    return FeedStoreRef(
      id: _asInt(json['id']),
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      logoUrl: json['logoUrl'] as String?,
      accentColor: json['accentColor'] as String? ?? '#EF6C00',
    );
  }

  static int _asInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

/// Un ítem del feed del marketplace: un producto publicado más la tienda que lo
/// vende. Los campos del producto llegan en el nivel superior del JSON (se
/// reutiliza [StoreProduct.fromJson]); la tienda viene anidada en `store`.
class FeedItem {
  final StoreProduct product;
  final FeedStoreRef store;

  const FeedItem({required this.product, required this.store});

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    final storeJson = json['store'];
    return FeedItem(
      product: StoreProduct.fromJson(json),
      store: storeJson is Map<String, dynamic>
          ? FeedStoreRef.fromJson(storeJson)
          : const FeedStoreRef(
              id: 0,
              name: '',
              slug: '',
              logoUrl: null,
              accentColor: '#EF6C00',
            ),
    );
  }
}

/// Página del feed (paginación por `offset`). `total` es el número total de
/// productos publicados disponibles, para saber si hay más que cargar.
class FeedPage {
  final List<FeedItem> items;
  final int total;
  final int limit;
  final int offset;

  const FeedPage({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory FeedPage.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    return FeedPage(
      items: itemsJson is List
          ? itemsJson.whereType<Map<String, dynamic>>().map(FeedItem.fromJson).toList()
          : const [],
      total: _asInt(json['total']),
      limit: _asInt(json['limit']),
      offset: _asInt(json['offset']),
    );
  }

  static int _asInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
