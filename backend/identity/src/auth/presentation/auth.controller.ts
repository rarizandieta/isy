import { Body, Controller, Get, HttpCode, Post, Req, UseGuards } from '@nestjs/common';
import type { Request } from 'express';
import type { AuthResult, PublicUser, SessionMeta } from '../application/dto/auth.dto.js';
import { AuthService } from '../application/services/auth.service.js';
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
  constructor(private readonly auth: AuthService) {}

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

  /** Revoca una sesión. */
  @Post('logout')
  @HttpCode(204)
  logout(@Body() dto: RefreshTokenDto): Promise<void> {
    return this.auth.logout(dto);
  }

  private extractMeta(req: Request): SessionMeta {
    return { userAgent: req.headers['user-agent'], ipAddress: req.ip };
  }
}
