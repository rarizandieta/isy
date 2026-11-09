/**
 * Categoría semántica del error de dominio. La capa de presentación (el filtro
 * de excepciones) la traduce al código HTTP correspondiente, de modo que el
 * dominio permanece libre de detalles de transporte (HTTP).
 */
export type DomainErrorKind =
  | 'conflict'
  | 'unauthorized'
  | 'not_found'
  | 'validation'
  | 'forbidden';

/**
 * Error base del dominio. Las reglas de negocio lanzan subclases de este error;
 * nunca excepciones de framework (Nest/HTTP).
 */
export abstract class DomainError extends Error {
  abstract readonly kind: DomainErrorKind;

  protected constructor(message: string) {
    super(message);
    this.name = new.target.name;
  }
}
