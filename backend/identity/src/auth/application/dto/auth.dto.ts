/**
 * DTOs de la capa de aplicación: contratos de entrada/salida de los casos de
 * uso, independientes del transporte (HTTP) y de la base de datos.
 */

// --- Entradas (casos de uso) ---
export interface RegisterInput {
  fullName: string;
  email: string;
  password: string;
}

export interface LoginInput {
  email: string;
  password: string;
}

export interface RefreshInput {
  refreshToken: string;
}

/** Metadatos de la petición asociados a la sesión. */
export interface SessionMeta {
  userAgent?: string;
  ipAddress?: string;
}

// --- Salidas ---
export interface PublicUser {
  id: number;
  email: string;
  fullName: string;
  roles: string[];
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  tokenType: 'Bearer';
  /** Vida del access token en segundos. */
  expiresIn: number;
}

export type AuthResult = AuthTokens & { user: PublicUser };
