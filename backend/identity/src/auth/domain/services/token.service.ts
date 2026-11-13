/** Claims que viaja el access token. */
export interface AccessTokenClaims {
  /** Subject: el id del usuario. */
  sub: number;
  email: string;
  roles: string[];
  /** Id del perfil activo (el gateway lo propaga como x-profile-id). */
  profileId?: number;
  /** Tipo del perfil activo (el gateway lo propaga como x-profile-type). */
  profileType?: string;
}

/** Payload decodificado del access token (claims + marcas de tiempo del JWT). */
export interface AccessTokenPayload extends AccessTokenClaims {
  /** JWT id único (para revocación vía blocklist). */
  jti?: string;
  iat?: number;
  exp?: number;
}

/**
 * Puerto para la emisión/verificación de tokens. La implementación concreta
 * (JWT HS256 hoy, RS256 a futuro) vive en infraestructura.
 */
export abstract class TokenService {
  /** Firma un access token con el TTL dado (segundos). */
  abstract signAccessToken(claims: AccessTokenClaims, ttlSeconds: number): Promise<string>;

  /** Verifica y decodifica un access token. Lanza si es inválido/expirado. */
  abstract verifyAccessToken(token: string): Promise<AccessTokenPayload>;

  /** Genera un refresh token opaco (sin estado). */
  abstract generateRefreshToken(): string;

  /** Hash determinista del refresh token (lo que se persiste, nunca el token). */
  abstract hashRefreshToken(token: string): string;
}
