import 'package:flutter/foundation.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/result.dart';
import '../../../data/repositories/auth_repository.dart';

/// ViewModel de la pantalla de inicio de sesión. Mantiene el estado del envío
/// (enviando / error) y delega la operación en el repositorio.
class LoginViewModel extends ChangeNotifier {
  LoginViewModel(this._repo);

  final AuthRepository _repo;

  bool _submitting = false;
  bool get submitting => _submitting;

  String? _error;
  String? get error => _error;

  /// Ejecuta el login. Devuelve true si tuvo éxito (la navegación la hace la
  /// View); en caso de error, [error] contiene el mensaje a mostrar.
  Future<bool> submit({required String email, required String password}) async {
    _submitting = true;
    _error = null;
    notifyListeners();

    final result = await _repo.login(email: email, password: password);
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
