import type { Profile, ProfileType } from '../entities/profile.entity.js';
import type { User } from '../entities/user.entity.js';

/** Datos para crear un usuario con identidad de contraseña y un rol inicial. */
export interface NewUserWithPassword {
  fullName: string;
  /** Correo ya normalizado (minúsculas). */
  email: string;
  passwordHash: string;
  /** Código del rol inicial a asignar (p. ej. 'buyer'). */
  roleCode: string;
  /** Tipo del perfil inicial (por defecto), p. ej. 'buyer'. */
  profileType: ProfileType;
}

/** Credenciales de acceso de un usuario (para el login por contraseña). */
export interface UserCredentials {
  user: User;
  /** Null si el usuario no tiene identidad de contraseña. */
  passwordHash: string | null;
}

/**
 * Puerto de persistencia de usuarios (lo implementa la capa de infraestructura).
 * Devuelve entidades de dominio, nunca filas de la base de datos.
 */
export abstract class UserRepository {
  /** ¿Existe un usuario con ese correo (case-insensitive)? */
  abstract existsByEmail(email: string): Promise<boolean>;

  /**
   * Crea, de forma atómica, el usuario + su identidad de contraseña + la
   * asignación del rol inicial. Debe lanzar EmailAlreadyRegisteredError si viola
   * la unicidad del correo.
   */
  abstract createWithPassword(data: NewUserWithPassword): Promise<User>;

  abstract findById(id: number): Promise<User | null>;

  /** Busca credenciales por correo (incluye el hash de contraseña). */
  abstract findCredentialsByEmail(email: string): Promise<UserCredentials | null>;

  /** Códigos de rol del usuario, ordenados. */
  abstract findRoleCodes(userId: number): Promise<string[]>;

  /**
   * Perfil activo del usuario (el marcado por defecto). Devuelve null si el
   * usuario aún no tiene perfiles. Lo usa el emisor de tokens para incluir el
   * perfil activo en el access token.
   */
  abstract findActiveProfile(userId: number): Promise<Profile | null>;

  /** Todos los perfiles del usuario, ordenados por id. */
  abstract listProfiles(userId: number): Promise<Profile[]>;

  /**
   * Crea un perfil del tipo dado y lo deja como activo (por defecto); otorga el
   * rol correspondiente (seller/service_provider). Si ya existe un perfil de ese
   * tipo, no lo duplica: simplemente lo activa. Operación atómica.
   */
  abstract createProfile(
    userId: number,
    type: ProfileType,
    displayName: string,
  ): Promise<Profile>;

  /**
   * Marca un perfil del usuario como activo (por defecto). Devuelve false si el
   * perfil no existe o no pertenece al usuario. Operación atómica.
   */
  abstract activateProfile(userId: number, profileId: number): Promise<boolean>;

  /** Marca la última fecha de inicio de sesión. */
  abstract touchLastLogin(userId: number): Promise<void>;
}
