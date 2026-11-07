# Requerimientos — Arquitectura Backend de Isy

## Introducción

Primer diseño arquitectónico del backend de **Isy**. El ecosistema se orquesta con **Docker
Compose**, el backend se construye con **NestJS (Node.js)** en microservicios, se expone al
exterior a través de **nginx** (TLS en el puerto **443**) y un **API Gateway** como fachada
única. La persistencia es **PostgreSQL**, y por ahora el único artefacto con volumen es la BD.

Esta es la base inicial (esqueleto). No busca el sistema completo, sino dejar el andamiaje y
los dos primeros microservicios funcionando de punta a punta: **Identity** (autenticación,
autorización, usuarios y perfiles) y **Mini Tiendas**.

### Alcance de esta fase
- ✅ Esqueleto de plataforma orquestado con Docker Compose.
- ✅ nginx como borde (TLS 443 + reverse proxy) — único artefacto expuesto al host.
- ✅ API Gateway (NestJS) como punto de entrada de la aplicación.
- ✅ Microservicio **identity** (auth + authz + users + profiles).
- ✅ Microservicio **ministores** (vitrina: tiendas, secciones, productos).
- ✅ PostgreSQL con un volumen; aislamiento lógico por servicio.
- ✅ **Redis** (en memoria, **sin volumen**) para rate-limiting y blocklist de access tokens.
- ❌ Lógica de negocio completa, feed/chat/notificaciones, media/uploads (fases siguientes).

---

## Requisito 1 — Punto de entrada único por HTTPS (nginx / 443)

**Historia:** Como operador de la plataforma, quiero que todo el tráfico externo entre por un
solo punto seguro, para simplificar exposición, TLS y seguridad.

**Criterios de aceptación:**
1. EL SISTEMA DEBERÁ exponer al exterior únicamente **nginx**, escuchando en el puerto **443**
   (HTTPS) con terminación TLS.
2. CUANDO llegue tráfico al puerto **80**, EL SISTEMA DEBERÁ redirigirlo a 443.
3. EL SISTEMA DEBERÁ reenviar (reverse proxy) las peticiones de API hacia el **API Gateway**
   por la red interna.
4. EL SISTEMA DEBERÁ mantener el gateway y los microservicios **sin puertos publicados** al
   host (solo accesibles dentro de la red de Docker).

---

## Requisito 2 — API Gateway (fachada de la aplicación)

**Historia:** Como cliente (app Flutter), quiero consumir una sola API coherente, para no
conocer la topología interna de microservicios.

**Criterios de aceptación:**
1. EL SISTEMA DEBERÁ ofrecer un **API Gateway** (NestJS) como única fachada de aplicación
   detrás de nginx.
2. EL GATEWAY DEBERÁ enrutar cada petición al microservicio correspondiente según la ruta
   (p. ej. `/api/auth/*`, `/api/profiles/*` → identity; `/api/stores/*` → ministores).
3. EL GATEWAY DEBERÁ validar el **access token (JWT)** en rutas protegidas y propagar el
   contexto de identidad (usuario y perfil activo) hacia los microservicios.
4. EL GATEWAY DEBERÁ centralizar preocupaciones transversales: CORS, validación de entrada,
   rate limiting básico y logging/correlación de peticiones.
5. DONDE una respuesta requiera datos de varios microservicios, EL GATEWAY PODRÁ agregar
   (componer) las respuestas (patrón BFF).

---

## Requisito 3 — Microservicio Identity (auth + authz + users + profiles)

**Historia:** Como plataforma, quiero un servicio que concentre identidad y acceso, para
evitar transacciones distribuidas en registro/login y cambios de perfil.

**Criterios de aceptación:**
1. EL SISTEMA DEBERÁ incluir un microservicio **identity** dueño de: credenciales e
   identidades SSO, códigos OTP, tokens de recuperación, sesiones/refresh tokens, **usuarios**
   y **perfiles** (comprador/vendedor/servicios).
2. EL SERVICIO DEBERÁ emitir y renovar tokens (access + refresh) y exponer la validación de
   los mismos.
3. EL SERVICIO DEBERÁ ser el único dueño de las tablas de su dominio (identidad).
4. EL SERVICIO DEBERÁ exponer el "perfil activo" como parte del contexto de identidad.

---

## Requisito 4 — Microservicio Mini Tiendas

