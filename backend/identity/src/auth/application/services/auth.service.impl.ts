import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { User } from '../../domain/entities/user.entity.js';
import {
  EmailAlreadyRegisteredError,
  InvalidCredentialsError,
  InvalidRefreshTokenError,
  UserNotFoundError,
} from '../../domain/errors/auth.errors.js';
import { SessionRepository } from '../../domain/repositories/session.repository.js';
import { UserRepository } from '../../domain/repositories/user.repository.js';
import { PasswordHasher } from '../../domain/services/password-hasher.js';
import { TokenService } from '../../domain/services/token.service.js';
import type {
  AuthResult,
  AuthTokens,
  LoginInput,
  PublicUser,
  RefreshInput,
  RegisterInput,
  SessionMeta,
} from '../dto/auth.dto.js';
import { AuthService } from './auth.service.js';

/** Rol con el que nace todo usuario. */
const DEFAULT_ROLE = 'buyer';

/**
 * Implementación del caso de uso de autenticación. Orquesta los puertos
 * (repositorios y servicios de dominio); no conoce Drizzle, bcrypt ni JWT
 * directamente.
 */
@Injectable()
export class AuthServiceImpl extends AuthService {
  constructor(
    private readonly users: UserRepository,
    private readonly sessions: SessionRepository,
    private readonly hasher: PasswordHasher,
    private readonly tokens: TokenService,
    private readonly config: ConfigService,
  ) {
    super();
  }

  async register(input: RegisterInput): Promise<PublicUser> {
    const email = this.normalizeEmail(input.email);

    if (await this.users.existsByEmail(email)) {
      throw new EmailAlreadyRegisteredError();
    }

    const passwordHash = await this.hasher.hash(input.password);
    const user = await this.users.createWithPassword({
      fullName: input.fullName,
      email,
      passwordHash,
      roleCode: DEFAULT_ROLE,
    });

    return { id: user.id, email: user.email, fullName: user.fullName, roles: [DEFAULT_ROLE] };
  }

  async login(input: LoginInput, meta: SessionMeta): Promise<AuthResult> {
    const email = this.normalizeEmail(input.email);
    const creds = await this.users.findCredentialsByEmail(email);

    // Mensaje genérico: no revela si el correo existe.
    if (
      !creds?.passwordHash ||
      !(await this.hasher.compare(input.password, creds.passwordHash))
    ) {
      throw new InvalidCredentialsError();
    }

    const roles = await this.users.findRoleCodes(creds.user.id);
    const tokens = await this.issueTokens(creds.user, roles, meta);
    await this.users.touchLastLogin(creds.user.id);

    return { ...tokens, user: this.toPublicUser(creds.user, roles) };
  }

  async getMe(userId: number): Promise<PublicUser> {
    const user = await this.users.findById(userId);
    if (!user) {
      throw new UserNotFoundError();
    }
    const roles = await this.users.findRoleCodes(userId);
    return this.toPublicUser(user, roles);
  }

  async refresh(input: RefreshInput, meta: SessionMeta): Promise<AuthResult> {
    const tokenHash = this.tokens.hashRefreshToken(input.refreshToken);
    const session = await this.sessions.findActiveByTokenHash(tokenHash);
    if (!session) {
      throw new InvalidRefreshTokenError();
    }

    const user = await this.users.findById(session.userId);
    if (!user) {
      throw new InvalidRefreshTokenError();
    }

    const roles = await this.users.findRoleCodes(user.id);

    // Rotación: reemplaza el hash almacenado y desliza last_used_at.
    const newRefreshToken = this.tokens.generateRefreshToken();
    await this.sessions.rotate(session.id, {
      refreshTokenHash: this.tokens.hashRefreshToken(newRefreshToken),
      userAgent: meta.userAgent ?? session.userAgent,
      ipAddress: meta.ipAddress ?? session.ipAddress,
    });

    const accessTtl = this.accessTtl();
    const accessToken = await this.tokens.signAccessToken(
      { sub: user.id, email: user.email, roles },
      accessTtl,
    );

    return {
      accessToken,
      refreshToken: newRefreshToken,
      tokenType: 'Bearer',
      expiresIn: accessTtl,
      user: this.toPublicUser(user, roles),
    };
  }

  async logout(input: RefreshInput): Promise<void> {
    const tokenHash = this.tokens.hashRefreshToken(input.refreshToken);
    await this.sessions.revokeByTokenHash(tokenHash);
  }

  // --- helpers --------------------------------------------------------------

  private async issueTokens(
    user: User,
    roles: string[],
    meta: SessionMeta,
  ): Promise<AuthTokens> {
    const accessTtl = this.accessTtl();
    const refreshTtl = this.refreshTtl();

    const accessToken = await this.tokens.signAccessToken(
      { sub: user.id, email: user.email, roles },
      accessTtl,
    );
    const refreshToken = this.tokens.generateRefreshToken();

    await this.sessions.create({
      userId: user.id,
      refreshTokenHash: this.tokens.hashRefreshToken(refreshToken),
      userAgent: meta.userAgent,
      ipAddress: meta.ipAddress,
      expiresAt: new Date(Date.now() + refreshTtl * 1000),
    });

    return { accessToken, refreshToken, tokenType: 'Bearer', expiresIn: accessTtl };
  }

  private toPublicUser(user: User, roles: string[]): PublicUser {
    return { id: user.id, email: user.email, fullName: user.fullName, roles };
  }

  private accessTtl(): number {
    return this.config.getOrThrow<number>('ACCESS_TTL');
  }

  private refreshTtl(): number {
    return this.config.getOrThrow<number>('REFRESH_TTL');
  }

  private normalizeEmail(email: string): string {
    return email.trim().toLowerCase();
  }
}
