/// Error de API con el código HTTP y un mensaje legible ya extraído del
/// envelope de error del backend (`{ statusCode, message, error, ... }`).
class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Error de red / conectividad (host inalcanzable, timeout, etc.).
class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}
