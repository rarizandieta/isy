import 'package:flutter/material.dart';

import '../../shared/widgets/auth_panel.dart';
import '../../shared/widgets/brand_background.dart';
import '../../shared/widgets/isy_logo.dart';
import '../../shared/widgets/sso_buttons.dart';
import '../login/login_view.dart';
import '../register/register_view.dart';

/// Pantalla inicial sin sesión: marca + accesos a registro e inicio de sesión.
/// No necesita ViewModel (no tiene lógica, solo navega).
class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  // SSO (Apple/Google): por ahora solo interfaz. La integración real se hará
  // después; aquí solo avisamos.
  void _sso(BuildContext context, String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Crear cuenta con $provider: disponible próximamente.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: BrandBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 3),
                const IsyLogo(fontSize: 52),
                const SizedBox(height: 12),
                Text(
                  'Tu mercado, tu gente',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const Spacer(flex: 4),
                FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const RegisterView(),
                    ),
                  ),
                  child: const Text('Crear cuenta'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const LoginView()),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: scheme.surface.withValues(alpha: 0.6),
                  ),
                  child: const Text('Iniciar sesión'),
                ),
                const SizedBox(height: 20),
                const OrDivider(),
                const SizedBox(height: 20),
                SsoButtons(onPressed: (provider) => _sso(context, provider)),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
