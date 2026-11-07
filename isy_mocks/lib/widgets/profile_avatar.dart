import 'package:flutter/material.dart';

import '../core/formatting.dart';

/// Avatar circular con iniciales y color determinístico (o color fijo).
class ProfileAvatar extends StatelessWidget {
  final String name;
  final int seed;
  final Color? color;
  final double radius;
  final IconData? icon;

  const ProfileAvatar({
    super.key,
    required this.name,
    this.seed = 0,
    this.color,
    this.radius = 20,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? avatarColorForSeed(seed);
    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: icon != null
          ? Icon(icon, color: Colors.white, size: radius)
          : Text(
              initialsOf(name),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: radius * 0.8,
              ),
            ),
    );
  }
}
