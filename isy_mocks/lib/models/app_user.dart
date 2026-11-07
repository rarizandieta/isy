/// Cuenta raíz (una persona). Los perfiles se gestionan en SessionController.
class AppUser {
  final String id;
  final String name;
  final String email;
  final int avatarSeed;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatarSeed = 0,
  });
}
