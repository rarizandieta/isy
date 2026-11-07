import 'package:flutter/material.dart';

/// Botones de Single Sign-On (Apple / Google) con estilo de marca aproximado.
/// En los mocks solo disparan el flujo simulado.
class SsoButtons extends StatelessWidget {
  final void Function(String provider) onPressed;

  const SsoButtons({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        // Apple
        FilledButton.icon(
          onPressed: () => onPressed('Apple'),
          icon: const Icon(Icons.apple, size: 22),
          label: const Text('Continuar con Apple'),
          style: FilledButton.styleFrom(
            backgroundColor: isDark ? Colors.white : Colors.black,
            foregroundColor: isDark ? Colors.black : Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        // Google
        OutlinedButton.icon(
          onPressed: () => onPressed('Google'),
          icon: const _GoogleGlyph(),
          label: const Text('Continuar con Google'),
          style: OutlinedButton.styleFrom(
            foregroundColor:
                isDark ? Colors.white : const Color(0xFF3C4043),
            side: BorderSide(
              color: isDark ? Colors.white24 : const Color(0xFFDADCE0),
            ),
          ),
        ),
      ],
    );
  }
}

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF4285F4),
      ),
    );
  }
}
