import type { Logger } from '@nestjs/common';
import type { NextFunction, RequestHandler, Response } from 'express';
import type { Redis } from 'ioredis';
import type { GatewayRequest } from '../gateway-context.js';

/**
 * Rate limiting en el borde (por IP), respaldado por Redis.
 *
 * Diseño:
 *  - Ventana fija por bucket: `INCR` + `EXPIRE` atómico (script Lua). La primera
 *    petición de la ventana fija el TTL; al expirar, el contador se reinicia.
 *  - Reglas en orden: a una petición le aplican TODAS las que casen. El login
 *    (público y sensible a fuerza bruta) lleva un límite estricto además del
 *    límite general.
 *  - FAIL-OPEN: si Redis no responde, se deja pasar. Preferimos disponibilidad a
 *    bloquear tráfico legítimo cuando la infraestructura de apoyo falla.
 */

interface RateLimitRule {
  /** Prefijo de la clave en Redis (identifica el bucket). */
  bucket: string;
  /** Máximo de peticiones por ventana. */
  limit: number;
  /** Tamaño de la ventana, en segundos. */
  windowSeconds: number;
  /** ¿Esta petición cuenta para este bucket? */
  applies: (req: GatewayRequest) => boolean;
}

// INCR + EXPIRE en una sola llamada atómica (evita condiciones de carrera entre
// el incremento y el fijado del TTL).
const INCR_WITH_TTL = `
local current = redis.call('INCR', KEYS[1])
if current == 1 then
  redis.call('EXPIRE', KEYS[1], ARGV[1])
end
return current
`;

const RULES: RateLimitRule[] = [
  {
    // Antifuerza bruta: el login es público y es el objetivo típico.
    bucket: 'login',
    limit: 5,
    windowSeconds: 60,
    applies: (req) => req.method === 'POST' && req.path === '/auth/login',
  },
  {
    // Límite general por IP para todo el tráfico del borde.
    bucket: 'gen',
    limit: 120,
    windowSeconds: 60,
    applies: () => true,
  },
];

/** IP del cliente real (detrás de nginx: X-Real-IP / X-Forwarded-For). */
function clientIp(req: GatewayRequest): string {
  const realIp = req.headers['x-real-ip'];
  if (typeof realIp === 'string' && realIp.trim().length > 0) {
    return realIp.trim();
  }
  const xff = req.headers['x-forwarded-for'];
  const firstHop = Array.isArray(xff) ? xff[0] : xff?.split(',')[0];
  if (firstHop && firstHop.trim().length > 0) {
    return firstHop.trim();
  }
  return req.socket.remoteAddress ?? 'unknown';
}

function tooManyRequests(res: Response, retryAfterSeconds: number): void {
  res.setHeader('Retry-After', String(retryAfterSeconds));
  res.status(429).json({
    statusCode: 429,
    message: 'Demasiadas peticiones. Inténtalo más tarde.',
    error: 'Too Many Requests',
  });
}

export function createRateLimitMiddleware(redis: Redis, logger: Logger): RequestHandler {
  return (req: GatewayRequest, res: Response, next: NextFunction): void => {
    const ip = clientIp(req);
    const applicable = RULES.filter((rule) => rule.applies(req));

    void (async () => {
      try {
        for (const rule of applicable) {
          const key = `rl:${rule.bucket}:${ip}`;
          const count = (await redis.eval(
            INCR_WITH_TTL,
            1,
            key,
            String(rule.windowSeconds),
          )) as number;

          if (count > rule.limit) {
            const ttl = await redis.ttl(key);
            logger.warn(`rate-limit ${rule.bucket} excedido por ${ip} (${count}/${rule.limit})`);
            tooManyRequests(res, ttl > 0 ? ttl : rule.windowSeconds);
            return;
          }
        }
        next();
      } catch (err) {
        // fail-open: si Redis no está disponible, no bloqueamos el tráfico.
        logger.warn(`rate-limit fail-open: ${(err as Error).message}`);
        next();
      }
    })();
  };
}
