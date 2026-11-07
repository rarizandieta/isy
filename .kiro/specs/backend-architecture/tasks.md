# Plan de implementación — Arquitectura Backend de Isy

Construcción incremental del esqueleto. El objetivo es llegar a un **end-to-end**:
`App → nginx:443 → gateway → (identity | ministores) → postgres`, con health checks y un
flujo de auth mínimo. Cada tarea referencia los requisitos que cubre.

> Prerrequisitos locales: Docker + Docker Compose, Node.js LTS, Nest CLI.

- [ ] 1. Bootstrap de los microservicios (proyectos Nest independientes)
  - [ ] 1.1 Crear `backend/gateway`, `backend/identity`, `backend/ministores` como proyectos
        Nest **independientes** (cada uno su `package.json` con pin de **Volta** a Node 24,
        `tsconfig`, `nest-cli.json`, `Dockerfile` y build propios)
  - [ ] 1.2 Esqueleto por servicio: `main.ts` (PORT por env) + `GET /health`
  - [ ] 1.3 `.dockerignore` / `.gitignore` por servicio
  - _Requisitos: R8_

- [ ] 2. Código compartido (diferido)
  - [ ] 2.1 Cuando exista código común (contratos/DTOs, guards JWT, config), resolverlo como
        **paquete compartido** (workspace o versionado) o por duplicación controlada — sin
        metadata común entre servicios
  - _Requisitos: R7, R8_

- [ ] 3. Microservicio `identity` (esqueleto)
  - [ ] 3.1 Crear `apps/identity` (Nest HTTP) con módulo `health` (`/health`)
  - [ ] 3.2 Conexión a la base `identity` (ORM + migraciones) — crear tablas del módulo de
        usuarios y perfiles (ver `isy-mocks/database.md`)
  - [ ] 3.3 Endpoints mínimos: `POST /auth/register`, `POST /auth/login`, `POST /auth/refresh`,
        `GET /profiles/me` (stubs que ya emiten/validan JWT)
  - [ ] 3.4 Al revocar (logout / cierre global / cambio de contraseña), registrar el `jti` en
        la **blocklist** de Redis (TTL = vida restante del access)
  - _Requisitos: R3, R7, R11_

- [ ] 4. Microservicio `ministores` (esqueleto)
  - [ ] 4.1 Crear `apps/ministores` (Nest HTTP) con `/health`
  - [ ] 4.2 Conexión a la base `ministores` (ORM + migraciones) — tablas `mini_stores`,
        `store_sections`, `store_products` (ver `db-mini-tiendas.html`)
  - [ ] 4.3 Endpoints mínimos: `GET /stores/mine`, `GET /stores/:id`, `POST /stores`,
        CRUD básico de productos — autorizando por contexto de identidad
  - _Requisitos: R4_

- [ ] 5. API Gateway (`apps/gateway`)
  - [ ] 5.1 Crear `apps/gateway` (Nest HTTP) con `/health`
  - [ ] 5.2 Routing a servicios (clientes HTTP a `IDENTITY_URL` y `MINISTORES_URL`) por prefijo
        de ruta (`/api/auth`, `/api/profiles`, `/api/stores`, `/api/products`)
  - [ ] 5.3 `AuthGuard` (valida JWT por clave pública) + propagación de contexto por headers
        (`X-User-Id`, `X-Profile-Id`, `X-Profile-Type`, `X-Correlation-Id`)
  - [ ] 5.4 Transversales: CORS, validación, filtro de error unificado, logging/correlación
  - [ ] 5.5 Integrar **Redis**: rate limiting (contadores con TTL) y verificación de la
        **blocklist** de `jti` dentro del `AuthGuard`
  - _Requisitos: R2, R7, R9, R11_

- [ ] 6. Dockerización de las apps
  - [ ] 6.1 `Dockerfile` por app (multi-stage: build → runtime slim) para gateway/identity/ministores
  - [ ] 6.2 `.dockerignore` y optimización de capas (instalar deps del monorepo correctamente)
  - _Requisitos: R6_

- [ ] 7. PostgreSQL
  - [ ] 7.1 Servicio `postgres` en compose con volumen `pgdata` y `healthcheck` (`pg_isready`)
  - [ ] 7.2 `infra/postgres/init.sql`: crea bases `identity` y `ministores` (y roles por base)
  - _Requisitos: R5, R6_

- [ ] 8. nginx (borde / TLS 443)
  - [ ] 8.1 `infra/nginx/nginx.conf`: `server` en 443 con TLS, `location /api/ → gateway:3000`
  - [ ] 8.2 Redirección 80 → 443 y headers de seguridad (HSTS, etc.)
  - [ ] 8.3 Certificados dev autofirmados montados por volumen de solo lectura
  - _Requisitos: R1_

- [ ] 9. Orquestación con Docker Compose
  - [ ] 9.1 `docker-compose.yml` con nginx, gateway, identity, ministores, postgres y **redis** en `isy-net`
  - [ ] 9.2 Exponer **solo** 443/80 de nginx; resto sin `ports`
  - [ ] 9.3 `depends_on` con condiciones de health; variables de entorno por servicio
  - [ ] 9.4 Servicio `redis` (redis:7-alpine) con healthcheck, **sin volumen** ni `ports`
  - _Requisitos: R1, R5, R6, R11_

- [ ] 10. Verificación end-to-end
  - [ ] 10.1 `docker compose up` levanta todo y los `/health` responden
  - [ ] 10.2 `POST https://localhost/api/auth/login` (vía nginx) emite tokens desde identity
  - [ ] 10.3 `GET https://localhost/api/stores/mine` con Bearer válido llega a ministores con
        el contexto de identidad propagado
  - [ ] 10.4 Verificar que gateway/servicios/postgres/redis **no** son accesibles desde el host
  - [ ] 10.5 Verificar **rate-limiting** (exceso de intentos de login) y **revocación
        inmediata** vía blocklist (logout invalida el access al instante)
  - _Requisitos: R1, R2, R3, R4, R7, R11_

- [ ] 11. Observabilidad y afinado
  - [ ] 11.1 Logs estructurados + `X-Correlation-Id` end-to-end
  - [ ] 11.2 Formato de error unificado del gateway
  - [ ] 11.3 Documentar comandos de operación (levantar, logs, migraciones) en un README
  - _Requisitos: R9_

---

## Notas de orden
- Se puede avanzar 1→2→(3 y 4 en paralelo)→5→(6,7,8)→9→10→11.
- Hasta no validar el end-to-end (tarea 10), los endpoints de dominio pueden ser *stubs*; la
  lógica real de cada dominio se detalla en specs por módulo (identity, ministores) después.
