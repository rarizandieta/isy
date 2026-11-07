import 'package:flutter/material.dart';

/// Tiempo relativo en español ("hace 2 h").
String timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'ahora';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  if (diff.inDays < 7) return 'hace ${diff.inDays} d';
  final weeks = (diff.inDays / 7).floor();
  return 'hace $weeks sem';
}

/// Formatea un precio opcional ("$12.50"). Devuelve '' si es null.
String priceLabel(double? price) =>
    price == null ? '' : '\$${price.toStringAsFixed(2)}';

/// Iniciales a partir de un nombre (máximo 2 letras).
String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return (parts.first.characters.first + parts[1].characters.first)
      .toUpperCase();
}

/// Par de colores determinístico para placeholders de imagen.
List<Color> gradientForSeed(int seed) {
  final hue1 = (seed * 37) % 360;
  final hue2 = (hue1 + 45) % 360;
  return [
    HSLColor.fromAHSL(1, hue1.toDouble(), 0.55, 0.52).toColor(),
    HSLColor.fromAHSL(1, hue2.toDouble(), 0.6, 0.40).toColor(),
  ];
}

/// Color de avatar determinístico a partir de una semilla.
Color avatarColorForSeed(int seed) {
  final hue = (seed.abs() * 47) % 360;
  return HSLColor.fromAHSL(1, hue.toDouble(), 0.5, 0.45).toColor();
}