**Historia:** Como vendedor, quiero gestionar mi vitrina, servida por un servicio de comercio
independiente de la identidad.

**Criterios de aceptación:**
1. EL SISTEMA DEBERÁ incluir un microservicio **ministores** dueño de `mini_stores`,
   `store_sections` y `store_products`.
2. EL SERVICIO DEBERÁ referenciar al **perfil vendedor** por ID (propiedad del servicio
   identity), sin llaves foráneas entre bases de datos de distintos servicios.
3. EL SERVICIO DEBERÁ validar que el solicitante es dueño del perfil vendedor antes de
   permitir operaciones de escritura (según el contexto de identidad del gateway).

---

## Requisito 5 — Persistencia PostgreSQL con un único volumen

**Historia:** Como operador, quiero persistir solo lo necesario, para mantener el stack
ligero y reproducible.

**Criterios de aceptación:**
1. EL SISTEMA DEBERÁ usar **una** instancia de PostgreSQL con **un único volumen** para los
   datos.
2. EL SISTEMA DEBERÁ aislar lógicamente los datos **por servicio** (una base de datos por
   microservicio dentro de la misma instancia: `identity`, `ministores`).
3. CADA microservicio DEBERÁ conectarse únicamente a su propia base de datos.
4. LOS demás artefactos (gateway, servicios, nginx) DEBERÁN ser **sin estado** (sin volumen).

---

## Requisito 6 — Orquestación con Docker Compose

**Historia:** Como desarrollador, quiero levantar todo el ecosistema con un comando, para
tener paridad dev/prod y onboarding simple.

**Criterios de aceptación:**
1. EL SISTEMA DEBERÁ definirse en un `docker-compose.yml` con los servicios: nginx, gateway,
   identity, ministores, postgres y **redis**.
2. LOS servicios DEBERÁN comunicarse por una **red privada** de Docker.
3. EL SISTEMA DEBERÁ exponer al host únicamente el puerto 443 (y 80 para redirección) de nginx.
4. EL SISTEMA DEBERÁ permitir configuración por **variables de entorno** (y archivos `.env`),
   sin secretos hardcodeados.
5. CADA servicio DEBERÁ declarar un **health check**.

---

## Requisito 7 — Autenticación y autorización con JWT

**Historia:** Como usuario, quiero sesiones seguras, para acceder sin reingresar credenciales
y con mis permisos correctos.

**Criterios de aceptación:**
1. EL SISTEMA DEBERÁ usar **access tokens** de vida corta (JWT firmado) y **refresh tokens**
   de vida larga (opacos, hash en BD) según lo definido en el módulo de BD de usuarios.
2. EL GATEWAY DEBERÁ validar el access token por **firma** (sin consultar BD) en cada petición
   protegida.
3. EL SISTEMA DEBERÁ aplicar autorización según el **tipo de perfil activo** (comprador /
   vendedor / servicios) y, a futuro, roles/permisos.
4. LOS microservicios DEBERÁN poder confiar en el contexto propagado por el gateway y, como
   defensa en profundidad, revalidar cuando aplique.

---

## Requisito 8 — Estructura de código (monorepo de servicios independientes)

**Historia:** Como equipo, quiero que cada microservicio sea un proyecto independiente, para
desplegarlos y versionarlos por separado sin acoplar dependencias.

**Criterios de aceptación:**
1. EL repositorio DEBERÁ ser un **monorepo** que agrupe los proyectos, pero **cada
   microservicio** (`gateway`, `identity`, `ministores`) DEBERÁ ser un **proyecto NestJS
   independiente** con su **propia metadata**: `package.json` (con pin de **Volta** a Node 24),
   `tsconfig`, `node_modules`, `Dockerfile` y build propios.
2. LOS microservicios **no** DEBERÁN compartir `package.json` ni dependencias.
3. EL código compartido (contratos/guards), cuando exista, DEBERÁ resolverse como **paquete
   compartido** (workspace o versionado) o por duplicación controlada — no mediante una
   metadata común.

---

## Requisito 9 — Observabilidad y operación básica

**Historia:** Como operador, quiero diagnosticar el sistema, para detectar fallos pronto.

**Criterios de aceptación:**
1. CADA servicio DEBERÁ exponer un endpoint `/health` (readiness/liveness).
2. EL SISTEMA DEBERÁ emitir logs estructurados con un **id de correlación** propagado desde el
   gateway.
