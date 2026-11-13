import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/store_repository.dart';
import 'data/repositories/store_repository_impl.dart';
import 'data/services/auth_api.dart';
import 'data/services/profile_api.dart';
import 'data/services/store_api.dart';
import 'data/services/token_storage.dart';
import 'ui/session/auth_gate.dart';
import 'ui/session/auth_session_view_model.dart';
import 'ui/theme/theme_controller.dart';

/// Composición de la app: inyección de dependencias (servicios -> repositorio
/// -> ViewModel de sesión) y MaterialApp con el AuthGate como raíz.
class IsyApp extends StatelessWidget {
  final http.Client httpClient;
  final TokenStorage tokenStorage;
  final ThemeMode initialThemeMode;

  const IsyApp({
    super.key,
    required this.httpClient,
    required this.tokenStorage,
    required this.initialThemeMode,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // --- Servicios (capa de datos) ---
        Provider<AuthApi>(
          create: (_) => AuthApi(client: httpClient),
          dispose: (_, api) => api.dispose(),
        ),
        Provider<ProfileApi>(
          create: (_) => ProfileApi(client: httpClient),
          dispose: (_, api) => api.dispose(),
        ),
        Provider<StoreApi>(
          create: (_) => StoreApi(client: httpClient),
          dispose: (_, api) => api.dispose(),
        ),
        Provider<TokenStorage>(create: (_) => tokenStorage),
        // --- Tema (preferencia persistida en el dispositivo) ---
        ChangeNotifierProvider<ThemeController>(
          create: (ctx) => ThemeController(
            ctx.read<TokenStorage>(),
            initial: initialThemeMode,
          ),
        ),
        // --- Repositorio (fuente de verdad de la sesión) ---
        ChangeNotifierProvider<AuthRepository>(
          create: (ctx) => AuthRepositoryImpl(
            ctx.read<AuthApi>(),
            ctx.read<TokenStorage>(),
            ctx.read<ProfileApi>(),
          ),
        ),
        // --- Repositorio de Mini Tienda (usa el token de AuthRepository) ---
        Provider<StoreRepository>(
          create: (ctx) => StoreRepositoryImpl(
            ctx.read<StoreApi>(),
            ctx.read<AuthRepository>(),
          ),
        ),
        // --- ViewModel de sesión a nivel app ---
        ChangeNotifierProvider<AuthSessionViewModel>(
          create: (ctx) => AuthSessionViewModel(ctx.read<AuthRepository>()),
        ),
      ],
      // El tema reacciona a DOS cosas: el modo (claro/oscuro/sistema) y el
      // perfil activo (verde comprador / morado vendedor / azul servicios).
      child: Consumer2<ThemeController, AuthRepository>(
        builder: (context, themeController, auth, _) {
          final profile = auth.activeProfile?.type;
          return MaterialApp(
            title: 'Isy',
            debugShowCheckedModeBanner: false,
            theme: buildIsyTheme(Brightness.light, profile),
            darkTheme: buildIsyTheme(Brightness.dark, profile),
            themeMode: themeController.mode,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
