import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../api_exception.dart';

/// Base para los servicios HTTP/JSON que hablan con el gateway. Encapsula el
/// cliente, la URL base, el timeout y la normalización de respuestas/errores
/// (2xx -> JSON; error HTTP -> [ApiException]; fallo de red/timeout ->
/// [NetworkException]). Mismo patrón que `AuthApi`, reutilizable.
abstract class JsonApi {
  JsonApi({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? AppConfig.gatewayBaseUrl;

  final http.Client _client;
  final String baseUrl;

  static const Duration _timeout = Duration(seconds: 15);

  Uri uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> bearer(String accessToken) => {
        'Authorization': 'Bearer $accessToken',
      };

  Map<String, String> bearerJson(String accessToken) => {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

  http.Client get httpClient => _client;

  void dispose() => _client.close();

  /// Ejecuta la petición y devuelve el cuerpo JSON decodificado (Map o List).
  Future<dynamic> sendRaw(
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
      return jsonDecode(res.body);
    }

    throw ApiException(res.statusCode, _extractMessage(res));
  }

  /// Variante que garantiza un Map como resultado (objetos JSON).
  Future<Map<String, dynamic>> sendJson(
    Future<http.Response> Function() request, {
    bool expectBody = true,
  }) async {
    final decoded = await sendRaw(request, expectBody: expectBody);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
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
