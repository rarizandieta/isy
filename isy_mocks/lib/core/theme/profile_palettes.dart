import 'package:flutter/material.dart';

import '../../models/profile.dart';

/// Color semilla (seed) por tipo de perfil. Material 3 deriva todo el esquema
/// a partir de estos valores.
///  - Comprador  -> verde
///  - Vendedor   -> morado
///  - Servicios  -> azul
const Map<ProfileType, Color> kProfileSeeds = {
  ProfileType.buyer: Color(0xFF2E7D32),
  ProfileType.seller: Color(0xFF6A1B9A),
  ProfileType.service: Color(0xFF1565C0),
};

/// Color de marca (acento) por perfil, usado en logo, avatares y chips.
const Map<ProfileType, Color> kProfileBrandColors = {
  ProfileType.buyer: Color(0xFF43A047),
  ProfileType.seller: Color(0xFF8E24AA),
  ProfileType.service: Color(0xFF1E88E5),
};

Color brandColorFor(ProfileType type) => kProfileBrandColors[type]!;
Color seedColorFor(ProfileType type) => kProfileSeeds[type]!;
