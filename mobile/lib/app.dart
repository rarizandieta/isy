import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/services/auth_api.dart';
import 'data/services/token_storage.dart';
import 'ui/session/auth_gate.dart';
import 'ui/session/auth_session_view_model.dart';

/// Composición de la app: inyección de dependencias (servicios -> repositorio
/// -> ViewModel de sesión) y MaterialApp con el AuthGate como raíz.
class IsyApp extends StatelessWidget {
  final http.Client httpClient;

  const IsyApp({super.key, required this.httpClient});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // --- Servicios (capa de datos) ---
        Provider<AuthApi>(
          create: (_) => AuthApi(client: httpClient),
          dispose: (_, api) => api.dispose(),
        ),
        Provider<TokenStorage>(create: (_) => TokenStorage()),
        // --- Repositorio (fuente de verdad de la sesión) ---
        ChangeNotifierProvider<AuthRepository>(
          create: (ctx) => AuthRepositoryImpl(
            ctx.read<AuthApi>(),
            ctx.read<TokenStorage>(),
          ),
        ),
        // --- ViewModel de sesión a nivel app ---
        ChangeNotifierProvider<AuthSessionViewModel>(
          create: (ctx) => AuthSessionViewModel(ctx.read<AuthRepository>()),
        ),
      ],
      child: MaterialApp(
        title: 'Isy',
        debugShowCheckedModeBanner: false,
        theme: buildIsyTheme(Brightness.light),
        darkTheme: buildIsyTheme(Brightness.dark),
        home: const AuthGate(),
      ),
    );
  }
}
