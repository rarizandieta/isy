import '../../core/result.dart';
import '../../domain/failure.dart';
import '../../domain/models/auth_session.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/models/profile.dart';
import '../api_exception.dart';
import '../failure_mapper.dart';
import '../services/auth_api.dart';
import '../services/profile_api.dart';
import '../services/token_storage.dart';
import 'auth_repository.dart';

/// Implementación del repositorio de autenticación. Orquesta los servicios HTTP
/// (AuthApi, ProfileApi) y el almacenamiento seguro (TokenStorage); traduce las
/// excepciones de transporte a [Failure] semánticos.
class AuthRepositoryImpl extends AuthRepository {
  AuthRepositoryImpl(this._api, this._storage, this._profileApi);

  final AuthApi _api;
  final TokenStorage _storage;
  final ProfileApi _profileApi;

  AuthUser? _user;
  String? _accessToken;
  String? _refreshToken;
  bool _initialized = false;
  List<Profile> _profiles = const [];
  int? _activeProfileId;

  @override
  AuthUser? get currentUser => _user;

  @override
  String? get accessToken => _accessToken;

  @override
  String? get refreshToken => _refreshToken;

  @override
  bool get isInitialized => _initialized;

  @override
  List<Profile> get profiles => List.unmodifiable(_profiles);

  @override
  int? get activeProfileId => _activeProfileId;

  @override
  Profile? get activeProfile {
    if (_profiles.isEmpty) return null;
    for (final p in _profiles) {
      if (p.id == _activeProfileId) return p;
    }
    return _profiles.first;
  }

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
      await loadProfiles();
    } on ApiException {
      // Access inválido/caducado: intentar refrescar.
      try {
        await _applySession(await _api.refresh(refresh));
        await loadProfiles();
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
      await loadProfiles();
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
      // Cargamos los perfiles ya mismo para que el tema (color por perfil) y la
      // UI conozcan el perfil activo en toda la app desde el inicio.
      await loadProfiles();
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

  @override
  Future<Result<void>> loadProfiles() async {
    final access = _accessToken;
    if (access == null) return const Err(Failure(FailureKind.unknown));
    try {
      final snapshot = await _profileApi.list(access);
      _profiles = snapshot.profiles;
      _activeProfileId = snapshot.activeProfileId;
      notifyListeners();
      return const Ok(null);
    } catch (e) {
      return Err(_failureFrom(e));
    }
  }

  @override
  Future<Result<void>> createProfile({
    required ProfileType type,
    required String displayName,
  }) async {
    final access = _accessToken;
    if (access == null) return const Err(Failure(FailureKind.unknown));
    try {
      final mutation = await _profileApi.create(
        access,
        type: type.wire,
        displayName: displayName,
      );
      await _applyProfileMutation(mutation);
      return const Ok(null);
    } catch (e) {
      return Err(_failureFrom(e));
    }
  }

  @override
  Future<Result<void>> switchProfile(int profileId) async {
    final access = _accessToken;
    if (access == null) return const Err(Failure(FailureKind.unknown));
    try {
      final mutation = await _profileApi.activate(access, profileId);
      await _applyProfileMutation(mutation);
      return const Ok(null);
    } catch (e) {
      return Err(_failureFrom(e));
    }
  }

  // --- helpers ---------------------------------------------------------------

  /// Al crear/cambiar de perfil, el backend emite un nuevo access token (el
  /// perfil activo cambió). Adoptamos ese token y actualizamos los perfiles.
  /// El refresh token NO cambia.
  Future<void> _applyProfileMutation(ProfileMutation mutation) async {
    _accessToken = mutation.accessToken;
    _profiles = mutation.profiles;
    _activeProfileId = mutation.activeProfileId;
    final refresh = _refreshToken;
    if (refresh != null) {
      await _storage.save(accessToken: mutation.accessToken, refreshToken: refresh);
    }
    notifyListeners();
  }

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
    _profiles = const [];
    _activeProfileId = null;
    await _storage.clear();
    if (notify) notifyListeners();
  }

  Failure _failureFrom(Object e) => failureFromError(e);
}
