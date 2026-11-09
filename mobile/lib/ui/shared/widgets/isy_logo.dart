import 'package:flutter/material.dart';

/// Wordmark de Isy. Usa el color primario del tema salvo que se indique otro.
class IsyLogo extends StatelessWidget {
  final double fontSize;
  final Color? color;
  final bool showIcon;

  const IsyLogo({
    super.key,
    this.fontSize = 28,
    this.color,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Icon(Icons.storefront_rounded, color: c, size: fontSize * 1.05),
          SizedBox(width: fontSize * 0.2),
        ],
        Text(
          'isi',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: c,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
