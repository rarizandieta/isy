import 'package:flutter/foundation.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/result.dart';
import '../../data/repositories/store_repository.dart';
import '../../domain/models/store_product.dart';
import '../../domain/models/store_section.dart';

/// ViewModel del editor de producto. Carga catálogos (unidades + etiquetas) y
/// las secciones de la tienda, y ejecuta crear / actualizar / eliminar.
class ProductEditorViewModel extends ChangeNotifier {
  ProductEditorViewModel(this._store, this._storeId) {
    _loadCatalog();
  }

  final StoreRepository _store;
  final int _storeId;

  bool _loadingCatalog = true;
  bool get loadingCatalog => _loadingCatalog;

  List<ProductUnit> _units = const [];
  List<ProductUnit> get units => _units;

  List<ProductTag> _tags = const [];
  List<ProductTag> get tags => _tags;

  List<StoreSection> _sections = const [];
  List<StoreSection> get sections => _sections;

  String? _catalogError;
  String? get catalogError => _catalogError;

  bool _submitting = false;
  bool get submitting => _submitting;

  String? _error;
  String? get error => _error;

  Future<void> _loadCatalog() async {
    _loadingCatalog = true;
    _catalogError = null;
    notifyListeners();

    final unitsResult = await _store.listUnits();
    final tagsResult = await _store.listTags();
    final sectionsResult = await _store.listSections(_storeId);

    switch (unitsResult) {
      case Ok(:final value):
        _units = value;
      case Err(:final failure):
        _catalogError = messageFor(failure);
    }
    if (_catalogError == null) {
      switch (tagsResult) {
        case Ok(:final value):
          _tags = value;
        case Err(:final failure):
          _catalogError = messageFor(failure);
      }
    }
    // Las secciones son opcionales: si fallan, no bloqueamos el editor.
    if (sectionsResult case Ok(:final value)) {
      _sections = value;
    }
    _loadingCatalog = false;
    notifyListeners();
  }

  Future<void> retry() => _loadCatalog();

  Future<bool> save({int? productId, required ProductDraft draft}) async {
    _submitting = true;
    _error = null;
    notifyListeners();

    final result = productId == null
        ? await _store.createProduct(_storeId, draft)
        : await _store.updateProduct(_storeId, productId, draft);
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

  Future<bool> delete(int productId) async {
    _submitting = true;
    _error = null;
    notifyListeners();

    final result = await _store.deleteProduct(_storeId, productId);
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
