import {
  type CanActivate,
  type ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import type { Request } from 'express';
import { type AccessTokenPayload, TokenService } from '../../domain/services/token.service.js';

/** Request aumentada con el payload del access token autenticado. */
export interface AuthenticatedRequest extends Request {
  user: AccessTokenPayload;
}

/**
 * Valida la cabecera `Authorization: Bearer <access>`. El access token se
 * verifica solo por firma (sin round-trip a BD) usando el TokenService, y los
 * claims decodificados se adjuntan a `request.user`.
 */
@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(private readonly tokens: TokenService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const token = this.extractBearerToken(request.headers.authorization);

    if (!token) {
      throw new UnauthorizedException('Missing or malformed Authorization header');
    }

    try {
      request.user = await this.tokens.verifyAccessToken(token);
      return true;
    } catch {
      throw new UnauthorizedException('Invalid or expired token');
    }
  }

  private extractBearerToken(header: string | undefined): string | null {
    if (!header) return null;
    const [scheme, value] = header.split(' ');
    return scheme === 'Bearer' && value ? value : null;
  }
}
