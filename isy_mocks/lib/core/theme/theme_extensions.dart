import 'package:flutter/material.dart';

/// Colores transversales que NO cambian con el perfil activo.
@immutable
class IsyColors extends ThemeExtension<IsyColors> {
  final Color promoted; // badge "Promovido" (admin)
  final Color success;
  final Color danger;
  final Color love; // reacción "me encanta"

  const IsyColors({
    required this.promoted,
    required this.success,
    required this.danger,
    required this.love,
  });

  static const IsyColors light = IsyColors(
    promoted: Color(0xFFFFB300),
    success: Color(0xFF2E7D32),
    danger: Color(0xFFC62828),
    love: Color(0xFFE91E63),
  );

  static const IsyColors dark = IsyColors(
    promoted: Color(0xFFFFCA28),
    success: Color(0xFF81C784),
    danger: Color(0xFFEF9A9A),
    love: Color(0xFFF48FB1),
  );

  @override
  IsyColors copyWith({
    Color? promoted,
    Color? success,
    Color? danger,
    Color? love,
  }) {
    return IsyColors(
      promoted: promoted ?? this.promoted,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      love: love ?? this.love,
    );
  }

  @override
  IsyColors lerp(ThemeExtension<IsyColors>? other, double t) {
    if (other is! IsyColors) return this;
    return IsyColors(
      promoted: Color.lerp(promoted, other.promoted, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      love: Color.lerp(love, other.love, t)!,
    );
  }
}

/// Acceso corto a los colores transversales: `context.isyColors`.
extension IsyColorsX on BuildContext {
  IsyColors get isyColors =>
      Theme.of(this).extension<IsyColors>() ?? IsyColors.light;
}
