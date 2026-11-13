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

/** Access token a revocar en el logout (para la blocklist). */
export interface RevokedAccess {
  jti: string;
  /** Expiración del access token, en segundos epoch (claim `exp`). */
  expiresAt: number;
}

/** Metadatos de la petición asociados a la sesión. */
export interface SessionMeta {
  userAgent?: string;
  ipAddress?: string;
}

/** Datos para crear un perfil adicional (vendedor / prestador de servicios). */
export interface CreateProfileInput {
  /** Solo se pueden crear 'seller' o 'service_provider' (buyer nace al registrarse). */
  type: 'seller' | 'service_provider';
  displayName: string;
}

/** Vista de un perfil del usuario. */
export interface ProfileView {
  id: number;
  type: string;
  displayName: string | null;
  /** true si es el perfil activo (el que viaja en el access token). */
  isActive: boolean;
}

/** Listado de perfiles + cuál está activo. */
export interface ProfileList {
  profiles: ProfileView[];
  activeProfileId: number | null;
}

/**
 * Resultado de crear o cambiar de perfil activo. Incluye un NUEVO access token
 * (el perfil activo cambió, así que el token anterior ya no refleja el perfil);
 * el cliente debe reemplazar el access token con este.
 */
export interface ProfileMutationResult {
  accessToken: string;
  tokenType: 'Bearer';
  /** Vida del nuevo access token, en segundos. */
  expiresIn: number;
  profiles: ProfileView[];
  activeProfileId: number | null;
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
