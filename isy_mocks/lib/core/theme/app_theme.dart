import 'package:flutter/material.dart';

import '../../models/profile.dart';
import 'profile_palettes.dart';
import 'theme_extensions.dart';

/// Construye el tema Material 3 para el tipo de perfil activo.
/// El seed del perfil define todo el ColorScheme (claro u oscuro).
/// En modo oscuro se tiñen las superficies con el tono del perfil para evitar
/// el negro plano y lograr un look más cálido y amigable.
ThemeData buildTheme(ProfileType type, Brightness brightness) {
  final seed = seedColorFor(type);
  var scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);

  if (brightness == Brightness.dark) {
    scheme = _tintedDarkScheme(scheme, seed);
  } else {
    scheme = _warmLightScheme(scheme, seed);
  }

  final isLight = brightness == Brightness.light;

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    extensions: <ThemeExtension<dynamic>>[
      isLight ? IsyColors.light : IsyColors.dark,
    ],
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    cardColor: scheme.surfaceContainer,
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: 0.5),
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

/// Tiñe las superficies del esquema oscuro con el tono del seed, subiendo un
/// poco la luminosidad para que no sea negro plano.
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

/// En claro, aporta un matiz muy sutil del perfil a las superficies para que
/// no sea blanco plano.
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
