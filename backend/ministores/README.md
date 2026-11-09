# Ministores service

Backend de ministores en NestJS.

## Bases de datos

Este servicio usa dos bases dentro de la misma instancia de PostgreSQL:

- `ministores`: dominio de tienda/secciones/productos/auditoría.
- `media`: assets de imagen y variantes (`optimized`, `thumbnail`, `hd`).

Variables requeridas:

- `DATABASE_URL` para `ministores`.
- `MEDIA_DATABASE_URL` para `media`.
- `MEDIA_STORAGE_DIR` para guardar archivos localmente en dev.
- `MEDIA_PUBLIC_BASE_URL` para construir URLs públicas de variantes.

Puedes copiar `.env.example` a `.env` y ajustar valores:

```bash
cp .env.example .env
```

## Migraciones (TypeORM)

```bash
# Instalar dependencias
npm install

# Correr migraciones de la BD ministores
npm run migration:run:ministores

# Correr migraciones de la BD media
npm run migration:run:media

# Revertir última migración de cada BD
npm run migration:revert:ministores
npm run migration:revert:media
```

## Decisiones de diseño actuales

- IDs automáticos con `BIGINT GENERATED ALWAYS AS IDENTITY`.
- `store_products.price` permite `0` para soportar artículos gratuitos.
- `offer_price` nunca puede ser mayor a `price`.
- `audit_logs` registra cambios de negocio en el dominio de `ministores`.
- Imágenes fuera de la BD (storage S3-compatible); la BD `media` guarda metadatos y variantes.
- Implementación runtime con TypeORM en dos conexiones (`ministores` y `media`).

## Endpoints iniciales

### Ministores

- `POST /stores`
- `POST /stores/with-image` (multipart: `logo`, opcional `cover`)
- `GET /stores/mine` (lista de tiendas del perfil vendedor)
- `GET /stores/:id`
- `PATCH /stores/:id`
- `PATCH /stores/:id/with-image` (multipart: `logo`, opcional `cover`)
- `DELETE /stores/:id` (soft delete)
- `GET /stores/:id/sections`
- `POST /stores/:id/sections`
- `PATCH /stores/:id/sections/:sectionId`
- `DELETE /stores/:id/sections/:sectionId` (soft delete)
- `POST /stores/:id/products`
- `POST /stores/:id/products/with-image` (multipart: `file`)
- `GET /stores/:id/products`
- `GET /stores/:id/products/:productId`
- `PATCH /stores/:id/products/:productId`
- `PATCH /stores/:id/products/:productId/with-image` (multipart: `file`)
- `DELETE /stores/:id/products/:productId` (soft delete)

Productos soportan `tagIds` en create/patch para asociar etiquetas en la tabla puente
`store_product_tags`.

### Catálogos

- `GET /catalogs/categories`
- `POST /catalogs/categories`
- `PATCH /catalogs/categories/:id` (soporta `imageUrl` o `imageMediaAssetId`)
- `GET /catalogs/units`
- `POST /catalogs/units`
- `PATCH /catalogs/units/:id`
- `GET /catalogs/tags`
- `POST /catalogs/tags`
- `PATCH /catalogs/tags/:id` (soporta `imageUrl` o `imageMediaAssetId`)

### Auditoría

- `GET /audit-logs` (filtros opcionales: `entityName`, `entityId`, `action`, `actorProfileId`, `limit`)

Si envías `logoMediaAssetId`, `coverMediaAssetId` o `imageMediaAssetId`, `ministores`
resuelve la URL preferida desde `media` (prioridad: `is_default`, luego `optimized`).
Esa integración es interna por servicio (inyección de `MediaService`), no llamada HTTP.

### Media

- `POST /media/assets`
- `GET /media/assets/:id`
- `GET /media/assets/owner/:ownerType/:ownerId`
- `POST /media/assets/:id/variants`
- `POST /media/assets/upload` (`multipart/form-data` con `file`)

`POST /media/assets/upload` procesa la imagen con `sharp` y crea:

- `optimized` (default)
- `thumbnail`
- `hd` (si `includeHd=true` o `qualityMode=hd_default`)

Regla de variantes actual:
- Si `includeHd=false` (o no se envía) => se guardan `optimized` + `thumbnail`.
- Si `includeHd=true` => se guardan `optimized` + `thumbnail` + `hd`.

## Levantar rápido para pruebas locales

Desde la raíz del repo:

```bash
# 1) Levantar postgres + ministores con puertos de desarrollo
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d postgres ministores

# 2) Cargar datos base (categorías y unidades)
cat backend/ministores/sql/dev-seed.sql | docker compose -f docker-compose.yml -f docker-compose.dev.yml exec -T postgres psql -U isy -d ministores

# 3) Ver errores en tiempo real (útil para 500)
docker compose -f docker-compose.yml -f docker-compose.dev.yml logs -f ministores

# 4) Ver últimas 200 líneas de logs
docker compose -f docker-compose.yml -f docker-compose.dev.yml logs --tail=200 ministores
```

Probar API en:

- `http://localhost:3002/health`
- `http://localhost:3002/stores/...`
- `http://localhost:3002/media/...`
