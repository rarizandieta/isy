import 'package:flutter/material.dart';

/// Tarjeta de superficie que contiene el formulario por encima del degradado.
class AuthPanel extends StatelessWidget {
  final Widget child;

  const AuthPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Separador "——— o ———" para las pantallas de autenticación.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('o', style: TextStyle(color: scheme.onSurfaceVariant)),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
