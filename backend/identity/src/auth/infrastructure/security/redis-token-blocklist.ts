import { Inject, Injectable, Logger } from '@nestjs/common';
import type { Redis } from 'ioredis';
import { REDIS } from '../../../shared/redis/redis.constants.js';
import { TokenBlocklist } from '../../domain/services/token-blocklist.js';

/** Implementación de la blocklist con Redis (clave `bl:<jti>` con TTL). */
@Injectable()
export class RedisTokenBlocklist extends TokenBlocklist {
  private readonly logger = new Logger(RedisTokenBlocklist.name);

  constructor(@Inject(REDIS) private readonly redis: Redis) {
    super();
  }

  async block(jti: string, ttlSeconds: number): Promise<void> {
    try {
      await this.redis.set(`bl:${jti}`, '1', 'EX', ttlSeconds);
    } catch (err) {
      // fail-open: si Redis no está disponible no rompemos el logout.
      this.logger.warn(
        `No se pudo escribir en la blocklist (jti=${jti}): ${(err as Error).message}`,
      );
    }
  }
}
