import 'package:flutter/foundation.dart';

import '../../core/result.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/models/profile.dart';

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

  /// Perfiles del usuario (vacío hasta que se cargan con [loadProfiles]).
  List<Profile> get profiles;

  /// Id del perfil activo (el que viaja en el token), o null.
  int? get activeProfileId;

  /// Perfil activo resuelto, o null si aún no hay perfiles cargados.
  Profile? get activeProfile;

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

  /// Carga/actualiza la lista de perfiles del usuario y el perfil activo.
  Future<Result<void>> loadProfiles();

  /// Crea un perfil (vendedor/servicios), lo activa y adopta el nuevo access
  /// token que emite el backend.
  Future<Result<void>> createProfile({
    required ProfileType type,
    required String displayName,
  });

  /// Cambia el perfil activo y adopta el nuevo access token.
  Future<Result<void>> switchProfile(int profileId);
}
