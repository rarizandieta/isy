import '../../core/result.dart';
import '../../domain/failure.dart';
import '../../domain/models/auth_session.dart';
import '../../domain/models/auth_user.dart';
import '../api_exception.dart';
import '../services/auth_api.dart';
import '../services/token_storage.dart';
import 'auth_repository.dart';

/// Implementación del repositorio de autenticación. Orquesta el servicio HTTP
/// (AuthApi) y el almacenamiento seguro (TokenStorage); traduce las excepciones
/// de transporte a [Failure] semánticos.
class AuthRepositoryImpl extends AuthRepository {
  AuthRepositoryImpl(this._api, this._storage);

  final AuthApi _api;
  final TokenStorage _storage;

  AuthUser? _user;
  String? _accessToken;
  String? _refreshToken;
  bool _initialized = false;

  @override
  AuthUser? get currentUser => _user;

  @override
  String? get accessToken => _accessToken;

  @override
  String? get refreshToken => _refreshToken;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> restoreSession() async {
    final access = await _storage.readAccessToken();
    final refresh = await _storage.readRefreshToken();

    if (access == null || refresh == null) {
      _initialized = true;
      notifyListeners();
      return;
    }

    _accessToken = access;
    _refreshToken = refresh;

    try {
      _user = await _api.me(access);
    } on ApiException {
      // Access inválido/caducado: intentar refrescar.
      try {
        await _applySession(await _api.refresh(refresh));
      } catch (_) {
        await _clearSession(notify: false);
      }
    } on NetworkException {
      // Sin red: no damos la sesión por válida (se pedirá iniciar de nuevo).
      _user = null;
    }

    _initialized = true;
    notifyListeners();
  }

  @override
  Future<Result<AuthUser>> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      await _api.register(fullName: fullName, email: email, password: password);
      await _applySession(await _api.login(email: email, password: password));
      return Ok(_user!);
    } catch (e) {
      return Err(_failureFrom(e));
    }
  }

  @override
  Future<Result<AuthUser>> login({
    required String email,
    required String password,
  }) async {
    try {
      await _applySession(await _api.login(email: email, password: password));
      return Ok(_user!);
    } catch (e) {
      return Err(_failureFrom(e));
    }
  }

  @override
  Future<Result<void>> refreshSession() async {
    final refresh = _refreshToken;
    if (refresh == null) return const Err(Failure(FailureKind.unknown));
    try {
      await _applySession(await _api.refresh(refresh));
      return const Ok(null);
    } catch (e) {
      return Err(_failureFrom(e));
    }
  }

  @override
  Future<Result<AuthUser>> reloadMe() async {
    final access = _accessToken;
    if (access == null) return const Err(Failure(FailureKind.unknown));
    try {
      _user = await _api.me(access);
      notifyListeners();
      return Ok(_user!);
    } catch (e) {
      return Err(_failureFrom(e));
    }
  }

  @override
  Future<void> logout() async {
    final refresh = _refreshToken;
    try {
      if (refresh != null) {
        await _api.logout(refresh);
      }
    } catch (_) {
      // Ignoramos errores de red al cerrar sesión: limpiamos localmente igual.
    } finally {
      await _clearSession();
    }
  }

  // --- helpers ---------------------------------------------------------------

  Future<void> _applySession(AuthSession session) async {
    _accessToken = session.accessToken;
    _refreshToken = session.refreshToken;
    _user = session.user;
    await _storage.save(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    notifyListeners();
  }

  Future<void> _clearSession({bool notify = true}) async {
    _accessToken = null;
    _refreshToken = null;
    _user = null;
    await _storage.clear();
    if (notify) notifyListeners();
  }

  Failure _failureFrom(Object e) {
    if (e is ApiException) {
      switch (e.statusCode) {
        case 401:
          return const Failure(FailureKind.invalidCredentials);
        case 409:
          return const Failure(FailureKind.emailAlreadyRegistered);
        default:
          return Failure(FailureKind.unknown, e.message);
      }
    }
    if (e is NetworkException) {
      return Failure(FailureKind.network, e.message);
    }
    return const Failure(FailureKind.unknown);
  }
}
