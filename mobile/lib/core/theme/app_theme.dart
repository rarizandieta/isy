import 'package:flutter/material.dart';

import '../../domain/models/profile.dart';

/// Paleta central de la app. Es la ÚNICA fuente de verdad del color por perfil:
/// toda la app tiñe su tema a partir de aquí, para que el usuario identifique
/// de un vistazo en qué perfil está.
///  - Comprador  -> verde
///  - Vendedor   -> morado
///  - Servicios  -> azul
///
/// `kProfileSeeds` son las semillas Material 3 (derivan TODO el ColorScheme).
/// `kProfileBrandColors` son los acentos de marca (logo, avatares, chips).
const Map<ProfileType, Color> kProfileSeeds = {
  ProfileType.buyer: Color(0xFF2E7D32),
  ProfileType.seller: Color(0xFF6A1B9A),
  ProfileType.serviceProvider: Color(0xFF1565C0),
};

const Map<ProfileType, Color> kProfileBrandColors = {
  ProfileType.buyer: Color(0xFF43A047),
  ProfileType.seller: Color(0xFF8E24AA),
  ProfileType.serviceProvider: Color(0xFF1E88E5),
};

/// Semilla del perfil (verde comprador por defecto / sin sesión).
Color profileSeedColor(ProfileType? type) =>
    kProfileSeeds[type] ?? kProfileSeeds[ProfileType.buyer]!;

/// Acento de marca del perfil (verde comprador por defecto / sin sesión).
Color profileBrandColor(ProfileType? type) =>
    kProfileBrandColors[type] ?? kProfileBrandColors[ProfileType.buyer]!;

/// Semilla por defecto (compat): marca comprador.
const Color kIsySeed = Color(0xFF2E7D32);

/// Tema Material 3 de la app, teñido según el [profile] activo. Mantiene el
/// estilo de los mocks (inputs redondeados rellenos, botones altos) y aplica un
/// matiz sutil del perfil a las superficies para un look cálido y no plano.
ThemeData buildIsyTheme(Brightness brightness, [ProfileType? profile]) {
  final seed = profileSeedColor(profile);
  final base = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  final scheme = brightness == Brightness.dark
      ? _tintedDarkScheme(base, seed)
      : _warmLightScheme(base, seed);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    cardColor: scheme.surfaceContainer,
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: 0.5),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
  );
}

/// Oscuro: tiñe las superficies con el tono del perfil (evita el negro plano).
ColorScheme _tintedDarkScheme(ColorScheme base, Color seed) {
  final hue = HSLColor.fromColor(seed).hue;
  Color surf(double lightness, [double sat = 0.16]) =>
      HSLColor.fromAHSL(1, hue, sat, lightness).toColor();

  return base.copyWith(
    surface: surf(0.11),
    surfaceContainerLowest: surf(0.08),
    surfaceContainerLow: surf(0.13),
    surfaceContainer: surf(0.15),
    surfaceContainerHigh: surf(0.18),
    surfaceContainerHighest: surf(0.22),
    surfaceTint: base.primary,
  );
}

/// Claro: matiz muy sutil del perfil en las superficies (evita el blanco plano).
ColorScheme _warmLightScheme(ColorScheme base, Color seed) {
  final hue = HSLColor.fromColor(seed).hue;
  Color surf(double lightness, double sat) =>
      HSLColor.fromAHSL(1, hue, sat, lightness).toColor();

  return base.copyWith(
    surface: surf(0.985, 0.30),
    surfaceContainerLowest: surf(1.0, 0.0),
    surfaceContainerLow: surf(0.97, 0.28),
    surfaceContainer: surf(0.955, 0.28),
    surfaceContainerHigh: surf(0.93, 0.26),
    surfaceContainerHighest: surf(0.91, 0.24),
  );
}
