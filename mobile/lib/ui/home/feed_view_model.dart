import 'package:flutter/foundation.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/result.dart';
import '../../data/repositories/store_repository.dart';
import '../../domain/models/feed_item.dart';

/// ViewModel del feed de Inicio. Carga la primera página al crearse y soporta
/// "pull to refresh" y paginación incremental (scroll infinito) por offset.
class FeedViewModel extends ChangeNotifier {
  FeedViewModel(this._store) {
    load();
  }

  final StoreRepository _store;
  static const int _pageSize = 20;

  final List<FeedItem> _items = [];
  List<FeedItem> get items => List.unmodifiable(_items);

  bool _loading = false;
  bool get loading => _loading;

  bool _loadingMore = false;
  bool get loadingMore => _loadingMore;

  String? _error;
  String? get error => _error;

  int _total = 0;

  /// ¿Quedan más productos por cargar?
  bool get hasMore => _items.length < _total;

  /// Lista cargada, sin error y vacía (para pintar el estado vacío).
  bool get isEmpty => !_loading && _error == null && _items.isEmpty;

  /// Primera carga / recarga completa (reemplaza la lista).
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    final result = await _store.listFeed(limit: _pageSize, offset: 0);
    switch (result) {
      case Ok(:final value):
        _items
          ..clear()
          ..addAll(value.items);
        _total = value.total;
      case Err(:final failure):
        _error = messageFor(failure);
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() => load();

  /// Carga la siguiente página y la añade al final. Silenciosa ante error (el
  /// usuario puede reintentar volviendo a desplazarse).
  Future<void> loadMore() async {
    if (_loadingMore || _loading || !hasMore) return;
    _loadingMore = true;
    notifyListeners();

    final result = await _store.listFeed(limit: _pageSize, offset: _items.length);
    switch (result) {
      case Ok(:final value):
        _items.addAll(value.items);
        _total = value.total;
      case Err():
        break;
    }
    _loadingMore = false;
    notifyListeners();
  }
}
