import 'package:flutter/foundation.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/result.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/models/mini_store.dart';
import '../../domain/models/profile.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/store_repository.dart';

/// ViewModel de la pantalla Cuenta. Expone la sesión (usuario + perfiles +
/// perfil activo) desde [AuthRepository] y, cuando el perfil activo es vendedor,
/// resuelve si ya tiene Mini Tienda (para decidir "Crear" vs "Configurar").
class AccountViewModel extends ChangeNotifier {
  AccountViewModel(this._auth, this._store) {
    _auth.addListener(_onAuthChanged);
    _init();
  }

  final AuthRepository _auth;
  final StoreRepository _store;

  bool _loading = true;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  bool _storeLoading = false;
  bool get storeLoading => _storeLoading;

  MiniStore? _myStore;
  MiniStore? get myStore => _myStore;

  // --- Passthrough de la sesión ---
  AuthUser? get user => _auth.currentUser;
  List<Profile> get profiles => _auth.profiles;
  Profile? get activeProfile => _auth.activeProfile;
  bool get isSellerActive => _auth.activeProfile?.type == ProfileType.seller;

  Future<void> _init() async {
    _loading = true;
    _error = null;
    notifyListeners();
    final result = await _auth.loadProfiles();
    if (result case Err(:final failure)) {
      _error = messageFor(failure);
    }
    _loading = false;
    notifyListeners();
    await _refreshStore();
  }

  /// Recarga perfiles + estado de la tienda (al volver de otra pantalla).
  Future<void> refresh() async {
    await _auth.loadProfiles();
    await _refreshStore();
  }

  /// Cambia el perfil activo; devuelve un mensaje de error o null si tuvo éxito.
  Future<String?> switchProfile(int profileId) async {
    final result = await _auth.switchProfile(profileId);
    switch (result) {
      case Ok():
        await _refreshStore();
        return null;
      case Err(:final failure):
        return messageFor(failure);
    }
  }

  Future<void> logout() => _auth.logout();

  /// Consulta la Mini Tienda del perfil activo solo si es vendedor.
  Future<void> _refreshStore() async {
    final active = _auth.activeProfile;
    if (active == null || active.type != ProfileType.seller) {
      _myStore = null;
      notifyListeners();
      return;
    }
    _storeLoading = true;
    notifyListeners();
    final result = await _store.getMyStore();
    _storeLoading = false;
    switch (result) {
      case Ok(:final value):
        _myStore = value;
      case Err():
        _myStore = null;
    }
    notifyListeners();
  }

  void _onAuthChanged() => notifyListeners();

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
