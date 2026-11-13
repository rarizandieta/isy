import type { Logger } from '@nestjs/common';
import type { Redis } from 'ioredis';

/**
 * Blocklist de access tokens revocados. identity ESCRIBE el `jti` al revocar
 * (logout, etc.) con TTL = vida restante del token; el gateway la LEE en cada
 * petición protegida para rechazar al instante tokens revocados, pese a que el
 * JWT es stateless y su firma sigue siendo válida hasta expirar.
 *
 * FAIL-OPEN: si Redis no responde, se asume NO revocado. La firma del JWT ya
 * garantiza autenticidad; la ventana de exposición está acotada por el TTL corto
 * del access token.
 */
export async function isTokenBlocked(
  redis: Redis,
  jti: string | undefined,
  logger: Logger,
): Promise<boolean> {
  if (!jti) return false;
  try {
    const hit = await redis.exists(`bl:${jti}`);
    return hit === 1;
  } catch (err) {
    logger.warn(`blocklist fail-open (jti=${jti}): ${(err as Error).message}`);
    return false;
  }
}
