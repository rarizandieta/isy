import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { QueryFailedError } from 'typeorm';

type PgDriverError = {
  code?: string;
  constraint?: string;
  detail?: string;
};

@Catch(QueryFailedError)
export class DatabaseExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(DatabaseExceptionFilter.name);

  catch(exception: QueryFailedError, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse();
    const request = ctx.getRequest<{ method: string; url: string }>();
    const error = (exception as { driverError?: PgDriverError }).driverError;

    const mapped = this.mapDatabaseError(error);
    this.logger.error(
      `DB error on ${request.method} ${request.url}: ${mapped.message}`,
      exception.stack,
    );

    response.status(mapped.statusCode).json({
      statusCode: mapped.statusCode,
      message: mapped.message,
      error: mapped.error,
    });
  }

  private mapDatabaseError(error?: PgDriverError): {
    statusCode: number;
    error: string;
    message: string;
  } {
    if (!error?.code) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        error: 'Internal Server Error',
        message: 'Ocurrió un error inesperado en base de datos.',
      };
    }

    if (error.code === '23505') {
      const byConstraint: Record<string, string> = {
        mini_stores_slug_key: 'Ya existe una tienda con ese slug.',
        uq_store_sections_name:
          'Ya existe una sección con ese nombre para esta tienda.',
        uq_store_sections_position:
          'Ya existe una sección en esa posición para esta tienda.',
        uq_media_asset_variant:
          'Esa variante de imagen ya existe para el asset indicado.',
        uq_media_storage_object:
          'Ese objeto de storage ya existe. Reintenta con otro nombre.',
      };

      return {
        statusCode: HttpStatus.CONFLICT,
        error: 'Conflict',
        message:
          byConstraint[error.constraint ?? ''] ??
          'No se pudo completar porque el registro ya existe.',
      };
    }

    if (error.code === '23503') {
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        error: 'Bad Request',
        message:
          'No se pudo completar por referencia inválida (por ejemplo categoría, sección o unidad no existente).',
      };
    }

    if (error.code === '23514') {
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        error: 'Bad Request',
        message:
          'No se pudo completar porque una validación de negocio en base de datos fue violada.',
      };
    }

    return {
      statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
      error: 'Internal Server Error',
      message: 'Error de base de datos no controlado.',
    };
  }
}
