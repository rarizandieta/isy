/// Tipo de perfil con el que actúa el usuario. El valor `wire` es el que usa el
/// backend (identity) en el token y en la API de perfiles.
enum ProfileType {
  buyer,
  seller,
  serviceProvider;

  /// Valor serializado que entiende el backend.
  String get wire => switch (this) {
        ProfileType.buyer => 'buyer',
        ProfileType.seller => 'seller',
        ProfileType.serviceProvider => 'service_provider',
      };

  static ProfileType fromWire(String? value) => switch (value) {
        'seller' => ProfileType.seller,
        'service_provider' => ProfileType.serviceProvider,
        _ => ProfileType.buyer,
      };
}

/// Perfil del usuario tal como lo devuelve identity (`/auth/profiles`).
///
/// Un usuario nace con un perfil `buyer`; puede crear `seller` /
/// `service_provider`. El perfil activo (`isActive`) es el que viaja en el
/// access token y el que el gateway propaga a los microservicios.
class Profile {
  final int id;
  final ProfileType type;
  final String? displayName;
  final bool isActive;

  const Profile({
    required this.id,
    required this.type,
    required this.displayName,
    required this.isActive,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: (json['id'] as num).toInt(),
      type: ProfileType.fromWire(json['type'] as String?),
      displayName: json['displayName'] as String?,
      isActive: json['isActive'] as bool? ?? false,
    );
  }
}

/// Respuesta de `GET /auth/profiles`: lista de perfiles + cuál está activo.
class ProfileSnapshot {
  final List<Profile> profiles;
  final int? activeProfileId;

  const ProfileSnapshot({required this.profiles, required this.activeProfileId});

  factory ProfileSnapshot.fromJson(Map<String, dynamic> json) {
    return ProfileSnapshot(
      profiles: (json['profiles'] as List<dynamic>? ?? const [])
          .map((e) => Profile.fromJson(e as Map<String, dynamic>))
          .toList(),
      activeProfileId: (json['activeProfileId'] as num?)?.toInt(),
    );
  }
}

/// Respuesta de crear/activar un perfil: incluye un NUEVO access token (el perfil
/// activo cambió) que el cliente debe empezar a usar, más el estado actualizado.
class ProfileMutation {
  final String accessToken;
  final int expiresIn;
  final List<Profile> profiles;
  final int? activeProfileId;

  const ProfileMutation({
    required this.accessToken,
    required this.expiresIn,
    required this.profiles,
    required this.activeProfileId,
  });

  factory ProfileMutation.fromJson(Map<String, dynamic> json) {
    return ProfileMutation(
      accessToken: json['accessToken'] as String,
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 0,
      profiles: (json['profiles'] as List<dynamic>? ?? const [])
          .map((e) => Profile.fromJson(e as Map<String, dynamic>))
          .toList(),
      activeProfileId: (json['activeProfileId'] as num?)?.toInt(),
    );
  }
}
