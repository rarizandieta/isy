import '../../core/result.dart';
import '../../domain/models/coverage_zone.dart';
import '../../domain/models/feed_item.dart';
import '../../domain/models/mini_store.dart';
import '../../domain/models/store_category.dart';
import '../../domain/models/store_product.dart';
import '../../domain/models/store_section.dart';

/// Acceso a la Mini Tienda del perfil activo (vía ministores a través del
/// gateway). El `sellerProfileId` lo resuelve el gateway desde el token, por lo
/// que estas operaciones actúan siempre sobre el PERFIL ACTIVO.
abstract class StoreRepository {
  /// Feed público del marketplace (productos publicados de tiendas activas).
  Future<Result<FeedPage>> listFeed({int limit, int offset});

  /// Mini Tienda del perfil activo, o null si aún no tiene.
  Future<Result<MiniStore?>> getMyStore();

  Future<Result<MiniStore>> createStore(StoreDraft draft);

  Future<Result<MiniStore>> updateStore(int storeId, StoreDraft draft);

  /// Catálogo de giros para el formulario.
  Future<Result<List<StoreCategory>>> listCategories();

  /// Catálogo de zonas de cobertura (ubicaciones fijas).
  Future<Result<List<CoverageZone>>> listCoverageZones();

  // --- Productos ---
  Future<Result<List<StoreProduct>>> listProducts(int storeId);
  Future<Result<StoreProduct>> createProduct(int storeId, ProductDraft draft);
  Future<Result<StoreProduct>> updateProduct(int storeId, int productId, ProductDraft draft);
  Future<Result<void>> deleteProduct(int storeId, int productId);

  // --- Catálogos de producto ---
  Future<Result<List<ProductUnit>>> listUnits();
  Future<Result<List<ProductTag>>> listTags();

  // --- Secciones de vitrina ---
  Future<Result<List<StoreSection>>> listSections(int storeId);
  Future<Result<StoreSection>> createSection(
    int storeId, {
    required String name,
    required int position,
    String? description,
  });
  Future<Result<StoreSection>> updateSection(
    int storeId,
    int sectionId, {
    String? name,
    int? position,
    bool? isActive,
  });
  Future<Result<void>> deleteSection(int storeId, int sectionId);

  /// Reordena todas las secciones de la tienda según `orderedIds`.
  Future<Result<List<StoreSection>>> reorderSections(int storeId, List<int> orderedIds);
}
