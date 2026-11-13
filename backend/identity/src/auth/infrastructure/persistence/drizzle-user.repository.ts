import { Inject, Injectable } from '@nestjs/common';
import { and, desc, eq, sql } from 'drizzle-orm';
import { DRIZZLE } from '../../../database/database.constants.js';
import type { Database } from '../../../database/database.module.js';
import { authIdentities, profiles, roles, userRoles, users } from '../../../database/schema.js';
import { Profile, type ProfileType } from '../../domain/entities/profile.entity.js';
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

        // Perfil inicial (por defecto): el que viajará en el access token.
        await tx.insert(profiles).values({
          userId: user.id,
          type: data.profileType,
          isDefault: true,
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

  async findActiveProfile(userId: number): Promise<Profile | null> {
    const [row] = await this.db
      .select({
        id: profiles.id,
        userId: profiles.userId,
        type: profiles.type,
        isDefault: profiles.isDefault,
        displayName: profiles.displayName,
      })
      .from(profiles)
      .where(eq(profiles.userId, userId))
      // El perfil por defecto primero; si no lo hubiera, el más antiguo.
      .orderBy(desc(profiles.isDefault), profiles.id)
      .limit(1);
    if (!row) return null;
    return new Profile(row.id, row.userId, row.type as ProfileType, row.isDefault, row.displayName);
  }

  async listProfiles(userId: number): Promise<Profile[]> {
    const rows = await this.db
      .select({
        id: profiles.id,
        userId: profiles.userId,
        type: profiles.type,
        isDefault: profiles.isDefault,
        displayName: profiles.displayName,
      })
      .from(profiles)
      .where(eq(profiles.userId, userId))
      .orderBy(profiles.id);
    return rows.map(
      (r) => new Profile(r.id, r.userId, r.type as ProfileType, r.isDefault, r.displayName),
    );
  }

  async createProfile(userId: number, type: ProfileType, displayName: string): Promise<Profile> {
    return this.db.transaction(async (tx) => {
      // ¿Ya tiene un perfil de ese tipo? No duplicamos (unique user_id+type).
      const [existing] = await tx
        .select({
          id: profiles.id,
          type: profiles.type,
          displayName: profiles.displayName,
        })
        .from(profiles)
        .where(and(eq(profiles.userId, userId), eq(profiles.type, type)))
        .limit(1);

      let profileId: number;
      let resolvedType: ProfileType;
      let resolvedName: string | null;

      if (existing) {
        profileId = existing.id;
        resolvedType = existing.type as ProfileType;
        resolvedName = existing.displayName;
      } else {
        // Otorga el rol correspondiente (seller / service_provider), idempotente.
        const [role] = await tx
          .select({ id: roles.id })
          .from(roles)
          .where(eq(roles.code, type))
          .limit(1);
        if (role) {
          await tx
            .insert(userRoles)
            .values({ userId, roleId: role.id, createdBy: userId, updatedBy: userId })
            .onConflictDoNothing();
        }

        const [created] = await tx
          .insert(profiles)
          .values({
            userId,
            type,
            displayName,
            isDefault: false,
            createdBy: userId,
            updatedBy: userId,
          })
          .returning({
            id: profiles.id,
            type: profiles.type,
            displayName: profiles.displayName,
          });
        profileId = created.id;
        resolvedType = created.type as ProfileType;
        resolvedName = created.displayName;
      }

      // Activar: primero desmarcamos el default actual (por el índice único
      // parcial "un default por usuario"), luego marcamos este.
      await tx
        .update(profiles)
        .set({ isDefault: false, updatedAt: new Date(), updatedBy: userId })
        .where(and(eq(profiles.userId, userId), eq(profiles.isDefault, true)));
      await tx
        .update(profiles)
        .set({ isDefault: true, updatedAt: new Date(), updatedBy: userId })
        .where(eq(profiles.id, profileId));

      return new Profile(profileId, userId, resolvedType, true, resolvedName);
    });
  }

  async activateProfile(userId: number, profileId: number): Promise<boolean> {
    return this.db.transaction(async (tx) => {
      const [owned] = await tx
        .select({ id: profiles.id })
        .from(profiles)
        .where(and(eq(profiles.id, profileId), eq(profiles.userId, userId)))
        .limit(1);
      if (!owned) return false;

      // Un único default por usuario: desmarcar el anterior y marcar este.
      await tx
        .update(profiles)
        .set({ isDefault: false, updatedAt: new Date(), updatedBy: userId })
        .where(and(eq(profiles.userId, userId), eq(profiles.isDefault, true)));
      await tx
        .update(profiles)
        .set({ isDefault: true, updatedAt: new Date(), updatedBy: userId })
        .where(eq(profiles.id, profileId));
      return true;
    });
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
