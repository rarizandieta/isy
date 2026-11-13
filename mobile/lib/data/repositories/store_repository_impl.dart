import '../../core/result.dart';
import '../../domain/failure.dart';
import '../../domain/models/coverage_zone.dart';
import '../../domain/models/feed_item.dart';
import '../../domain/models/mini_store.dart';
import '../../domain/models/store_category.dart';
import '../../domain/models/store_product.dart';
import '../../domain/models/store_section.dart';
import '../failure_mapper.dart';
import '../services/store_api.dart';
import 'auth_repository.dart';
import 'store_repository.dart';

/// Implementación del repositorio de Mini Tienda. Toma el access token del
/// [AuthRepository] (fuente de verdad de la sesión) y delega en [StoreApi].
class StoreRepositoryImpl implements StoreRepository {
  StoreRepositoryImpl(this._api, this._auth);

  final StoreApi _api;
  final AuthRepository _auth;

  @override
  Future<Result<FeedPage>> listFeed({int limit = 20, int offset = 0}) =>
      _guard((token) => _api.listFeed(token, limit: limit, offset: offset));

  @override
  Future<Result<MiniStore?>> getMyStore() => _guard((token) => _api.getMyStore(token));

  @override
  Future<Result<MiniStore>> createStore(StoreDraft draft) =>
      _guard((token) => _api.createStore(token, draft));

  @override
  Future<Result<MiniStore>> updateStore(int storeId, StoreDraft draft) =>
      _guard((token) => _api.updateStore(token, storeId, draft));

  @override
  Future<Result<List<StoreCategory>>> listCategories() =>
      _guard((token) => _api.listCategories(token));

  @override
  Future<Result<List<CoverageZone>>> listCoverageZones() =>
      _guard((token) => _api.listCoverageZones(token));

  @override
  Future<Result<List<StoreProduct>>> listProducts(int storeId) =>
      _guard((token) => _api.listProducts(token, storeId));

  @override
  Future<Result<StoreProduct>> createProduct(int storeId, ProductDraft draft) =>
      _guard((token) => _api.createProduct(token, storeId, draft));

  @override
  Future<Result<StoreProduct>> updateProduct(int storeId, int productId, ProductDraft draft) =>
      _guard((token) => _api.updateProduct(token, storeId, productId, draft));

  @override
  Future<Result<void>> deleteProduct(int storeId, int productId) =>
      _guard((token) => _api.deleteProduct(token, storeId, productId));

  @override
  Future<Result<List<ProductUnit>>> listUnits() => _guard((token) => _api.listUnits(token));

  @override
  Future<Result<List<ProductTag>>> listTags() => _guard((token) => _api.listTags(token));

  @override
  Future<Result<List<StoreSection>>> listSections(int storeId) =>
      _guard((token) => _api.listSections(token, storeId));

  @override
  Future<Result<StoreSection>> createSection(
    int storeId, {
    required String name,
    required int position,
    String? description,
  }) =>
      _guard((token) => _api.createSection(
            token,
            storeId,
            name: name,
            position: position,
            description: description,
          ));

  @override
  Future<Result<StoreSection>> updateSection(
    int storeId,
    int sectionId, {
    String? name,
    int? position,
    bool? isActive,
  }) =>
      _guard((token) => _api.updateSection(
            token,
            storeId,
            sectionId,
            name: name,
            position: position,
            isActive: isActive,
          ));

  @override
  Future<Result<void>> deleteSection(int storeId, int sectionId) =>
      _guard((token) => _api.deleteSection(token, storeId, sectionId));

  @override
  Future<Result<List<StoreSection>>> reorderSections(int storeId, List<int> orderedIds) =>
      _guard((token) => _api.reorderSections(token, storeId, orderedIds));

  /// Ejecuta [action] con el access token actual, mapeando fallos a [Failure].
  Future<Result<T>> _guard<T>(Future<T> Function(String token) action) async {
    final token = _auth.accessToken;
    if (token == null) {
      return Err<T>(const Failure(FailureKind.unknown));
    }
    try {
      return Ok<T>(await action(token));
    } catch (e) {
      return Err<T>(failureFromError(e));
    }
  }
}
