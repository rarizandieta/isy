import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/profile.dart';
import 'mock_data.dart';

/// Fuente única de verdad de la sesión: usuario autenticado (simulado),
/// perfiles anidados, perfil activo y preferencia de tema.
class SessionController extends ChangeNotifier {
  AppUser? _user;
  final List<Profile> _profiles = [];
  String? _activeProfileId;
  ThemeMode _themeMode = ThemeMode.system;
  int _seq = 0;

  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;
  ThemeMode get themeMode => _themeMode;

  List<Profile> get profiles => List.unmodifiable(_profiles);

  List<Profile> profilesOfType(ProfileType type) =>
      _profiles.where((p) => p.type == type).toList();

  Profile get activeProfile {
    return _profiles.firstWhere(
      (p) => p.id == _activeProfileId,
      orElse: () => _profiles.isNotEmpty
          ? _profiles.first
          : MockData.buyerProfile(),
    );
  }

  ProfileType get activeType =>
      isLoggedIn ? activeProfile.type : ProfileType.buyer;

  bool get canPublish => isLoggedIn && activeProfile.type.canPublish;

  // --- Autenticación simulada ---

  /// Inicia sesión con la cuenta de demo (acepta cualquier credencial no vacía).
  void login() {
    _user = MockData.user();
    _profiles
      ..clear()
      ..addAll(MockData.ownedProfiles());
    _activeProfileId = _profiles.first.id; // comprador
    notifyListeners();
  }

  /// Registro tradicional: crea la cuenta con un perfil comprador por defecto.
  void register({required String name, required String email}) {
    _user = AppUser(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      avatarSeed: name.hashCode,
    );
    final buyer = Profile(
      id: 'p_buyer',
      type: ProfileType.buyer,
      displayName: name.split(' ').first,
      description: 'Nuevo en isi 👋',
    );
    _profiles
      ..clear()
      ..add(buyer);
    _activeProfileId = buyer.id;
    notifyListeners();
  }

  /// SSO simulado (Apple / Google): entra con la cuenta de demo.
  void loginWithSso(String provider) => login();

  void logout() {
    _user = null;
    _profiles.clear();
    _activeProfileId = null;
    notifyListeners();
  }

  // --- Perfiles anidados ---

  void setActiveProfile(String profileId) {
    if (_profiles.any((p) => p.id == profileId)) {
      _activeProfileId = profileId;
      notifyListeners();
    }
  }

  Profile createProfile({
    required ProfileType type,
    required String displayName,
    String? description,
    String? category,
  }) {
    final profile = Profile(
      id: 'p_${type.name}_${_seq++}',
      type: type,
      displayName: displayName,
      description: description,
      category: category,
      followers: 0,
    );
    _profiles.add(profile);
    _activeProfileId = profile.id; // activar el recién creado
    notifyListeners();
    return profile;
  }

  /// No permite eliminar el perfil comprador.
  bool removeProfile(String profileId) {
    final index = _profiles.indexWhere((p) => p.id == profileId);
    if (index < 0) return false;
    if (_profiles[index].type == ProfileType.buyer) return false;

    final wasActive = _profiles[index].id == _activeProfileId;
    _profiles.removeAt(index);
    if (wasActive) {
      _activeProfileId = _profiles.first.id; // volver al comprador
    }
    notifyListeners();
    return true;
  }

  // --- Tema ---
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}
