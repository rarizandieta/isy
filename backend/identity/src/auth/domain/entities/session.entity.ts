/**
 * Entidad de dominio Sesión: representa una sesión de refresh abierta por el
 * usuario. El token de refresh nunca se guarda en claro (solo su hash), por eso
 * no forma parte de la entidad.
 */
export class Session {
  constructor(
    public readonly id: number,
    public readonly userId: number,
    public readonly expiresAt: Date,
    public readonly revokedAt: Date | null,
    public readonly userAgent: string | null,
    public readonly ipAddress: string | null,
  ) {}
}
