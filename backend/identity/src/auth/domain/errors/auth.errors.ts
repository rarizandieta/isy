import { DomainError, type DomainErrorKind } from '../../../shared/domain/domain-error.js';

/** El correo ya está registrado (registro). */
export class EmailAlreadyRegisteredError extends DomainError {
  readonly kind: DomainErrorKind = 'conflict';
  constructor() {
    super('Email already registered');
  }
}

/** Credenciales inválidas (login). Mensaje genérico: no revela si el correo existe. */
export class InvalidCredentialsError extends DomainError {
  readonly kind: DomainErrorKind = 'unauthorized';
  constructor() {
    super('Invalid credentials');
  }
}

/** Refresh token inválido, revocado o expirado. */
export class InvalidRefreshTokenError extends DomainError {
  readonly kind: DomainErrorKind = 'unauthorized';
  constructor() {
    super('Invalid or expired refresh token');
  }
}

/** El usuario autenticado ya no existe. */
export class UserNotFoundError extends DomainError {
  readonly kind: DomainErrorKind = 'unauthorized';
  constructor() {
    super('User not found');
  }
}
