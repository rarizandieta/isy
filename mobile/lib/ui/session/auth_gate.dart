import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/welcome/welcome_view.dart';
import '../home/home_view.dart';
import '../shared/widgets/isy_logo.dart';
import 'auth_session_view_model.dart';

/// Decide qué pantalla mostrar según el estado de sesión (observa al
/// AuthSessionViewModel).
///
/// Los permisos de cámara/galería NO se piden aquí al arrancar: pedirlos por
/// adelantado abría el selector de fotos del sistema en el primer inicio. El
/// `image_picker` los gestiona de forma contextual —la galería usa el Android
/// Photo Picker (sin permiso) y la cámara pide su permiso— cuando el usuario
/// realmente toca "Tomar foto" o "Elegir de la galería".
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status =
        context.select<AuthSessionViewModel, AuthStatus>((vm) => vm.status);

    switch (status) {
      case AuthStatus.unknown:
        return const _SplashScreen();
      case AuthStatus.unauthenticated:
        return const WelcomeView();
      case AuthStatus.authenticated:
        return const HomeView();
    }
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IsyLogo(fontSize: 44),
            SizedBox(height: 24),
            SizedBox(
              height: 26,
              width: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
