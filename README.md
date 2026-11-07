# Isy — Monorepo

Ecosistema de la app **Isy** (marketplace social con perfiles anidados y Mini Tiendas).
Monorepo que agrupa backend, app móvil, infraestructura y documentación.

## Estructura

```
Isy/
├── .kiro/specs/            # Documentación viva (requirements, design, tasks) por feature
│   ├── isy-mocks/          #   · prototipo/mocks + diseño de BD por módulo
│   └── backend-architecture/  · arquitectura backend (microservicios, gateway, nginx, Redis…)
├── backend/                # Microservicios NestJS INDEPENDIENTES (cada uno su propia metadata)
│   ├── gateway/            #   proyecto Nest propio · Node 24 (Volta) · puerto 3000
│   ├── identity/           #   proyecto Nest propio · Node 24 (Volta) · puerto 3001
│   └── ministores/         #   proyecto Nest propio · Node 24 (Volta) · puerto 3002
├── mobile/                 # App Flutter (paquete isy)
├── infra/
│   ├── nginx/              # reverse proxy + TLS (nginx.conf, certs/)
│   └── postgres/           # init.sql (crea las BD por servicio)
├── isy_mocks/              # Prototipo de UI (mocks navegables) — referencia
├── db/                     # Notas/artefactos de BD
├── docker-compose.yml      # Orquestación (solo nginx expuesto: 443/80)
└── .env.example
```

## Arquitectura (resumen)

```
App Flutter ──HTTPS:443──► nginx ──HTTP──► API Gateway ──HTTP──► microservicios ──► PostgreSQL
                                              └──► Redis (rate-limit · blocklist de tokens)
```

- **Único expuesto al host:** nginx (443, y 80→443). Gateway, servicios, Postgres y Redis
  viven en la red privada de Docker.
- **Persistencia:** una Postgres, **un volumen** (`pgdata`), **una base por servicio**
  (`identity`, `ministores`). Redis es efímero (sin volumen).
- Detalle completo en `.kiro/specs/backend-architecture/design.md`.

## Prerrequisitos
- Docker + Docker Compose
- Node 24 (gestionado por **Volta** en `backend/package.json`)
- Flutter (para `mobile/`)

## Cómo levantar (dev)

1. Generar certificados TLS autofirmados para nginx:
   ```bash
   openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
     -keyout infra/nginx/certs/server.key \
     -out infra/nginx/certs/server.crt \
     -subj "/CN=localhost"
   ```
2. Levantar el stack:
   ```bash
   docker compose up --build
   ```
3. La API queda detrás de `https://localhost/api/...` (vía nginx → gateway).

> Estado actual: **esqueleto**. Los servicios exponen `/health`; la lógica de dominio se
> implementará por módulo (ver specs). Credenciales de `docker-compose.yml` son solo para dev.

## Git
El repositorio aún **no** está vinculado a un remoto; se hará en un paso posterior.
