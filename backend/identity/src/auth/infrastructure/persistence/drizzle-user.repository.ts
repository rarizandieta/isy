import { Inject, Injectable } from '@nestjs/common';
import { and, eq, sql } from 'drizzle-orm';
import { DRIZZLE } from '../../../database/database.constants.js';
import type { Database } from '../../../database/database.module.js';
import { authIdentities, roles, userRoles, users } from '../../../database/schema.js';
import { User } from '../../domain/entities/user.entity.js';
import { EmailAlreadyRegisteredError } from '../../domain/errors/auth.errors.js';
import {
  type NewUserWithPassword,
  UserRepository,
  type UserCredentials,
} from '../../domain/repositories/user.repository.js';

/** Implementación Drizzle del puerto UserRepository. */
@Injectable()
export class DrizzleUserRepository extends UserRepository {
  constructor(@Inject(DRIZZLE) private readonly db: Database) {
    super();
  }

  async existsByEmail(email: string): Promise<boolean> {
    const rows = await this.db
      .select({ id: users.id })
      .from(users)
      .where(sql`lower(${users.email}) = ${email}`)
      .limit(1);
    return rows.length > 0;
  }

  async createWithPassword(data: NewUserWithPassword): Promise<User> {
    try {
      const created = await this.db.transaction(async (tx) => {
        const [user] = await tx
          .insert(users)
          .values({ fullName: data.fullName, email: data.email, status: 'active' })
          .returning({
            id: users.id,
            email: users.email,
            fullName: users.fullName,
            status: users.status,
          });

        await tx.insert(authIdentities).values({
          userId: user.id,
          provider: 'password',
          passwordHash: data.passwordHash,
          email: data.email,
          createdBy: user.id,
          updatedBy: user.id,
        });

        const [role] = await tx
          .select({ id: roles.id })
          .from(roles)
          .where(eq(roles.code, data.roleCode))
          .limit(1);
        if (!role) {
          // El catálogo de roles se siembra al arranque; esto no debería ocurrir.
          throw new Error(`Default role "${data.roleCode}" is missing (seed not run)`);
        }

        await tx.insert(userRoles).values({
          userId: user.id,
          roleId: role.id,
          createdBy: user.id,
          updatedBy: user.id,
        });

        return user;
      });

      return new User(created.id, created.email, created.fullName, created.status);
    } catch (err) {
      // Red de seguridad para el índice unique(lower(email)) bajo carrera.
      if (this.isUniqueViolation(err)) {
        throw new EmailAlreadyRegisteredError();
      }
      throw err;
    }
  }

  async findById(id: number): Promise<User | null> {
    const [row] = await this.db
      .select({
        id: users.id,
        email: users.email,
        fullName: users.fullName,
        status: users.status,
      })
      .from(users)
      .where(eq(users.id, id))
      .limit(1);
    return row ? new User(row.id, row.email, row.fullName, row.status) : null;
  }

  async findCredentialsByEmail(email: string): Promise<UserCredentials | null> {
    const [row] = await this.db
      .select({
        id: users.id,
        email: users.email,
        fullName: users.fullName,
        status: users.status,
        passwordHash: authIdentities.passwordHash,
      })
      .from(users)
      .innerJoin(
        authIdentities,
        and(eq(authIdentities.userId, users.id), eq(authIdentities.provider, 'password')),
      )
      .where(sql`lower(${users.email}) = ${email}`)
      .limit(1);
    if (!row) return null;
    return {
      user: new User(row.id, row.email, row.fullName, row.status),
      passwordHash: row.passwordHash,
    };
  }

  async findRoleCodes(userId: number): Promise<string[]> {
    const rows = await this.db
      .select({ code: roles.code })
      .from(userRoles)
      .innerJoin(roles, eq(roles.id, userRoles.roleId))
      .where(eq(userRoles.userId, userId))
      .orderBy(roles.code);
    return rows.map((r) => r.code);
  }

  async touchLastLogin(userId: number): Promise<void> {
    await this.db
      .update(users)
      .set({ lastLoginAt: new Date(), updatedAt: new Date() })
      .where(eq(users.id, userId));
  }

  private isUniqueViolation(err: unknown): boolean {
    return typeof err === 'object' && err !== null && (err as { code?: string }).code === '23505';
  }
}
