import 'package:flutter/material.dart';

import '../core/theme/theme_extensions.dart';

/// Etiqueta "Promovido" (destacado por el admin), color ámbar transversal.
class PromotedBadge extends StatelessWidget {
  const PromotedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final color = context.isyColors.promoted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 14, color: color),
          const SizedBox(width: 3),
          Text(
            'Promovido',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
