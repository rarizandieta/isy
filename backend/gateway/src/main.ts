import { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import type { NestExpressApplication } from '@nestjs/platform-express';
import type { NextFunction, Request, Response } from 'express';
import { AppModule } from './app.module.js';
import { createServiceProxies } from './proxy/create-service-proxies.js';
import { serviceRoutes } from './proxy/service-routes.js';

/**
 * API Gateway — borde lógico de la plataforma, detrás de nginx.
 *
 * Es un componente de borde (infraestructura), NO un servicio de dominio: su
 * única responsabilidad es enrutar/hacer proxy hacia los microservicios y, a
 * futuro, resolver preocupaciones transversales (validación de JWT, rate-limit,
 * agregación). Por eso se mantiene delgado y organizado por responsabilidad,
 * sin capas de Clean Architecture (no hay entidades ni casos de uso aquí).
 *
 * nginx reenvía todo lo que entra por /api/ a este gateway (sin el prefijo), así
 * que aquí las rutas llegan como /auth/..., /health, etc.
 */
async function bootstrap() {
  const logger = new Logger('Gateway');

  // bodyParser:false -> el cuerpo de las peticiones se reenvía intacto al
  // microservicio destino (si Nest lo parsea primero, el proxy no podría
  // retransmitir el stream del body).
  const app = await NestFactory.create<NestExpressApplication>(AppModule, {
    bodyParser: false,
  });

  // Log mínimo del tráfico que entra por el borde (útil en desarrollo).
  app.use((req: Request, _res: Response, next: NextFunction) => {
    logger.log(`${req.method} ${req.originalUrl}`);
    next();
  });

  // Un proxy por microservicio, según la tabla de rutas.
  const routes = serviceRoutes();
  for (const proxy of createServiceProxies(routes, logger)) {
    app.use(proxy);
  }

  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port);
  logger.log(
    `Gateway en :${port}  ->  ${routes
      .map((r) => `${r.prefixes.join(',')} ⇒ ${r.target}`)
      .join('   ')}`,
  );
}

await bootstrap();
