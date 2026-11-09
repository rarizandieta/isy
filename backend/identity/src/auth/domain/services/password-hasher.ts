/**
 * Puerto para el hashing de contraseñas. La implementación concreta (bcrypt,
 * argon2, …) vive en infraestructura; el dominio solo conoce este contrato.
 */
export abstract class PasswordHasher {
  abstract hash(plain: string): Promise<string>;
  abstract compare(plain: string, hash: string): Promise<boolean>;
}
