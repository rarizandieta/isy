import type { ServerResponse } from 'node:http';
import type { Logger } from '@nestjs/common';
import { createProxyMiddleware, type RequestHandler } from 'http-proxy-middleware';
import type { GatewayRequest } from '../gateway-context.js';
import { type ServiceRoute, routeMatchesPath } from './service-routes.js';

/**
 * Headers de identidad que SOLO puede fijar el gateway (a partir del token
 * validado). Se eliminan de la petición entrante para que un cliente no pueda
 * falsificarlos (anti-spoofing).
 */
const IDENTITY_HEADERS = ['x-user-id', 'x-profile-id', 'x-profile-type'];

/**
 * Construye un middleware de reverse proxy por cada servicio de la tabla de
 * rutas. Preserva la ruta completa y, en cada reenvío:
 *  - propaga `x-correlation-id` (trazabilidad),
 *  - sanea los headers de identidad que venga del cliente,
 *  - en rutas protegidas, inyecta `x-user-id` desde el token validado y quita
 *    el `Authorization` (el microservicio no necesita el JWT: confía en el
 *    contexto del gateway).
 */
export function createServiceProxies(
  routes: ServiceRoute[],
  logger: Logger,
): RequestHandler[] {
  return routes.map((route) =>
    createProxyMiddleware({
      target: route.target,
      changeOrigin: true,
      pathFilter: (pathname) => routeMatchesPath(route, pathname),
      on: {
        proxyReq: (proxyReq, req) => {
          const gReq = req as unknown as GatewayRequest;

          // Trazabilidad: siempre propagamos el correlation id.
          if (gReq.correlationId) {
            proxyReq.setHeader('x-correlation-id', gReq.correlationId);
          }

          // Anti-spoofing: nunca confiar en headers de identidad del cliente.
          for (const header of IDENTITY_HEADERS) {
            proxyReq.removeHeader(header);
          }

          if (route.protected) {
            // La identidad la fija el gateway desde el token ya validado.
            if (gReq.auth?.sub != null) {
              proxyReq.setHeader('x-user-id', String(gReq.auth.sub));
            }
            // Perfil activo del usuario (emitido por identity dentro del token):
            // ministores lo usa para saber "en calidad de qué" actúa el usuario.
            if (gReq.auth?.profileId != null) {
              proxyReq.setHeader('x-profile-id', String(gReq.auth.profileId));
            }
            if (gReq.auth?.profileType) {
              proxyReq.setHeader('x-profile-type', String(gReq.auth.profileType));
            }

            // Defensa en profundidad: el microservicio protegido no necesita el
            // JWT (usa los headers del gateway); no le reenviamos credenciales.
            proxyReq.removeHeader('authorization');
          }
        },
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
    }),
  );
}
