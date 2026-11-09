import type { Session } from '../entities/session.entity.js';

/** Datos para abrir una nueva sesión de refresh. */
export interface NewSession {
  userId: number;
  refreshTokenHash: string;
  userAgent?: string;
  ipAddress?: string;
  expiresAt: Date;
}

/** Datos para rotar una sesión existente (nuevo hash + metadatos). */
export interface RotateSession {
  refreshTokenHash: string;
  userAgent: string | null;
  ipAddress: string | null;
}

/**
 * Puerto de persistencia de sesiones de refresh (lo implementa infraestructura).
 */
export abstract class SessionRepository {
  abstract create(data: NewSession): Promise<void>;

  /** Devuelve la sesión activa (no revocada y no expirada) para ese hash, o null. */
  abstract findActiveByTokenHash(tokenHash: string): Promise<Session | null>;

  /** Rota el refresh token de una sesión (y desliza last_used_at). */
  abstract rotate(sessionId: number, data: RotateSession): Promise<void>;

  /** Revoca la sesión asociada a ese hash (idempotente). */
  abstract revokeByTokenHash(tokenHash: string): Promise<void>;
}
