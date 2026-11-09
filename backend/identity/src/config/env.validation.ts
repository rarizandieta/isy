/**
 * Environment configuration + validation for the identity service.
 *
 * Used by `ConfigModule.forRoot({ validate: validateEnv })`. It fails fast at
 * boot if the required secrets/connection strings are missing, and coerces the
 * numeric TTLs/port so the rest of the app can rely on real numbers.
 */
export interface EnvConfig {
  PORT: number;
  DATABASE_URL: string;
  JWT_SECRET: string;
  /** Access token lifetime, in seconds. */
  ACCESS_TTL: number;
  /** Refresh token lifetime, in seconds. */
  REFRESH_TTL: number;
}

function requireString(
  config: Record<string, unknown>,
  key: keyof EnvConfig,
  errors: string[],
): string {
  const value = config[key];
  if (typeof value !== 'string' || value.trim().length === 0) {
    errors.push(`${key} is required`);
    return '';
  }
  return value;
}

function toNumber(value: unknown, fallback: number): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

export function validateEnv(config: Record<string, unknown>): EnvConfig {
  const errors: string[] = [];

  const DATABASE_URL = requireString(config, 'DATABASE_URL', errors);
  const JWT_SECRET = requireString(config, 'JWT_SECRET', errors);

  if (errors.length > 0) {
    throw new Error(`Invalid environment configuration:\n- ${errors.join('\n- ')}`);
  }

  return {
    PORT: toNumber(config.PORT, 3001),
    DATABASE_URL,
    JWT_SECRET,
    ACCESS_TTL: toNumber(config.ACCESS_TTL, 900), // 15 min
    REFRESH_TTL: toNumber(config.REFRESH_TTL, 2_592_000), // 30 days
  };
}
