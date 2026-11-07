import 'package:flutter/material.dart';

/// Tipo de perfil anidado dentro de un usuario.
enum ProfileType { buyer, seller, service }

extension ProfileTypeX on ProfileType {
  String get label {
    switch (this) {
      case ProfileType.buyer:
        return 'Comprador';
      case ProfileType.seller:
        return 'Vendedor';
      case ProfileType.service:
        return 'Servicios';
    }
  }

  IconData get icon {
    switch (this) {
      case ProfileType.buyer:
        return Icons.shopping_bag_outlined;
      case ProfileType.seller:
        return Icons.storefront_outlined;
      case ProfileType.service:
        return Icons.handyman_outlined;
    }
  }

  /// true si este tipo puede crear publicaciones (CRUD).
  bool get canPublish =>
      this == ProfileType.seller || this == ProfileType.service;
}

/// Identidad del usuario: comprador (por defecto), vendedor o servicios.
@immutable
class Profile {
  final String id;
  final ProfileType type;
  final String displayName;
  final String? description;
  final String? category;
  final int followers;

  /// true = perfil propio del usuario; false = tienda externa que se sigue.
  final bool isOwnedByUser;

  const Profile({
    required this.id,
    required this.type,
    required this.displayName,
    this.description,
    this.category,
    this.followers = 0,
    this.isOwnedByUser = true,
  });

  Profile copyWith({
    String? displayName,
    String? description,
    String? category,
    int? followers,
  }) {
    return Profile(
      id: id,
      type: type,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      category: category ?? this.category,
      followers: followers ?? this.followers,
      isOwnedByUser: isOwnedByUser,
    );
  }
}
