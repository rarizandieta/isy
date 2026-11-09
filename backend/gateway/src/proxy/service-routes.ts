/**
 * Tabla de enrutado del gateway.
 *
 * El API Gateway NO tiene lógica de dominio: solo sabe qué prefijos de ruta
 * pertenecen a cada microservicio y a qué destino reenviarlos. Agregar un
 * servicio nuevo es simplemente añadir una entrada aquí.
 */
export interface ServiceRoute {
  /** Nombre del servicio (para logs y mensajes de error). */
  name: string;
  /** URL base del microservicio en la red interna de Docker. */
  target: string;
  /** Prefijos de ruta que se reenvían a ese servicio. */
  prefixes: string[];
}

/** Construye la tabla de rutas a partir del entorno. */
export function serviceRoutes(env: NodeJS.ProcessEnv = process.env): ServiceRoute[] {
  return [
    {
      name: 'identity',
      target: env.IDENTITY_URL ?? 'http://identity:3001',
      prefixes: ['/auth'],
    },
    // Futuro — ministores:
    // {
    //   name: 'ministores',
    //   target: env.MINISTORES_URL ?? 'http://ministores:3002',
    //   prefixes: ['/ministores'],
    // },
  ];
}
