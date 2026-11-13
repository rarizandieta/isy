/**
 * Puerto de la blocklist de access tokens revocados. identity ESCRIBE aquí al
 * revocar (logout, "cerrar en todos los dispositivos", cambio de contraseña);
 * el gateway la LEE en cada petición protegida para rechazar al instante tokens
 * revocados pese a que el JWT es stateless. Implementación en infraestructura
 * (Redis).
 */
export abstract class TokenBlocklist {
  /** Marca un `jti` como revocado, con TTL = vida restante del access token. */
  abstract block(jti: string, ttlSeconds: number): Promise<void>;
}
