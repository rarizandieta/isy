import type { ServerResponse } from 'node:http';
import type { Logger } from '@nestjs/common';
import { createProxyMiddleware, type RequestHandler } from 'http-proxy-middleware';
import type { ServiceRoute } from './service-routes.js';

/**
 * Construye un middleware de reverse proxy por cada servicio de la tabla de
 * rutas. Cada proxy reenvía (preservando la ruta completa) las peticiones cuyo
 * path cae bajo alguno de los prefijos del servicio.
 */
export function createServiceProxies(
  routes: ServiceRoute[],
  logger: Logger,
): RequestHandler[] {
  return routes.map((route) => {
    const belongsToRoute = (pathname: string): boolean =>
      route.prefixes.some((p) => pathname === p || pathname.startsWith(`${p}/`));

    return createProxyMiddleware({
      target: route.target,
      changeOrigin: true,
      pathFilter: (pathname) => belongsToRoute(pathname),
      on: {
        error: (err, _req, res) => {
          logger.error(`${route.name} proxy error: ${err.message}`);
          // res puede ser un Socket (WebSocket upgrade); solo manejamos HTTP.
          if ('writeHead' in res) {
            const httpRes = res as ServerResponse;
            if (!httpRes.headersSent) {
              httpRes.writeHead(502, { 'Content-Type': 'application/json' });
            }
            httpRes.end(
              JSON.stringify({
                statusCode: 502,
                message: `${route.name} no disponible`,
              }),
            );
          }
        },
      },
    });
  });
}
