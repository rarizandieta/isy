import 'auth_user.dart';

/// Resultado de `/auth/login` y `/auth/refresh`: tokens + usuario.
class AuthSession {
  final String accessToken;
  final String refreshToken;
  final String tokenType;

  /// Vida del access token en segundos.
  final int expiresIn;
  final AuthUser user;

  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 0,
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
