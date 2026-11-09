import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Ruta del certificado de dev empaquetado como asset.
const String _kDevCertAsset = 'assets/certs/isy_dev_ca.pem';

/// Construye el [http.Client] de la app.
///
/// IMPORTANTE: el cliente HTTP de Dart (`dart:io`) usa su propio almacén de
/// confianza (BoringSSL) y NO consulta el `network_security_config` de Android.
/// Por eso, para confiar en el certificado AUTOFIRMADO del borde de dev hay que
/// agregarlo explícitamente a un [SecurityContext]. Esto NO desactiva la
/// verificación: se valida la cadena y el hostname (SAN) igual que en prod.
///
/// En release (o web) se usa el cliente por defecto, que confía solo en CAs
/// públicas.
Future<http.Client> buildHttpClient() async {
  if (kIsWeb || !kDebugMode) {
    return http.Client();
  }

  try {
    final data = await rootBundle.load(_kDevCertAsset);
    final context = SecurityContext(withTrustedRoots: true)
      ..setTrustedCertificatesBytes(data.buffer.asUint8List());
    return IOClient(HttpClient(context: context));
  } catch (_) {
    // Si el cert no está empaquetado, usar el cliente por defecto.
    return http.Client();
  }
}
