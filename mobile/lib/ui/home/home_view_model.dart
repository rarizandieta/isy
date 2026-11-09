import 'package:flutter/foundation.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/result.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/models/auth_user.dart';

/// ViewModel de la pantalla Home (superficie de pruebas del microservicio).
/// Expone el usuario y los tokens, y los comandos para ejercitar /auth/me,
/// /auth/refresh y /auth/logout. Observa al repositorio para reflejar cambios.
class HomeViewModel extends ChangeNotifier {
  HomeViewModel(this._repo) {
    _repo.addListener(_onRepoChanged);
  }

  final AuthRepository _repo;

  AuthUser? get user => _repo.currentUser;
  String? get accessToken => _repo.accessToken;
  String? get refreshToken => _repo.refreshToken;

  bool _busy = false;
  bool get busy => _busy;

  /// Prueba GET /auth/me. Devuelve el mensaje a mostrar.
  Future<String> reloadMe() {
    return _run(() async {
      final result = await _repo.reloadMe();
      return switch (result) {
        Ok() => '✓ /auth/me OK: ${_repo.currentUser?.email ?? ''}',
        Err(:final failure) => messageFor(failure),
      };
    });
  }

  /// Prueba POST /auth/refresh. Indica si el refresh token rotó.
  Future<String> refreshSession() {
    final before = _repo.refreshToken;
    return _run(() async {
      final result = await _repo.refreshSession();
      return switch (result) {
        Ok() => _repo.refreshToken != before
            ? '✓ Sesión renovada. El refresh token rotó.'
            : '✓ Sesión renovada.',
        Err(:final failure) => messageFor(failure),
      };
    });
  }

  Future<void> logout() => _repo.logout();

  Future<String> _run(Future<String> Function() action) async {
    _busy = true;
    notifyListeners();
    try {
      return await action();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void _onRepoChanged() => notifyListeners();

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    super.dispose();
  }
}
