import 'package:flutter/material.dart';

import '../../core/routing/routes.dart';
import '../../core/theme/profile_palettes.dart';
import '../../models/profile.dart';
import '../../widgets/brand_background.dart';

class BuyerOnboardingScreen extends StatelessWidget {
  const BuyerOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final green = brandColorFor(ProfileType.buyer);
    return Scaffold(
      body: BrandBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              CircleAvatar(
                radius: 56,
                backgroundColor: green.withValues(alpha: 0.15),
                child: Icon(ProfileType.buyer.icon, size: 56, color: green),
              ),
              const SizedBox(height: 28),
              Text(
                '¡Bienvenido a isi!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Naciste con tu perfil de Comprador. Con él puedes seguir '
                'tiendas, descubrir publicaciones y contactar vendedores.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: 24),
              _Hint(
                color: green,
                icon: Icons.palette_outlined,
                text: 'Tu perfil comprador usa el tema verde.',
              ),
              const SizedBox(height: 12),
              _Hint(
                color: green,
                icon: Icons.add_business_outlined,
                text: 'Más adelante podrás crear tiendas y servicios.',
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context, Routes.home, (_) => false),
                  child: const Text('Explorar isi'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const _Hint({required this.color, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    );
  }
}
