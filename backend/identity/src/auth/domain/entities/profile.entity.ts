/**
 * Entidad de dominio Perfil. Un usuario puede actuar bajo distintos perfiles
 * (comprador, vendedor, prestador de servicios). El perfil ACTIVO es el que
 * viaja en el access token y que el gateway propaga a los microservicios
 * (x-profile-id / x-profile-type), para que estos sepan "en calidad de qué"
 * actúa el usuario sin leer el JWT.
 *
 * Modelo puro, sin dependencias de framework ni de la base de datos.
 */
export type ProfileType = 'buyer' | 'seller' | 'service_provider';

export class Profile {
  constructor(
    public readonly id: number,
    public readonly userId: number,
    public readonly type: ProfileType,
    public readonly isDefault: boolean,
    public readonly displayName: string | null,
  ) {}
}
