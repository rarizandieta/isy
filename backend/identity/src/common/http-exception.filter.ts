import {
  type ArgumentsHost,
  Catch,
  type ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import type { Request, Response } from 'express';
import { DomainError, type DomainErrorKind } from '../shared/domain/domain-error.js';

/** Traducción de la categoría de error de dominio al código HTTP. */
const KIND_TO_STATUS: Record<DomainErrorKind, HttpStatus> = {
  conflict: HttpStatus.CONFLICT, // 409
  unauthorized: HttpStatus.UNAUTHORIZED, // 401
  not_found: HttpStatus.NOT_FOUND, // 404
  validation: HttpStatus.BAD_REQUEST, // 400
  forbidden: HttpStatus.FORBIDDEN, // 403
};

/**
 * Filtro catch-all que renderiza todos los errores con el mismo envelope JSON.
 *  - DomainError: se mapea por su `kind` al código HTTP (el dominio no conoce HTTP).
 *  - HttpException conocida: conserva su status/mensaje.
 *  - Cualquier otra cosa: 500 genérico (sin filtrar stack traces al cliente).
 */
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger('ExceptionFilter');

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    // --- Errores de dominio: mapear la categoría semántica a HTTP ---
    if (exception instanceof DomainError) {
      const status = KIND_TO_STATUS[exception.kind];
      response.status(status).json({
        statusCode: status,
        message: exception.message,
        error: exception.name,
        path: request.url,
        timestamp: new Date().toISOString(),
      });
      return;
    }

    const isHttp = exception instanceof HttpException;
    const status = isHttp ? exception.getStatus() : HttpStatus.INTERNAL_SERVER_ERROR;
    const raw = isHttp ? exception.getResponse() : 'Internal server error';

    const body =
      typeof raw === 'object' && raw !== null
        ? (raw as Record<string, unknown>)
        : { message: raw };

    if (!isHttp || status >= HttpStatus.INTERNAL_SERVER_ERROR) {
      this.logger.error(
        `${request.method} ${request.url} -> ${status}`,
        exception instanceof Error ? exception.stack : String(exception),
      );
    }

    response.status(status).json({
      statusCode: status,
      ...body,
      path: request.url,
      timestamp: new Date().toISOString(),
    });
  }
}
