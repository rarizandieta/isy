import 'package:flutter/foundation.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/result.dart';
import '../../data/repositories/store_repository.dart';
import '../../domain/models/coverage_zone.dart';
import '../../domain/models/mini_store.dart';
import '../../domain/models/store_category.dart';

/// ViewModel del editor de Mini Tienda. Carga el catálogo de giros y ejecuta la
/// creación (POST) o actualización (PATCH) de la tienda del perfil activo.
class StoreEditorViewModel extends ChangeNotifier {
  StoreEditorViewModel(this._store) {
    _loadCategories();
  }

  final StoreRepository _store;

  bool _loadingCategories = true;
  bool get loadingCategories => _loadingCategories;

  List<StoreCategory> _categories = const [];
  List<StoreCategory> get categories => _categories;

  List<CoverageZone> _coverageZones = const [];
  List<CoverageZone> get coverageZones => _coverageZones;

  String? _categoriesError;
  String? get categoriesError => _categoriesError;

  bool _submitting = false;
  bool get submitting => _submitting;

  String? _error;
  String? get error => _error;

  Future<void> _loadCategories() async {
    _loadingCategories = true;
    notifyListeners();
    final result = await _store.listCategories();
    switch (result) {
      case Ok(:final value):
        _categories = value;
        _categoriesError = null;
      case Err(:final failure):
        _categoriesError = messageFor(failure);
    }
    // Zonas de cobertura (catálogo fijo). Best-effort: si falla, el selector de
    // cobertura queda vacío pero no bloquea el formulario.
    final zonesResult = await _store.listCoverageZones();
    if (zonesResult case Ok(:final value)) {
      _coverageZones = value;
    }
    _loadingCategories = false;
    notifyListeners();
  }

  Future<void> retryCategories() => _loadCategories();

  /// Crea (storeId == null) o actualiza la Mini Tienda. Devuelve true si tuvo
  /// éxito; si no, [error] contiene el mensaje.
  Future<bool> save({int? storeId, required StoreDraft draft}) async {
    _submitting = true;
    _error = null;
    notifyListeners();

    final result = storeId == null
        ? await _store.createStore(draft)
        : await _store.updateStore(storeId, draft);
    _submitting = false;

    switch (result) {
      case Ok():
        notifyListeners();
        return true;
      case Err(:final failure):
        _error = messageFor(failure);
        notifyListeners();
        return false;
    }
  }
}
