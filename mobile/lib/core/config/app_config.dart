import 'package:flutter/foundation.dart';

/// Configuración de entorno de la app.
///
/// `identityBaseUrl` apunta al microservicio de identidad. Durante el
/// desarrollo el backend corre en el host (Docker, puerto 3001):
///  - Emulador Android: `10.0.2.2` es el alias del localhost del host.
///  - iOS simulador / escritorio / web: `localhost`.
///
/// Se puede sobrescribir en tiempo de compilación con:
///   flutter run --dart-define=IDENTITY_BASE_URL=http://192.168.1.50:3001
class AppConfig {
  const AppConfig._();

  static String get identityBaseUrl {
    const override = String.fromEnvironment('IDENTITY_BASE_URL');
    if (override.isNotEmpty) return override;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3001';
    }
    return 'http://localhost:3001';
  }
}
