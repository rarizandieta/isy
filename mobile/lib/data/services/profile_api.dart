import 'dart:convert';

import '../../domain/models/profile.dart';
import 'json_api.dart';

/// Cliente de la API de perfiles de identity (vía gateway, `/auth/profiles`).
/// Todas las operaciones requieren un access token válido.
class ProfileApi extends JsonApi {
  ProfileApi({super.client, super.baseUrl});

  /// GET /auth/profiles -> perfiles del usuario + perfil activo.
  Future<ProfileSnapshot> list(String accessToken) async {
    final json = await sendJson(
      () => httpClient.get(uri('/auth/profiles'), headers: bearer(accessToken)),
    );
    return ProfileSnapshot.fromJson(json);
  }

  /// POST /auth/profiles -> crea un perfil (vendedor/servicios), lo activa y
  /// devuelve un nuevo access token + el estado actualizado.
  Future<ProfileMutation> create(
    String accessToken, {
    required String type,
    required String displayName,
  }) async {
    final json = await sendJson(
      () => httpClient.post(
        uri('/auth/profiles'),
        headers: bearerJson(accessToken),
        body: jsonEncode({'type': type, 'displayName': displayName}),
      ),
    );
    return ProfileMutation.fromJson(json);
  }

  /// POST /auth/profiles/:id/activate -> cambia el perfil activo y devuelve un
  /// nuevo access token + el estado actualizado.
  Future<ProfileMutation> activate(String accessToken, int profileId) async {
    final json = await sendJson(
      () => httpClient.post(
        uri('/auth/profiles/$profileId/activate'),
        headers: bearer(accessToken),
      ),
    );
    return ProfileMutation.fromJson(json);
  }
}
