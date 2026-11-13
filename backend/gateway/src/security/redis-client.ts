import type { Logger } from '@nestjs/common';
import { Redis } from 'ioredis';

/**
 * Cliente Redis compartido del gateway. Redis es estado EFÍMERO (sin volumen):
 * aquí respalda el rate-limit y la lectura de la blocklist de tokens revocados.
 *
 * Config con fallo rápido (maxRetriesPerRequest + enableOfflineQueue:false) para
 * que, si Redis cae, las operaciones fallen de inmediato y la lógica de borde
 * haga fail-open (dejar pasar) en vez de colgar cada petición.
 */
export function createRedisClient(logger: Logger): Redis {
  const client = new Redis(process.env.REDIS_URL ?? 'redis://localhost:6379', {
    maxRetriesPerRequest: 2,
    enableOfflineQueue: false,
    lazyConnect: false,
  });

  // Sin este listener, los errores de conexión se vuelven excepciones no
  // manejadas. Los registramos y seguimos (fail-open lo maneja cada consumidor).
  client.on('error', (err: Error) => {
    logger.warn(`Redis no disponible: ${err.message}`);
  });

  return client;
}
