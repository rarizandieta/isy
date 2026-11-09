import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Logger } from '@nestjs/common';
import { drizzle } from 'drizzle-orm/node-postgres';
import { migrate } from 'drizzle-orm/node-postgres/migrator';
import pg from 'pg';
import { roles } from './schema.js';

const logger = new Logger('Migrations');

/**
 * Platform role catalogue. Seeded idempotently after migrations.
 * A user is born with `buyer`; `seller`/`service_provider` are added when the
 * matching profile is created; `admin` is granted manually.
 */
const DEFAULT_ROLES = [
  { code: 'admin', name: 'Administrador', description: 'Acceso administrativo de la plataforma' },
  { code: 'buyer', name: 'Comprador', description: 'Rol por defecto al registrarse' },
  { code: 'seller', name: 'Vendedor', description: 'Puede gestionar una mini tienda' },
  {
    code: 'service_provider',
    name: 'Prestador de servicios',
    description: 'Ofrece servicios en la plataforma',
  },
] as const;

/**
 * Resolve the folder that holds the generated SQL migrations.
 * - Honors MIGRATIONS_DIR when set.
 * - Otherwise resolves `drizzle/` next to the project root. When running from
 *   the compiled output the file lives at `dist/database/migrate.js`, so the
 *   project root is two levels up; in that layout `drizzle/` is copied beside
 *   `dist/`. We also fall back to the current working directory.
 */
function resolveMigrationsFolder(): string {
  if (process.env.MIGRATIONS_DIR) {
    return resolve(process.env.MIGRATIONS_DIR);
  }
  return resolve(process.cwd(), 'drizzle');
}

async function seedRoles(db: ReturnType<typeof drizzle>): Promise<void> {
  // Idempotent: ON CONFLICT (code) DO NOTHING.
  await db.insert(roles).values([...DEFAULT_ROLES]).onConflictDoNothing({ target: roles.code });
  logger.log(`Seeded roles catalogue (${DEFAULT_ROLES.map((r) => r.code).join(', ')})`);
}

/**
 * Run pending migrations and seed the role catalogue. Uses its own short-lived
 * pool so it can run standalone (CLI) or at service startup without depending on
 * the Nest DI container. Only needs `drizzle-orm` + `pg` at runtime (no drizzle-kit).
 */
export async function runMigrations(databaseUrl: string): Promise<void> {
  const migrationsFolder = resolveMigrationsFolder();
  const pool = new pg.Pool({ connectionString: databaseUrl });
  const db = drizzle(pool);

  try {
    logger.log(`Applying migrations from ${migrationsFolder} ...`);
    await migrate(db, { migrationsFolder });
    logger.log('Migrations applied.');
    await seedRoles(db);
  } finally {
    await pool.end();
  }
}

// Allow running directly as a CLI: `node dist/database/migrate.js`.
const isDirectRun = (() => {
  if (!process.argv[1]) return false;
  return resolve(process.argv[1]) === fileURLToPath(import.meta.url);
})();

if (isDirectRun) {
  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) {
    logger.error('DATABASE_URL is required to run migrations.');
    process.exit(1);
  }
  runMigrations(databaseUrl)
    .then(() => {
      logger.log('Done.');
      process.exit(0);
    })
    .catch((err: unknown) => {
      logger.error('Migration failed', err instanceof Error ? err.stack : String(err));
      process.exit(1);
    });
}
