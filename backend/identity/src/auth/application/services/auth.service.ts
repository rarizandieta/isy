import type {
  AuthResult,
  CreateProfileInput,
  LoginInput,
  ProfileList,
  ProfileMutationResult,
  PublicUser,
  RefreshInput,
  RegisterInput,
  RevokedAccess,
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

  /**
   * Revoca una sesión (idempotente). Si se pasa el access token actual, además
   * lo mete en la blocklist para revocación inmediata.
   */
  abstract logout(input: RefreshInput, access?: RevokedAccess): Promise<void>;

  /** Lista los perfiles del usuario e indica cuál está activo. */
  abstract listProfiles(userId: number): Promise<ProfileList>;

  /**
   * Crea un perfil adicional (vendedor / servicios), lo deja activo y re-emite
   * el access token con el nuevo perfil activo.
   */
  abstract createProfile(
    userId: number,
    input: CreateProfileInput,
  ): Promise<ProfileMutationResult>;

  /**
   * Cambia el perfil activo del usuario y re-emite el access token. Lanza si el
   * perfil no existe o no pertenece al usuario.
   */
  abstract switchProfile(userId: number, profileId: number): Promise<ProfileMutationResult>;
}
