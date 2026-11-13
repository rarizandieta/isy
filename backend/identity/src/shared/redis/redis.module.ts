import { Global, Inject, Module, type OnModuleDestroy } from '@nestjs/common';
import { Redis } from 'ioredis';
import { REDIS } from './redis.constants.js';

/**
 * Módulo global que expone un cliente Redis (token `REDIS`). Redis es estado
 * efímero (sin volumen): aquí se usa para la blocklist de access tokens
 * revocados. Config con fallo rápido para no colgar peticiones si Redis cae
 * (la lógica de negocio hace fail-open).
 */
@Global()
@Module({
  providers: [
    {
      provide: REDIS,
      useFactory: (): Redis =>
        new Redis(process.env.REDIS_URL ?? 'redis://localhost:6379', {
          maxRetriesPerRequest: 2,
          enableOfflineQueue: false,
          lazyConnect: false,
        }),
    },
  ],
  exports: [REDIS],
})
export class RedisModule implements OnModuleDestroy {
  constructor(@Inject(REDIS) private readonly redis: Redis) {}

  async onModuleDestroy(): Promise<void> {
    await this.redis.quit();
  }
}
