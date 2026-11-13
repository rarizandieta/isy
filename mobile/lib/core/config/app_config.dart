import 'package:flutter/foundation.dart';

/// Configuración de entorno de la app.
///
/// `gatewayBaseUrl` apunta al API Gateway (el borde lógico de la plataforma).
/// TODO el tráfico de la app entra por aquí: el gateway valida el access token,
/// inyecta el contexto de identidad (x-user-id / x-profile-id / x-profile-type)
/// a partir del token y hace de proxy a los microservicios:
///   - identity  -> /auth/*         (login, perfiles, ...)
///   - ministores-> /stores, /catalogs, /media/files, ...
///
/// Desarrollo: el gateway se publica en el host en el puerto 3000 (ver
/// docker-compose.override.yml). Según dónde corra la app:
///  - Emulador Android: `10.0.2.2` es el alias del localhost del host.
///  - iOS simulador / escritorio / web: `localhost`.
///  - DISPOSITIVO FÍSICO: usa la IP LAN del equipo de desarrollo, p. ej.:
///      flutter run --dart-define=GATEWAY_BASE_URL=http://192.168.1.50:3000
///
/// En producción el único expuesto es nginx (443); ahí este valor sería algo
/// como `https://api.isy.app` (con el prefijo que enrute al gateway).
class AppConfig {
  const AppConfig._();

  static String get gatewayBaseUrl {
    const override = String.fromEnvironment('GATEWAY_BASE_URL');
    if (override.isNotEmpty) return override;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }
}
