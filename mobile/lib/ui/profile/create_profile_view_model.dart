import 'package:flutter/foundation.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/result.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/models/profile.dart';

/// ViewModel para crear un perfil adicional (vendedor / servicios). Al crearlo,
/// el backend lo deja ACTIVO y emite un nuevo access token (lo adopta el
/// [AuthRepository]).
class CreateProfileViewModel extends ChangeNotifier {
  CreateProfileViewModel(this._auth);

  final AuthRepository _auth;

  bool _submitting = false;
  bool get submitting => _submitting;

  String? _error;
  String? get error => _error;

  Future<bool> submit({required ProfileType type, required String displayName}) async {
    _submitting = true;
    _error = null;
    notifyListeners();

    final result = await _auth.createProfile(type: type, displayName: displayName);
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
