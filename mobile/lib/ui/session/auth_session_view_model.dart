import 'package:flutter/foundation.dart';

import '../../data/repositories/auth_repository.dart';
import '../../domain/models/auth_user.dart';

/// Estado de sesión a nivel de aplicación.
enum AuthStatus {
  /// Arrancando: aún no sabemos si hay sesión guardada.
  unknown,

  /// Sin sesión: mostrar bienvenida/login/registro.
  unauthenticated,

  /// Con sesión válida: mostrar la app.
  authenticated,
}

/// ViewModel de sesión de la app. Deriva el estado global a partir del
/// repositorio (fuente de verdad) y lo expone al AuthGate. Observa al
/// repositorio para reaccionar a login/logout/restauración.
class AuthSessionViewModel extends ChangeNotifier {
  AuthSessionViewModel(this._repo) {
    _repo.addListener(_onRepoChanged);
    // Dispara la restauración de sesión; el repo notifica al terminar.
    _repo.restoreSession();
  }

  final AuthRepository _repo;

  AuthStatus get status {
    if (!_repo.isInitialized) return AuthStatus.unknown;
    return _repo.currentUser != null
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
  }

  AuthUser? get user => _repo.currentUser;

  Future<void> logout() => _repo.logout();

  void _onRepoChanged() => notifyListeners();

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    super.dispose();
  }
}
