import 'package:flutter/material.dart';

/// Fondo con degradado derivado del color primario del tema. Da un aire
/// cálido y "de marca" a las pantallas de autenticación.
class BrandBackground extends StatelessWidget {
  final Widget child;

  const BrandBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hue = HSLColor.fromColor(scheme.primary).hue;

    final List<Color> colors = isDark
        ? [
            HSLColor.fromAHSL(1, hue, 0.40, 0.20).toColor(),
            HSLColor.fromAHSL(1, hue, 0.26, 0.13).toColor(),
            scheme.surface,
          ]
        : [
            HSLColor.fromAHSL(1, hue, 0.60, 0.90).toColor(),
            HSLColor.fromAHSL(1, hue, 0.45, 0.96).toColor(),
            scheme.surface,
          ];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
      child: SizedBox.expand(child: child),
    );
  }
}
