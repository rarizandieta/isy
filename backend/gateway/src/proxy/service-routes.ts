/**
 * Tabla de enrutado del gateway.
 *
 * El API Gateway NO tiene lógica de dominio: solo sabe qué prefijos de ruta
 * pertenecen a cada microservicio, a qué destino reenviarlos y si exigen un
 * access token válido. Agregar un servicio nuevo es añadir una entrada aquí.
 */
export interface ServiceRoute {
  /** Nombre del servicio (para logs y mensajes de error). */
  name: string;
  /** URL base del microservicio en la red interna de Docker. */
  target: string;
  /** Prefijos de ruta que se reenvían a ese servicio. */
  prefixes: string[];
  /** Si true, el gateway exige un access token válido antes de reenviar. */
  protected: boolean;
}

/** Construye la tabla de rutas a partir del entorno. */
export function serviceRoutes(env: NodeJS.ProcessEnv = process.env): ServiceRoute[] {
  return [
    {
      name: 'identity',
      target: env.IDENTITY_URL ?? 'http://identity:3001',
      prefixes: ['/auth'],
      // Público: login/register/refresh/logout no pueden exigir token.
      // /auth/me lo protege el propio identity con su guard.
      protected: false,
    },
    {
      // Servir archivos de media (imágenes) es PÚBLICO: se muestran en el feed
      // y las vitrinas. Debe ir ANTES de la ruta protegida de ministores para
      // que /media/files/* no exija token (matchRoute devuelve el primer match).
      name: 'ministores-media-files',
      target: env.MINISTORES_URL ?? 'http://ministores:3002',
      prefixes: ['/media/files'],
      protected: false,
    },
    {
      // Feed del marketplace: PÚBLICO (productos publicados de tiendas activas).
      // Se puede navegar sin token; no necesita contexto de perfil.
      name: 'ministores-feed',
      target: env.MINISTORES_URL ?? 'http://ministores:3002',
      prefixes: ['/feed'],
      protected: false,
    },
    {
      name: 'ministores',
      target: env.MINISTORES_URL ?? 'http://ministores:3002',
      // /media (p. ej. /media/assets: subir/gestionar) queda protegido; la
      // lectura de archivos /media/files/* ya se resolvió arriba como pública.
      prefixes: ['/stores', '/catalogs', '/audit-logs', '/media'],
      // Solo consumible con access token válido (validado en el gateway).
      protected: true,
    },
  ];
}

/** ¿El pathname cae bajo alguno de los prefijos de la ruta? */
export function routeMatchesPath(route: ServiceRoute, pathname: string): boolean {
  return route.prefixes.some((p) => pathname === p || pathname.startsWith(`${p}/`));
}

/** Devuelve la ruta (servicio) a la que pertenece el pathname, o null. */
export function matchRoute(routes: ServiceRoute[], pathname: string): ServiceRoute | null {
  return routes.find((route) => routeMatchesPath(route, pathname)) ?? null;
}
