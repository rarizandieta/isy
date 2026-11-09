# Isy — Checklist de paso a producción

Este documento resume qué se necesita para publicar el backend en producción y
cómo conviven las configuraciones de **desarrollo** y **producción** sin
pisarse. Está pensado para completarse cuando tengas el dominio y el servidor.

> Estado actual (desarrollo): el borde (nginx 443 → gateway → identity) ya
> funciona con un **certificado autofirmado**. La app, en build _debug_, confía
> en ese certificado y entra por `https://…/api`. Nada de esto se usa en
> producción; ver la sección de separación dev/prod.

---

## 1. Lo que tú provees

- [ ] **Dominio** para el backend (p. ej. `api.isy.app`).
- [ ] **DNS**: un registro `A`/`AAAA` del dominio apuntando a la IP pública del servidor.
- [ ] **Servidor/hosting**: una VM/VPS con Docker y Docker Compose, con los puertos **80** y **443** abiertos al exterior.
- [ ] **Método de certificado TLS**, una de dos:
  - [ ] **Let's Encrypt** (gratis, automático, se renueva solo). _Recomendado._ Requiere que el DNS ya apunte al servidor y que el 80/443 sean alcanzables desde Internet.
  - [ ] **Certificado propio/corporativo**: `fullchain.crt` + `private.key` (y la cadena intermedia si aplica).
- [ ] **Secretos de producción** (NO van en el repositorio):
  - [ ] Contraseña real de Postgres (sustituye `isy`/`isy`).
  - [ ] Secreto/llaves JWT (ver RS256 más abajo).

## 2. Lo que configuro yo

- [ ] `nginx.conf` de producción: `server_name` con tu dominio, certificados reales, redirección 80→443, **HSTS** reactivado y cabeceras de seguridad.
- [ ] Emisión y **renovación automática** del certificado (si eliges Let's Encrypt).
- [ ] Compose de producción: solo **nginx** expuesto; sin Adminer ni puertos de microservicios publicados; credenciales por variables de entorno.
- [ ] **App (build release)**: `baseUrl = https://tu-dominio/api`, sin cleartext, con **SSL pinning** clavado a tu certificado.
- [ ] Migración de **JWT a RS256** (identity firma con la clave privada, el gateway valida con la pública).

## 3. Cómo quedan separados dev y prod

La separación ya está montada en el repo; estos son los mecanismos:

### Backend / Docker
- `docker-compose.yml` = definición con forma de **producción** (solo nginx expuesto; secretos por variables de entorno, sin valores por defecto reales).
- `docker-compose.override.yml` = **solo desarrollo**. Docker Compose lo carga automáticamente **en tu máquina** (publica el puerto de identity, levanta Adminer…). En el servidor de producción se arranca **sin** él:
  ```bash
  # DEV (local): usa override automáticamente
  docker compose up -d

  # PROD (servidor): ignora el override de dev
  docker compose -f docker-compose.yml up -d
  # (o un docker-compose.prod.yml dedicado)
  ```
- Los valores cambian por **archivos de entorno**: `.env` (dev) vs `.env.prod` (servidor). Ya existe `.env.example` como plantilla.

### App Flutter
- Build **debug** → configuración de dev: certificado autofirmado de confianza + cleartext a `localhost`/`10.0.2.2` (`android/app/src/debug/`). **No** se incluye en release.
- Build **release** → configuración de prod: tu dominio, HTTPS con CA pública y **SSL pinning**. Sin cleartext.
- El `baseUrl` se inyecta por build (`--dart-define=IDENTITY_BASE_URL=…`), así no hay URLs quemadas.

### Certificados
- Dev: autofirmado en `infra/nginx/certs/` (ignorado por git).
- Prod: certificado real provisto en el servidor (volumen de Let's Encrypt o secreto montado). **Nunca** en el repositorio.

## 4. Seguridad — pendientes para producción

- [ ] Sustituir **todos** los secretos de desarrollo:
  - `POSTGRES_PASSWORD` (`isy` → secreto real).
  - `JWT_SECRET` (`dev-secret-change-me` → ver RS256).
- [ ] **JWT RS256**: generar par de llaves; identity firma con la privada, el gateway valida con la pública. Rotación documentada.
- [ ] Usuario de base de datos con **mínimo privilegio** por servicio (hoy se usa el superusuario `isy` para dev).
- [ ] **SSL pinning** en el build release de la app, clavado al certificado/public key de producción.
- [ ] Revisar/activar **HSTS** en nginx (solo con dominio real y HTTPS estable).
- [ ] Rate-limit y blocklist de tokens vía Redis (ya contemplado en la arquitectura).
- [ ] Copias de seguridad de Postgres (volumen `pgdata`) y estrategia de restauración.

## 5. Referencia del setup de desarrollo actual

Para reproducir el entorno de dev por el borde 443:

```powershell
# 1) Backend completo (nginx + gateway + identity + postgres + redis + adminer)
docker compose up -d --build

# 2) Certificado autofirmado (si falta), con SAN para los hosts de dev
#    Generado en infra/nginx/certs/server.crt + server.key
#    SAN: DNS:localhost, IP:127.0.0.1, IP:10.0.2.2

# 3) Túnel del dispositivo físico hacia el borde (puerto alto en el teléfono)
adb -s <device> reverse tcp:8443 tcp:443

# 4) App apuntando al borde HTTPS
flutter run -d <device> --dart-define=IDENTITY_BASE_URL=https://localhost:8443/api
```

- Emulador Android (en vez de dispositivo físico): sin `adb reverse`, usando `https://10.0.2.2/...` (el SAN del certificado ya incluye `10.0.2.2`).
- Adminer (inspección de BD, solo dev): http://localhost:8080 — PostgreSQL, servidor `postgres`, usuario `isy`, contraseña `isy`.

### Confianza del certificado en la app (detalle importante)

El cliente HTTP de Dart (`dart:io`) usa su propio almacén de confianza
(BoringSSL) y **no** consulta el `network_security_config` de Android. Por eso,
para que el paquete `http` confíe en el certificado autofirmado de dev:

- El cert se empaqueta como asset: `mobile/assets/certs/isy_dev_ca.pem`.
- En build **debug**, `buildHttpClient()` crea un `SecurityContext` que lo marca
  como confiable (`mobile/lib/core/http_client_factory.dart`). Esto **no**
  desactiva la verificación: valida cadena y hostname (SAN) igual que en prod.
- En build **release** se usa el cliente por defecto (solo CAs públicas); ahí
  entra el SSL pinning contra el certificado real.

(El trust-anchor en `network_security_config.xml` se mantiene por si algún
plugin usa la red nativa de Android, pero no afecta al paquete `http`.)
