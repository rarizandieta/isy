import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio de almacenamiento seguro de tokens (Android Keystore / iOS
/// Keychain). Nunca en SharedPreferences planas.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _kAccess = 'isy.access_token';
  static const String _kRefresh = 'isy.refresh_token';
  static const String _kThemeMode = 'isy.theme_mode';

  final FlutterSecureStorage _storage;

  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _kAccess, value: accessToken);
    await _storage.write(key: _kRefresh, value: refreshToken);
  }

  Future<String?> readAccessToken() => _storage.read(key: _kAccess);

  Future<String?> readRefreshToken() => _storage.read(key: _kRefresh);

  /// Preferencia de tema del usuario ('system' | 'light' | 'dark'). Se guarda
  /// junto a la sesión en el dispositivo y PERSISTE al cerrar sesión (es una
  /// preferencia local, no un secreto de sesión).
  Future<void> saveThemeMode(String mode) => _storage.write(key: _kThemeMode, value: mode);

  Future<String?> readThemeMode() => _storage.read(key: _kThemeMode);

  /// Limpia solo los tokens (la preferencia de tema se conserva).
  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }
}
