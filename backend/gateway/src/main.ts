import { randomUUID } from 'node:crypto';
import { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import type { NestExpressApplication } from '@nestjs/platform-express';
import type { NextFunction, Response } from 'express';
import jwt from 'jsonwebtoken';
import { AppModule } from './app.module.js';
import type { AccessClaims, GatewayRequest } from './gateway-context.js';
import { createServiceProxies } from './proxy/create-service-proxies.js';
import { matchRoute, serviceRoutes } from './proxy/service-routes.js';
import { createRateLimitMiddleware } from './security/rate-limit.js';
import { createRedisClient } from './security/redis-client.js';
import { isTokenBlocked } from './security/token-blocklist.js';

/**
 * API Gateway — borde lógico de la plataforma, detrás de nginx.
 *
 * Responsabilidades (sin lógica de dominio):
 *  - Enrutar/hacer proxy hacia cada microservicio (tabla de rutas).
 *  - Autenticación en el borde: las rutas protegidas exigen un access token
 *    válido, que se valida aquí POR FIRMA (sin tocar BD). Los microservicios NO
 *    leen el JWT: reciben la identidad por headers que inyecta el gateway.
 *  - Trazabilidad: genera/propaga `x-correlation-id` a todos los servicios.
 *
 * nginx reenvía todo lo que entra por /api/ a este gateway (sin el prefijo), así
 * que aquí las rutas llegan como /auth/..., /stores/..., /health, etc.
 */

const CORRELATION_HEADER = 'x-correlation-id';
// correlation id "sano": corto y sin caracteres raros (evita inyección en logs).
const CORRELATION_RE = /^[A-Za-z0-9._-]{1,64}$/;
// HS256 por ahora (dev); migrar a RS256 validando con clave pública.
const JWT_SECRET = process.env.JWT_SECRET ?? '';

function extractBearer(header: string | undefined): string | null {
  if (!header) return null;
  const [scheme, value] = header.split(' ');
  return scheme === 'Bearer' && value ? value : null;
}

function unauthorized(res: Response, message: string): void {
  res.status(401).json({ statusCode: 401, message, error: 'Unauthorized' });
}

async function bootstrap() {
  const logger = new Logger('Gateway');
  const routes = serviceRoutes();
  // Redis (efímero): respalda rate-limit + blocklist. Fail-open si no responde.
  const redis = createRedisClient(logger);

  // bodyParser:false -> el cuerpo se reenvía intacto al microservicio destino.
  const app = await NestFactory.create<NestExpressApplication>(AppModule, {
    bodyParser: false,
  });

  // 1) Correlation id (todas las rutas): reusar el del cliente si es válido;
  //    si no, generar uno nuevo. Se devuelve en la respuesta.
  app.use((req: GatewayRequest, res: Response, next: NextFunction) => {
    const incoming = req.headers[CORRELATION_HEADER];
    const candidate = Array.isArray(incoming) ? incoming[0] : incoming;
    const correlationId =
      candidate && CORRELATION_RE.test(candidate) ? candidate : randomUUID();
    req.correlationId = correlationId;
    res.setHeader(CORRELATION_HEADER, correlationId);
    next();
  });

  // 2) Log mínimo del tráfico que entra por el borde.
  app.use((req: GatewayRequest, _res: Response, next: NextFunction) => {
    logger.log(`[${req.correlationId}] ${req.method} ${req.originalUrl}`);
    next();
  });

  // 3) Rate limiting por IP (fail-open): login estricto + límite general.
  app.use(createRateLimitMiddleware(redis, logger));

  // 4) Autorización: valida el access token SOLO en rutas protegidas.
  app.use(async (req: GatewayRequest, res: Response, next: NextFunction) => {
    const route = matchRoute(routes, req.path);
    if (!route || !route.protected) {
      return next();
    }
    const token = extractBearer(req.headers.authorization);
    if (!token) {
      return unauthorized(res, 'Falta el access token.');
    }
    let claims: AccessClaims;
    try {
      claims = jwt.verify(token, JWT_SECRET, { algorithms: ['HS256'] }) as AccessClaims;
    } catch {
      return unauthorized(res, 'Access token inválido o expirado.');
    }
    // Revocación inmediata: el token puede ser válido por firma pero haber sido
    // revocado (logout). La blocklist hace fail-open si Redis no responde.
    if (await isTokenBlocked(redis, claims.jti, logger)) {
      return unauthorized(res, 'Access token revocado.');
    }
    req.auth = claims;
    return next();
  });

  // 5) Un proxy por microservicio, según la tabla de rutas.
  for (const proxy of createServiceProxies(routes, logger)) {
    app.use(proxy);
  }

  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port);
  logger.log(
    `Gateway en :${port}  ->  ${routes
      .map((r) => `${r.prefixes.join(',')} ${r.protected ? '[🔒]' : '[·]'} ${r.target}`)
      .join('   ')}`,
  );
}

await bootstrap();
