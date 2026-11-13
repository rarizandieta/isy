import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import {
  type AccessTokenClaims,
  type AccessTokenPayload,
  TokenService,
} from '../../domain/services/token.service.js';

/**
 * Implementación de TokenService:
 *  - access token: JWT HS256 (vía @nestjs/jwt).
 *  - refresh token: opaco (randomBytes), se persiste solo su hash SHA-256.
 *
 * TODO: migrar el access token a RS256 cuando el gateway valide con la clave
 * pública (identity firma con la privada).
 */
@Injectable()
export class JwtTokenService extends TokenService {
  constructor(private readonly jwt: JwtService) {
    super();
  }

  signAccessToken(claims: AccessTokenClaims, ttlSeconds: number): Promise<string> {
    return this.jwt.signAsync(
      {
        sub: claims.sub,
        email: claims.email,
        roles: claims.roles,
        // Perfil activo: el gateway lo propaga a los microservicios por headers.
        profileId: claims.profileId,
        profileType: claims.profileType,
      },
      // jwtid -> claim `jti`: identifica el token para poder revocarlo (blocklist).
      { expiresIn: ttlSeconds, jwtid: randomUUID() },
    );
  }

  verifyAccessToken(token: string): Promise<AccessTokenPayload> {
    return this.jwt.verifyAsync<AccessTokenPayload>(token, { algorithms: ['HS256'] });
  }

  generateRefreshToken(): string {
    return randomBytes(32).toString('hex');
  }

  hashRefreshToken(token: string): string {
    return createHash('sha256').update(token).digest('hex');
  }
}
