import 'package:flutter/material.dart';

import '../core/theme/profile_palettes.dart';
import '../models/profile.dart';

/// Chip que muestra el tipo de perfil con su color de marca.
class ProfileBadge extends StatelessWidget {
  final ProfileType type;
  final bool dense;

  const ProfileBadge({super.key, required this.type, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final color = brandColorFor(type);
    final padding = dense
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 4);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: dense ? 13 : 15, color: color),
          const SizedBox(width: 4),
          Text(
            type.label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: dense ? 11 : 12.5,
            ),
          ),
        ],
      ),
    );
  }
}
