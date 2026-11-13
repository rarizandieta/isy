import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../domain/models/auth_session.dart';
import '../../domain/models/auth_user.dart';
import '../api_exception.dart';

/// Servicio HTTP del microservicio identity. Encapsula los cinco endpoints de
/// autenticación y normaliza respuestas/errores. Es un acceso "tonto" a datos:
/// no mantiene estado de sesión (de eso se encarga el repositorio).
class AuthApi {
  AuthApi({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.gatewayBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  static const Duration _timeout = Duration(seconds: 15);
  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
  };

  /// POST /auth/register -> usuario creado (sin tokens).
  Future<AuthUser> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final json = await _send(
      () => _client.post(
        _uri('/auth/register'),
        headers: _jsonHeaders,
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'password': password,
        }),
      ),
    );
    return AuthUser.fromJson(json);
  }

  /// POST /auth/login -> access + refresh + usuario.
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final json = await _send(
      () => _client.post(
        _uri('/auth/login'),
        headers: _jsonHeaders,
        body: jsonEncode({'email': email, 'password': password}),
      ),
    );
    return AuthSession.fromJson(json);
  }

  /// GET /auth/me -> usuario actual (requiere access token).
  Future<AuthUser> me(String accessToken) async {
    final json = await _send(
      () => _client.get(
        _uri('/auth/me'),
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );
    return AuthUser.fromJson(json);
  }

  /// POST /auth/refresh -> rota el refresh token y emite nuevo access.
  Future<AuthSession> refresh(String refreshToken) async {
    final json = await _send(
      () => _client.post(
        _uri('/auth/refresh'),
        headers: _jsonHeaders,
        body: jsonEncode({'refreshToken': refreshToken}),
      ),
    );
    return AuthSession.fromJson(json);
  }

  /// POST /auth/logout -> revoca la sesión (204, sin cuerpo).
  Future<void> logout(String refreshToken) async {
    await _send(
      () => _client.post(
        _uri('/auth/logout'),
        headers: _jsonHeaders,
        body: jsonEncode({'refreshToken': refreshToken}),
      ),
      expectBody: false,
    );
  }

  void dispose() => _client.close();

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  /// Lanza la petición con timeout y normaliza el resultado:
  /// - 2xx -> cuerpo JSON (o `{}` si no hay).
  /// - error HTTP -> [ApiException] con el mensaje del backend.
  /// - fallo de red/timeout -> [NetworkException].
  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request, {
    bool expectBody = true,
  }) async {
    final http.Response res;
    try {
      res = await request().timeout(_timeout);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const NetworkException(
        'No se pudo conectar con el servidor. Verifica que el backend esté arriba.',
      );
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (!expectBody || res.body.isEmpty) return const <String, dynamic>{};
      final decoded = jsonDecode(res.body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    }

    throw ApiException(res.statusCode, _extractMessage(res));
  }

  String _extractMessage(http.Response res) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['message'] != null) {
        final dynamic msg = decoded['message'];
        if (msg is List) return msg.join('\n');
        return msg.toString();
      }
    } catch (_) {
      // cuerpo no-JSON
    }
    return 'Error ${res.statusCode}';
  }
}
