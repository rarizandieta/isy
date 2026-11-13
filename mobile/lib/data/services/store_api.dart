import 'dart:convert';

import '../../domain/models/coverage_zone.dart';
import '../../domain/models/feed_item.dart';
import '../../domain/models/mini_store.dart';
import '../../domain/models/store_category.dart';
import '../../domain/models/store_product.dart';
import '../../domain/models/store_section.dart';
import '../api_exception.dart';
import 'json_api.dart';

/// Cliente de la API de ministores (vía gateway). El gateway valida el token e
/// inyecta `x-profile-id` (perfil activo) y `x-user-id`; ministores resuelve el
/// `sellerProfileId` a partir de ese header, por lo que NO se envía en el body.
class StoreApi extends JsonApi {
  StoreApi({super.client, super.baseUrl});

  /// GET /catalogs/categories -> catálogo de giros.
  Future<List<StoreCategory>> listCategories(String accessToken) async {
    final decoded = await sendRaw(
      () => httpClient.get(uri('/catalogs/categories'), headers: bearer(accessToken)),
    );
    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(StoreCategory.fromJson)
          .toList();
    }
    return const [];
  }

  /// GET /feed -> feed público del marketplace (productos publicados de tiendas
  /// activas), paginado por `offset`. Es una ruta pública en el gateway; se
  /// envía el token igualmente (inofensivo) para reutilizar el patrón común.
  Future<FeedPage> listFeed(String accessToken, {int limit = 20, int offset = 0}) async {
    final decoded = await sendRaw(
      () => httpClient.get(
        uri('/feed?limit=$limit&offset=$offset'),
        headers: bearer(accessToken),
      ),
    );
    if (decoded is Map<String, dynamic>) return FeedPage.fromJson(decoded);
    return const FeedPage(items: [], total: 0, limit: 0, offset: 0);
  }

  /// GET /stores/mine -> la Mini Tienda del perfil activo, o null si no tiene
  /// (ministores responde 404 cuando no existe).
  Future<MiniStore?> getMyStore(String accessToken) async {
    try {
      final decoded = await sendRaw(
        () => httpClient.get(uri('/stores/mine'), headers: bearer(accessToken)),
      );
      if (decoded is List) {
        return decoded.isEmpty ? null : MiniStore.fromJson(decoded.first as Map<String, dynamic>);
      }
      if (decoded is Map<String, dynamic> && decoded.isNotEmpty) {
        return MiniStore.fromJson(decoded);
      }
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null; // no hay tienda para este perfil
      rethrow;
    }
  }

  /// POST /stores -> crea la Mini Tienda del perfil activo.
  Future<MiniStore> createStore(String accessToken, StoreDraft draft) async {
    final json = await sendJson(
      () => httpClient.post(
        uri('/stores'),
        headers: bearerJson(accessToken),
        body: jsonEncode(draft.toJson()),
      ),
    );
    return MiniStore.fromJson(json);
  }

  /// PATCH /stores/:id -> actualiza la Mini Tienda.
  Future<MiniStore> updateStore(String accessToken, int storeId, StoreDraft draft) async {
    final json = await sendJson(
      () => httpClient.patch(
        uri('/stores/$storeId'),
        headers: bearerJson(accessToken),
        body: jsonEncode(draft.toJson()),
      ),
    );
    return MiniStore.fromJson(json);
  }

  // --- Productos ---

  /// GET /stores/:id/products -> productos de la tienda (con unidad + imagen).
  Future<List<StoreProduct>> listProducts(String accessToken, int storeId) async {
    final decoded = await sendRaw(
      () => httpClient.get(uri('/stores/$storeId/products'), headers: bearer(accessToken)),
    );
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().map(StoreProduct.fromJson).toList();
    }
    return const [];
  }

  Future<StoreProduct> createProduct(String accessToken, int storeId, ProductDraft draft) async {
    final json = await sendJson(
      () => httpClient.post(
        uri('/stores/$storeId/products'),
        headers: bearerJson(accessToken),
        body: jsonEncode(draft.toJson()),
      ),
    );
    return StoreProduct.fromJson(json);
  }

  Future<StoreProduct> updateProduct(
    String accessToken,
    int storeId,
    int productId,
    ProductDraft draft,
  ) async {
    final json = await sendJson(
      () => httpClient.patch(
        uri('/stores/$storeId/products/$productId'),
        headers: bearerJson(accessToken),
        body: jsonEncode(draft.toJson()),
      ),
    );
    return StoreProduct.fromJson(json);
  }

  Future<void> deleteProduct(String accessToken, int storeId, int productId) async {
    await sendRaw(
      () => httpClient.delete(
        uri('/stores/$storeId/products/$productId'),
        headers: bearer(accessToken),
      ),
      expectBody: false,
    );
  }

  // --- Secciones de vitrina ---

  /// GET /stores/:id/sections -> secciones de la tienda (ordenadas por posición).
  Future<List<StoreSection>> listSections(String accessToken, int storeId) async {
    final decoded = await sendRaw(
      () => httpClient.get(uri('/stores/$storeId/sections'), headers: bearer(accessToken)),
    );
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().map(StoreSection.fromJson).toList();
    }
    return const [];
  }

  Future<StoreSection> createSection(
    String accessToken,
    int storeId, {
    required String name,
    required int position,
    String? description,
  }) async {
    final body = <String, dynamic>{'name': name, 'position': position};
    if (description != null && description.trim().isNotEmpty) {
      body['description'] = description.trim();
    }
    final json = await sendJson(
      () => httpClient.post(
        uri('/stores/$storeId/sections'),
        headers: bearerJson(accessToken),
        body: jsonEncode(body),
      ),
    );
    return StoreSection.fromJson(json);
  }

  Future<StoreSection> updateSection(
    String accessToken,
    int storeId,
    int sectionId, {
    String? name,
    int? position,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (position != null) body['position'] = position;
    if (isActive != null) body['isActive'] = isActive;
    final json = await sendJson(
      () => httpClient.patch(
        uri('/stores/$storeId/sections/$sectionId'),
        headers: bearerJson(accessToken),
        body: jsonEncode(body),
      ),
    );
    return StoreSection.fromJson(json);
  }

  Future<void> deleteSection(String accessToken, int storeId, int sectionId) async {
    await sendRaw(
      () => httpClient.delete(
        uri('/stores/$storeId/sections/$sectionId'),
        headers: bearer(accessToken),
      ),
      expectBody: false,
    );
  }

  /// PATCH /stores/:id/sections/reorder -> reordena TODAS las secciones según
  /// `orderedIds` (quedan con posición 1..N). Devuelve la lista ya ordenada.
  Future<List<StoreSection>> reorderSections(
    String accessToken,
    int storeId,
    List<int> orderedIds,
  ) async {
    final decoded = await sendRaw(
      () => httpClient.patch(
        uri('/stores/$storeId/sections/reorder'),
        headers: bearerJson(accessToken),
        body: jsonEncode({'sectionIds': orderedIds}),
      ),
    );
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().map(StoreSection.fromJson).toList();
    }
    return const [];
  }

  // --- Catálogos ---

  Future<List<ProductUnit>> listUnits(String accessToken) async {
    final decoded = await sendRaw(
      () => httpClient.get(uri('/catalogs/units'), headers: bearer(accessToken)),
    );
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().map(ProductUnit.fromJson).toList();
    }
    return const [];
  }

  Future<List<ProductTag>> listTags(String accessToken) async {
    final decoded = await sendRaw(
      () => httpClient.get(uri('/catalogs/tags'), headers: bearer(accessToken)),
    );
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().map(ProductTag.fromJson).toList();
    }
    return const [];
  }

  /// GET /catalogs/coverage-zones -> catálogo de zonas de cobertura.
  Future<List<CoverageZone>> listCoverageZones(String accessToken) async {
    final decoded = await sendRaw(
      () => httpClient.get(uri('/catalogs/coverage-zones'), headers: bearer(accessToken)),
    );
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().map(CoverageZone.fromJson).toList();
    }
    return const [];
  }
}
