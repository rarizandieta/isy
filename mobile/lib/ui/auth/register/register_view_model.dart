import 'package:flutter/foundation.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/result.dart';
import '../../../data/repositories/auth_repository.dart';

/// ViewModel de la pantalla de registro. El registro hace inicio de sesión
/// automático si tiene éxito (lógica en el repositorio).
class RegisterViewModel extends ChangeNotifier {
  RegisterViewModel(this._repo);

  final AuthRepository _repo;

  bool _submitting = false;
  bool get submitting => _submitting;

  String? _error;
  String? get error => _error;

  Future<bool> submit({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _submitting = true;
    _error = null;
    notifyListeners();

    final result = await _repo.register(
      fullName: fullName,
      email: email,
      password: password,
    );
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
