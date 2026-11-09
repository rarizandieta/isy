/// Usuario autenticado tal como lo devuelve el microservicio identity
/// (endpoints `/auth/register`, `/auth/login` -> `user`, `/auth/me`).
class AuthUser {
  final int id;
  final String email;
  final String fullName;
  final List<String> roles;

  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.roles,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      roles: (json['roles'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
