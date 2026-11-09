import { Global, Inject, Module, type OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { drizzle, type NodePgDatabase } from 'drizzle-orm/node-postgres';
import pg from 'pg';
import { DRIZZLE, PG_POOL } from './database.constants.js';
import * as schema from './schema.js';

/** Drizzle database handle bound to the identity schema. */
export type Database = NodePgDatabase<typeof schema>;

/**
 * Global database module: exposes a shared pg connection pool and a Drizzle
 * instance (token `DRIZZLE`) to the rest of the app. Connections are opened
 * lazily by pg on first query. The pool is closed on shutdown.
 */
@Global()
@Module({
  providers: [
    {
      provide: PG_POOL,
      useFactory: (config: ConfigService) =>
        new pg.Pool({ connectionString: config.getOrThrow<string>('DATABASE_URL') }),
      inject: [ConfigService],
    },
    {
      provide: DRIZZLE,
      useFactory: (pool: pg.Pool) => drizzle(pool, { schema }),
      inject: [PG_POOL],
    },
  ],
  exports: [DRIZZLE, PG_POOL],
})
export class DatabaseModule implements OnModuleDestroy {
  constructor(@Inject(PG_POOL) private readonly pool: pg.Pool) {}

  async onModuleDestroy(): Promise<void> {
    await this.pool.end();
  }
}
