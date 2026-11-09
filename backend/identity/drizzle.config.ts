import { defineConfig } from 'drizzle-kit';

/**
 * drizzle-kit configuration (used only at design time: `npm run db:generate`).
 * At runtime the service runs migrations programmatically with
 * `drizzle-orm/node-postgres/migrator` (see src/database/migrate.ts), so
 * drizzle-kit is NOT required in the runtime image.
 */
export default defineConfig({
  schema: './src/database/schema.ts',
  out: './drizzle',
  dialect: 'postgresql',
  dbCredentials: {
    url: process.env.DATABASE_URL ?? 'postgres://isy:isy@localhost:5432/identity',
  },
  casing: 'snake_case',
  verbose: true,
  strict: true,
});
