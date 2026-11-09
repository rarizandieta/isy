import type {
  AuthResult,
  LoginInput,
  PublicUser,
  RefreshInput,
  RegisterInput,
  SessionMeta,
} from '../dto/auth.dto.js';

/**
 * Puerto del servicio de autenticación (caso de uso). La presentación depende
 * de esta abstracción; la implementación concreta vive en AuthServiceImpl.
 */
export abstract class AuthService {
  /** Registro manual. Crea el usuario (activo) + identidad de contraseña + rol buyer. */
  abstract register(input: RegisterInput): Promise<PublicUser>;

  /** Login por contraseña. Emite access + refresh y abre una sesión. */
  abstract login(input: LoginInput, meta: SessionMeta): Promise<AuthResult>;

  /** Usuario actual a partir de un access token válido. */
  abstract getMe(userId: number): Promise<PublicUser>;

  /** Rota un refresh token válido y emite un nuevo access. */
  abstract refresh(input: RefreshInput, meta: SessionMeta): Promise<AuthResult>;

  /** Revoca una sesión (idempotente). */
  abstract logout(input: RefreshInput): Promise<void>;
}
