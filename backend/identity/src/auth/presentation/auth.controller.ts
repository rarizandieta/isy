import { Body, Controller, Get, HttpCode, Post, Req, UseGuards } from '@nestjs/common';
import type { Request } from 'express';
import type {
  AuthResult,
  PublicUser,
  RevokedAccess,
  SessionMeta,
} from '../application/dto/auth.dto.js';
import { AuthService } from '../application/services/auth.service.js';
import { TokenService } from '../domain/services/token.service.js';
import { LoginDto } from './dto/login.dto.js';
import { RefreshTokenDto } from './dto/refresh.dto.js';
import { RegisterDto } from './dto/register.dto.js';
import { type AuthenticatedRequest, JwtAuthGuard } from './guards/jwt-auth.guard.js';

/**
 * Capa de presentación (HTTP). Traduce peticiones/respuestas hacia el caso de
 * uso (AuthService). No contiene lógica de negocio.
 */
@Controller('auth')
export class AuthController {
  constructor(
    private readonly auth: AuthService,
    private readonly tokens: TokenService,
  ) {}

  /** Registro manual. Devuelve el usuario creado (sin tokens). */
  @Post('register')
  @HttpCode(201)
  register(@Body() dto: RegisterDto): Promise<PublicUser> {
    return this.auth.register(dto);
  }

  /** Login por contraseña. Devuelve access + refresh y el usuario. */
  @Post('login')
  @HttpCode(200)
  login(@Body() dto: LoginDto, @Req() req: Request): Promise<AuthResult> {
    return this.auth.login(dto, this.extractMeta(req));
  }

  /** Usuario actual (requiere access token válido). */
  @UseGuards(JwtAuthGuard)
  @Get('me')
  me(@Req() req: AuthenticatedRequest): Promise<PublicUser> {
    return this.auth.getMe(req.user.sub);
  }

  /** Rota un refresh token y emite un nuevo access token. */
  @Post('refresh')
  @HttpCode(200)
  refresh(@Body() dto: RefreshTokenDto, @Req() req: Request): Promise<AuthResult> {
    return this.auth.refresh(dto, this.extractMeta(req));
  }

  /**
   * Revoca una sesión. Además de invalidar el refresh token, intenta leer el
   * access token del header Authorization para bloquear su jti hasta que expire
   * (blocklist en Redis vía el gateway). La lectura es oportunista: un access
   * token ausente o expirado no impide revocar la sesión.
   */
  @Post('logout')
  @HttpCode(204)
  async logout(@Body() dto: RefreshTokenDto, @Req() req: Request): Promise<void> {
    await this.auth.logout(dto, await this.extractRevokedAccess(req));
  }

  private extractMeta(req: Request): SessionMeta {
    return { userAgent: req.headers['user-agent'], ipAddress: req.ip };
  }

  /**
   * Extrae el jti + expiración del access token (si viene y es válido) para
   * poder añadirlo a la blocklist. Devuelve undefined si no hay token válido.
   */
  private async extractRevokedAccess(req: Request): Promise<RevokedAccess | undefined> {
    const header = req.headers.authorization;
    const token = header?.startsWith('Bearer ') ? header.slice(7) : undefined;
    if (!token) return undefined;
    try {
      const payload = await this.tokens.verifyAccessToken(token);
      if (payload.jti && payload.exp) {
        return { jti: payload.jti, expiresAt: payload.exp };
      }
    } catch {
      // Access token ausente/expirado/ inválido: no bloqueamos nada, pero
      // seguimos revocando el refresh token.
    }
    return undefined;
  }
}