3. EL SISTEMA DEBERÁ manejar errores de forma consistente (formato de error unificado del
   gateway hacia el cliente).

---

## Requisito 10 — Evolución de la arquitectura

**Historia:** Como arquitecto, quiero que el diseño crezca sin reescrituras, para incorporar
nuevos dominios y comunicación asíncrona.

**Criterios de aceptación:**
1. EL SISTEMA DEBERÁ permitir **agregar microservicios** (feed/social, chat, notificaciones,
   media) sin cambiar el contrato del cliente (solo nuevas rutas en el gateway).
2. EL SISTEMA DEBERÁ permitir introducir a futuro un **bus de eventos** (p. ej. NATS/RabbitMQ)
   para flujos asíncronos (ej. "producto publicado" → aparece en el feed) sin acoplar servicios.
3. EL SISTEMA DEBERÁ permitir mover una base de datos lógica a su propia instancia sin cambiar
   el código de dominio (gracias al aislamiento por servicio).

---

## Requisito 11 — Caché en memoria (Redis): rate-limiting y revocación de tokens

**Historia:** Como plataforma, quiero un almacén en memoria compartido, para limitar abuso y
poder revocar access tokens al instante pese a que el JWT es *stateless*.

**Criterios de aceptación:**
1. EL SISTEMA DEBERÁ incluir un servicio **Redis** en la red privada, **sin volumen** (estado
   efímero) y con health check.
2. EL GATEWAY DEBERÁ usar Redis para **rate limiting** (contadores con TTL), compartido entre
   instancias del gateway.
3. CUANDO identity revoque tokens (logout, cierre en todos los dispositivos, cambio de
   contraseña), EL SERVICIO DEBERÁ registrar el `jti` en una **blocklist** en Redis con TTL =
   vida restante del access.
4. EL GATEWAY DEBERÁ consultar la blocklist en cada petición protegida y **rechazar** tokens
   revocados.
5. EL SISTEMA DEBERÁ definir la política ante indisponibilidad de Redis (fail-open vs
   fail-closed) — decisión a refinar.
6. EL SERVICIO Redis DEBERÁ permanecer **sin estado durable**; su reinicio reinicia contadores
   y vacía la blocklist (aceptable por la corta vida del access).

> Relacionado: R2 (rate-limiting en el gateway) y R7 (JWT / revocación).

---

## Requisito 12 — Seguridad del cliente (app) y pagos

**Historia:** Como usuario, quiero que la app y los pagos sean seguros, para proteger mi cuenta
y mis datos financieros. (Transversal; parte aplica desde ya, los pagos en fase futura.)

**Criterios de aceptación:**
1. LA APP DEBERÁ aplicar **SSL/Certificate Pinning** (por **clave pública/SPKI**, con pines de
   respaldo y rotación) sobre el tráfico hacia nginx/gateway.
2. LA APP DEBERÁ guardar tokens/datos sensibles en el **almacenamiento seguro del SO**
   (Keychain/Keystore) y **no incrustar secretos** en el binario (solo claves públicas).
3. LA APP DEBERÁ **ofuscar** el build de release — capa Dart (`--obfuscate`) y, en **Android**,
   **R8/ProGuard** (`minifyEnabled` + `shrinkResources`) — y evitar logs/telemetría con PII o
   datos de tarjeta.
4. DONDE haya operaciones sensibles o de **pago**, LA APP DEBERÁ exigir **re-autenticación**
   (biometría) y usar **atestación de app/dispositivo** (Play Integrity / App Attest).
5. EN pagos, LOS **datos de tarjeta NUNCA** DEBERÁN tocar la app ni el backend: se usa la
   **tokenización del SDK** del proveedor; el backend guarda solo **referencias/tokens**.
6. EL BACKEND DEBERÁ ser **autoritativo** en montos y estado de pago, confirmando mediante
   **webhooks firmados** e **idempotencia**; nunca confiar en el resultado reportado por el
   cliente.
7. EL SISTEMA DEBERÁ aislar los cobros en un microservicio **`payments`** (fase futura), que
   habla con el proveedor por la *secret key* y procesa sus webhooks.
8. LA APP en **Android** DEBERÁ **impedir su ejecución en dispositivos con root** (bloqueo
   total, no solo advertencia); en iOS, equivalente ante jailbreak.

> Detalle de principios en `design.md` §7.1 (cliente) y §7.2 (pagos).
