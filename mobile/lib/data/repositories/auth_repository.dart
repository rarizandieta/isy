import 'package:flutter/foundation.dart';

import '../../core/result.dart';
import '../../domain/models/auth_user.dart';

/// Fuente de verdad de la autenticación (capa de datos). Mantiene la sesión
/// (usuario + tokens) y la respalda en almacenamiento seguro. Es un
/// [ChangeNotifier]: notifica cuando cambia la sesión, para que los ViewModels
/// que la observan (p. ej. el de sesión de la app) reaccionen.
///
/// Las operaciones que pueden fallar con un error visible devuelven [Result].
abstract class AuthRepository extends ChangeNotifier {
  /// Usuario autenticado actual, o null si no hay sesión.
  AuthUser? get currentUser;

  String? get accessToken;
  String? get refreshToken;

  /// ¿Terminó ya el intento de restaurar la sesión al arrancar?
  bool get isInitialized;

  /// Restaura la sesión guardada (valida con /me, refresca si hace falta).
  Future<void> restoreSession();

  /// Registro manual + inicio de sesión automático si tiene éxito.
  Future<Result<AuthUser>> register({
    required String fullName,
    required String email,
    required String password,
  });

  Future<Result<AuthUser>> login({
    required String email,
    required String password,
  });

  /// Rota el refresh token y renueva el access.
  Future<Result<void>> refreshSession();

  /// Vuelve a pedir /auth/me con el access actual.
  Future<Result<AuthUser>> reloadMe();

  /// Cierra sesión: revoca en el backend y limpia el almacenamiento local.
  Future<void> logout();
}
