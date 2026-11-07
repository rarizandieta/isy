import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routing/routes.dart';
import '../../data/session_controller.dart';
import '../../widgets/brand_background.dart';
import '../../widgets/isy_logo.dart';
import '../../widgets/sso_buttons.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _ssoLogin(BuildContext context, String provider) {
    context.read<SessionController>().loginWithSso(provider);
    Navigator.pushNamedAndRemoveUntil(context, Routes.home, (_) => false);
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
                  onPressed: () =>
                      Navigator.pushNamed(context, Routes.register),
                  child: const Text('Crear cuenta'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, Routes.login),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: scheme.surface.withValues(alpha: 0.6),
                  ),
                  child: const Text('Iniciar sesión'),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'o',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),
                SsoButtons(onPressed: (p) => _ssoLogin(context, p)),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
