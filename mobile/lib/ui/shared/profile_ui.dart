import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/profile.dart';

/// Mapeos de presentación para [ProfileType] (texto en español, icono y color
/// de marca por tipo de perfil). Coincide con la paleta del mock.

String profileTypeLabel(ProfileType type) => switch (type) {
      ProfileType.buyer => 'Comprador',
      ProfileType.seller => 'Vendedor',
      ProfileType.serviceProvider => 'Servicios',
    };

IconData profileTypeIcon(ProfileType type) => switch (type) {
      ProfileType.buyer => Icons.shopping_bag_outlined,
      ProfileType.seller => Icons.storefront_outlined,
      ProfileType.serviceProvider => Icons.handyman_outlined,
    };

/// Acento de marca por perfil. Fuente única: [profileBrandColor] (core/theme).
Color profileTypeColor(ProfileType type) => profileBrandColor(type);

/// Nombre a mostrar de un perfil (usa el tipo cuando no hay displayName, p. ej.
/// el perfil comprador por defecto).
String profileDisplayName(Profile profile) =>
    (profile.displayName != null && profile.displayName!.trim().isNotEmpty)
        ? profile.displayName!.trim()
        : profileTypeLabel(profile.type);
