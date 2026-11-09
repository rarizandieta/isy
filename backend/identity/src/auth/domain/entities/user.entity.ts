/**
 * Entidad de dominio Usuario. Modelo puro (sin dependencias de framework ni de
 * la base de datos). Los repositorios mapean las filas de persistencia a esta
 * entidad.
 *
 * Nota: los roles y el hash de contraseña NO viven en esta entidad; son
 * conceptos relacionados que se obtienen por separado (roles del usuario y la
 * identidad de credenciales), para no mezclar responsabilidades.
 */
export class User {
  constructor(
    public readonly id: number,
    public readonly email: string,
    public readonly fullName: string,
    public readonly status: string,
  ) {}
}
