import type { Request } from 'express';

/** Claims del access token que nos interesan en el borde. */
export interface AccessClaims {
  /** Subject: id del usuario. */
  sub: number | string;
  email?: string;
  roles?: string[];
  /** Perfil activo: el gateway lo propaga como x-profile-id. */
  profileId?: number | string;
  /** Tipo del perfil activo: el gateway lo propaga como x-profile-type. */
  profileType?: string;
  /** JWT id: permite revocar el token vía blocklist (Redis). */
  jti?: string;
  /** Expiración (segundos epoch). */
  exp?: number;
}

/**
 * Request aumentada con el contexto que inyecta el gateway:
 * - `correlationId`: id de trazabilidad (se propaga a los microservicios).
 * - `auth`: claims del access token ya validado (solo en rutas protegidas).
 */
export interface GatewayRequest extends Request {
  correlationId?: string;
  auth?: AccessClaims;
}
