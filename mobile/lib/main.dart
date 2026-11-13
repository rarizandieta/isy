import 'package:flutter/material.dart';

import 'app.dart';
import 'core/http_client_factory.dart';
import 'data/services/token_storage.dart';
import 'ui/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final httpClient = await buildHttpClient();
  // Precargamos la preferencia de tema para arrancar sin parpadeo.
  final tokenStorage = TokenStorage();
  final initialTheme = themeModeFromWire(await tokenStorage.readThemeMode());
  runApp(
    IsyApp(
      httpClient: httpClient,
      tokenStorage: tokenStorage,
      initialThemeMode: initialTheme,
    ),
  );
}
