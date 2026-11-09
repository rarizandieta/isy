import { sql } from 'drizzle-orm';
import {
  integer,
  pgEnum,
  pgTable,
  serial,
  text,
  timestamp,
  uniqueIndex,
  varchar,
} from 'drizzle-orm/pg-core';

/**
 * Drizzle schema for the `identity` database — Module 1 (Users & Auth).
 *
 * IDs: enteros autoincrementables (`serial` -> secuencia por tabla
 * `<tabla>_id_seq`). Las FKs y las columnas de auditoría (`*_by`) son `integer`.
 *
 * Scope of this increment: manual registration (email/password) + login + roles.
 * SSO (Apple/Google) and OTP are NOT implemented here; the model is left ready:
 *   - `auth_identities.provider` already supports google/apple.
 *   - `users.status` / `users.emailVerifiedAt` are ready for the OTP flow.
 */

// --- Postgres enums ---------------------------------------------------------
export const userStatus = pgEnum('user_status', [
  'pending_verification',
  'active',
  'suspended',
  'deleted',
]);

export const authProvider = pgEnum('auth_provider', ['password', 'google', 'apple']);

/**
 * Audit columns present in EVERY table.
 * `*_by` are plain integer references to the acting user id (null when the
 * system acts). They are kept as plain integer columns (no FK) in this
 * increment to avoid circular self-references on `users` and to keep the
 * first-user bootstrap simple.
 */
const auditColumns = {
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  createdBy: integer('created_by'),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  updatedBy: integer('updated_by'),
};

// --- users ------------------------------------------------------------------
export const users = pgTable(
  'users',
  {
    id: serial('id').primaryKey(),
    fullName: varchar('full_name', { length: 120 }).notNull(),
    // Email is normalized to lowercase in the application layer.
    email: text('email').notNull(),
    avatarUrl: text('avatar_url'),
    // Default 'active' in this increment (no OTP yet).
    // TODO(OTP): switch default to 'pending_verification' and flip to 'active'
    // once the e-mail verification flow is implemented.
    status: userStatus('status').notNull().default('active'),
    emailVerifiedAt: timestamp('email_verified_at', { withTimezone: true }),
    lastLoginAt: timestamp('last_login_at', { withTimezone: true }),
    ...auditColumns,
  },
  (table) => [
    // Case-insensitive uniqueness on email (defense in depth; app also lowercases).
    uniqueIndex('users_email_lower_unique').on(sql`lower(${table.email})`),
  ],
);

// --- auth_identities --------------------------------------------------------
export const authIdentities = pgTable(
  'auth_identities',
  {
    id: serial('id').primaryKey(),
    userId: integer('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    provider: authProvider('provider').notNull(),
    // Null for password identities; set for SSO (provider `sub`).
    providerUid: varchar('provider_uid', { length: 255 }),
    // Only set for provider = 'password'.
    passwordHash: text('password_hash'),
    email: text('email'),
    ...auditColumns,
  },
  (table) => [
    // At most one identity per provider per user.
    uniqueIndex('auth_identities_user_provider_unique').on(table.userId, table.provider),
    // An SSO identity is not shared across accounts. provider_uid is null for
    // password rows, and NULLs are distinct, so multiple password rows are allowed.
    uniqueIndex('auth_identities_provider_uid_unique').on(table.provider, table.providerUid),
  ],
);

// --- roles ------------------------------------------------------------------
export const roles = pgTable('roles', {
  id: serial('id').primaryKey(),
  code: varchar('code', { length: 32 }).notNull().unique(),
  name: varchar('name', { length: 60 }).notNull(),
  description: text('description'),
  ...auditColumns,
});

// --- user_roles (N:M) -------------------------------------------------------
export const userRoles = pgTable(
  'user_roles',
  {
    id: serial('id').primaryKey(),
    userId: integer('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    roleId: integer('role_id')
      .notNull()
      .references(() => roles.id),
    ...auditColumns,
  },
  (table) => [uniqueIndex('user_roles_user_role_unique').on(table.userId, table.roleId)],
);

// --- user_sessions ----------------------------------------------------------
export const userSessions = pgTable('user_sessions', {
  id: serial('id').primaryKey(),
  userId: integer('user_id')
    .notNull()
    .references(() => users.id, { onDelete: 'cascade' }),
  // SHA-256 hash of the opaque refresh token (never stored in clear).
  refreshTokenHash: text('refresh_token_hash').notNull().unique(),
  userAgent: text('user_agent'),
  ipAddress: text('ip_address'),
  lastUsedAt: timestamp('last_used_at', { withTimezone: true }),
  expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
  revokedAt: timestamp('revoked_at', { withTimezone: true }),
  ...auditColumns,
});

// Inferred row types (handy for the service layer).
export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;
export type Role = typeof roles.$inferSelect;
export type UserSession = typeof userSessions.$inferSelect;
