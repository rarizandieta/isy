import { Inject, Injectable } from '@nestjs/common';
import { and, eq, gt, isNull } from 'drizzle-orm';
import { DRIZZLE } from '../../../database/database.constants.js';
import type { Database } from '../../../database/database.module.js';
import { userSessions } from '../../../database/schema.js';
import { Session } from '../../domain/entities/session.entity.js';
import {
  type NewSession,
  type RotateSession,
  SessionRepository,
} from '../../domain/repositories/session.repository.js';

/** Implementación Drizzle del puerto SessionRepository. */
@Injectable()
export class DrizzleSessionRepository extends SessionRepository {
  constructor(@Inject(DRIZZLE) private readonly db: Database) {
    super();
  }

  async create(data: NewSession): Promise<void> {
    await this.db.insert(userSessions).values({
      userId: data.userId,
      refreshTokenHash: data.refreshTokenHash,
      userAgent: data.userAgent,
      ipAddress: data.ipAddress,
      lastUsedAt: new Date(),
      expiresAt: data.expiresAt,
      createdBy: data.userId,
      updatedBy: data.userId,
    });
  }

  async findActiveByTokenHash(tokenHash: string): Promise<Session | null> {
    const now = new Date();
    const [row] = await this.db
      .select()
      .from(userSessions)
      .where(
        and(
          eq(userSessions.refreshTokenHash, tokenHash),
          isNull(userSessions.revokedAt),
          gt(userSessions.expiresAt, now),
        ),
      )
      .limit(1);
    if (!row) return null;
    return new Session(
      row.id,
      row.userId,
      row.expiresAt,
      row.revokedAt,
      row.userAgent,
      row.ipAddress,
    );
  }

  async rotate(sessionId: number, data: RotateSession): Promise<void> {
    const now = new Date();
    await this.db
      .update(userSessions)
      .set({
        refreshTokenHash: data.refreshTokenHash,
        lastUsedAt: now,
        updatedAt: now,
        userAgent: data.userAgent,
        ipAddress: data.ipAddress,
      })
      .where(eq(userSessions.id, sessionId));
  }

  async revokeByTokenHash(tokenHash: string): Promise<void> {
    await this.db
      .update(userSessions)
      .set({ revokedAt: new Date(), updatedAt: new Date() })
      .where(and(eq(userSessions.refreshTokenHash, tokenHash), isNull(userSessions.revokedAt)));
  }
}
