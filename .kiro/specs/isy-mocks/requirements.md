# Requerimientos — Mocks de Isy

## Introducción

**Isy** es una app móvil de comercio social donde las personas conviven bajo un mismo
usuario con **perfiles anidados**: nace un perfil **comprador** por defecto y puede crear
múltiples perfiles **vendedor** y de **servicios**. El contenido gira en torno a
publicaciones de tiendas (seguidas o promovidas por el admin), con reacciones, comentarios
y un chat básico de contacto.

Este documento cubre la **fase de mocks**: prototipos navegables en Flutter con datos
simulados (en memoria, sin backend). El objetivo es validar flujos, pantallas y el sistema
de temas por perfil antes de construir la app real. Las publicaciones, cuentas, mensajes y
reacciones viven en memoria y se reinician al cerrar la app.

### Alcance de esta fase
- ✅ Pantallas navegables con datos de ejemplo.
- ✅ Sistema de theming que cambia de color según el perfil activo.
- ✅ Flujos de UI completos (registro, login, perfiles, dashboard, publicación, chat).
- ❌ Backend, autenticación real, persistencia, notificaciones push, pagos.

### Glosario
- **Usuario**: la cuenta raíz (una persona).
- **Perfil**: identidad dentro del usuario (comprador, vendedor o servicios).
- **Publicación (post)**: contenido creado por un perfil vendedor/servicios.
- **Tienda**: un perfil vendedor o de servicios visto desde el lado del comprador.
- **Admin**: rol interno que puede promover tiendas en el dashboard.

---

## Requisito 1 — Registro tradicional

**Historia de usuario:** Como persona nueva, quiero registrarme con correo y contraseña,
para crear mi cuenta en Isy.

**Criterios de aceptación:**
1. CUANDO el usuario abra la app sin sesión iniciada, EL SISTEMA DEBERÁ mostrar una pantalla
   de bienvenida con las opciones "Crear cuenta" e "Iniciar sesión".
2. CUANDO el usuario seleccione "Crear cuenta", EL SISTEMA DEBERÁ mostrar un formulario con
   nombre, correo, contraseña y confirmación de contraseña.
3. CUANDO el usuario envíe el formulario con datos válidos, EL SISTEMA DEBERÁ simular la
   creación de la cuenta y continuar al onboarding del perfil comprador.
4. SI algún campo es inválido (correo mal formado, contraseñas que no coinciden, campos
   vacíos), ENTONCES EL SISTEMA DEBERÁ mostrar un mensaje de error en línea bajo el campo
   correspondiente.
5. MIENTRAS la contraseña esté oculta, EL SISTEMA DEBERÁ ofrecer un control para mostrar/ocultar
   su contenido.

---

## Requisito 2 — Registro e inicio con Single Sign-On (Apple / Google)

**Historia de usuario:** Como persona nueva, quiero registrarme o entrar con mi cuenta de
Apple o Google, para no tener que recordar otra contraseña.

**Criterios de aceptación:**
1. CUANDO el usuario esté en la pantalla de bienvenida o registro, EL SISTEMA DEBERÁ mostrar
   botones de "Continuar con Apple" y "Continuar con Google" con su marca estándar.
2. CUANDO el usuario seleccione un proveedor SSO, EL SISTEMA DEBERÁ simular el flujo de
   autenticación del proveedor y continuar a la app con una cuenta creada.
3. DONDE la plataforma sea iOS, EL SISTEMA DEBERÁ priorizar visualmente el botón de Apple
   según los lineamientos de Apple.
4. CUANDO el SSO devuelva un usuario ya existente, EL SISTEMA DEBERÁ iniciar sesión en lugar
   de crear una cuenta nueva.

---

## Requisito 3 — Inicio de sesión (Login)

**Historia de usuario:** Como usuario registrado, quiero iniciar sesión, para acceder a mis
perfiles y contenido.

**Criterios de aceptación:**
1. CUANDO el usuario seleccione "Iniciar sesión", EL SISTEMA DEBERÁ mostrar un formulario con
   correo y contraseña, además de los botones de SSO.
2. CUANDO el usuario envíe credenciales válidas (simuladas), EL SISTEMA DEBERÁ llevarlo al
   dashboard con su último perfil activo.
3. SI las credenciales son inválidas, ENTONCES EL SISTEMA DEBERÁ mostrar un mensaje de error
   sin revelar qué campo falló.
4. EL SISTEMA DEBERÁ ofrecer un enlace de "¿Olvidaste tu contraseña?" que lleve a una
   pantalla de recuperación (mock).

---

## Requisito 4 — Perfil comprador por defecto

**Historia de usuario:** Como usuario nuevo, quiero tener automáticamente un perfil de
comprador, para empezar a explorar y seguir tiendas sin configurar nada.

**Criterios de aceptación:**
1. CUANDO se cree una cuenta, EL SISTEMA DEBERÁ generar automáticamente un perfil comprador
   asociado al usuario.
2. EL SISTEMA DEBERÁ aplicar el **tema verde** cuando el perfil comprador esté activo.
3. EL SISTEMA DEBERÁ impedir que el usuario elimine su perfil comprador.
4. CUANDO el usuario entre por primera vez, EL SISTEMA DEBERÁ activar el perfil comprador por
   defecto.

---

## Requisito 5 — Perfiles vendedor (múltiples)

**Historia de usuario:** Como usuario, quiero crear uno o varios perfiles de vendedor, para
gestionar distintas tiendas desde la misma cuenta.

**Criterios de aceptación:**
1. CUANDO el usuario elija "Crear perfil de vendedor", EL SISTEMA DEBERÁ mostrar un formulario
   con nombre de tienda, descripción, categoría y avatar.
2. EL SISTEMA DEBERÁ permitir crear múltiples perfiles de vendedor sin límite en esta fase.
3. CUANDO un perfil vendedor esté activo, EL SISTEMA DEBERÁ aplicar el **tema morado**.
4. CUANDO un perfil vendedor esté activo, EL SISTEMA DEBERÁ habilitar la gestión de
   publicaciones (CRUD) de esa tienda.
5. EL SISTEMA DEBERÁ permitir eliminar un perfil vendedor con confirmación previa.

---

## Requisito 6 — Perfiles de servicios (múltiples)

**Historia de usuario:** Como usuario, quiero crear uno o varios perfiles de servicios, para
ofrecer servicios profesionales de forma independiente a mis tiendas.

**Criterios de aceptación:**
1. CUANDO el usuario elija "Crear perfil de servicios", EL SISTEMA DEBERÁ mostrar un formulario
   con nombre, descripción, categoría de servicio y avatar.
2. EL SISTEMA DEBERÁ permitir crear múltiples perfiles de servicios.
3. CUANDO un perfil de servicios esté activo, EL SISTEMA DEBERÁ aplicar el **tema azul**.
4. CUANDO un perfil de servicios esté activo, EL SISTEMA DEBERÁ habilitar la gestión de
   publicaciones (CRUD) de ese servicio.

---

## Requisito 7 — Perfiles anidados y cambio de perfil

**Historia de usuario:** Como usuario con varios perfiles, quiero cambiar entre ellos
fácilmente, para actuar como comprador, como una de mis tiendas o como un servicio.

**Criterios de aceptación:**
1. EL SISTEMA DEBERÁ mostrar un selector de perfiles accesible desde la barra superior o el
   menú, listando todos los perfiles del usuario agrupados por tipo.
2. CUANDO el usuario seleccione un perfil, EL SISTEMA DEBERÁ activarlo, aplicar su tema de
   color y actualizar las acciones disponibles.
3. EL SISTEMA DEBERÁ indicar visualmente cuál es el perfil activo en todo momento.
4. EL SISTEMA DEBERÁ ofrecer, desde el selector, un acceso para "Crear nuevo perfil"
   (vendedor o servicios).
5. MIENTRAS haya un perfil activo, EL SISTEMA DEBERÁ mantener su tema en toda la navegación
   hasta que se cambie de perfil.

---

## Requisito 8 — Theming por perfil

**Historia de usuario:** Como usuario, quiero que cada perfil tenga su propio color
distintivo, para saber de un vistazo bajo qué identidad estoy actuando.

**Criterios de aceptación:**
1. EL SISTEMA DEBERÁ aplicar **verde** al perfil comprador, **morado** al vendedor y **azul**
   a servicios, usando esquemas de color Material 3.
2. CUANDO el usuario cambie de perfil, EL SISTEMA DEBERÁ animar la transición de color de la
   UI (barra, botones, acentos).
3. EL SISTEMA DEBERÁ soportar modo claro y oscuro para cada tema.
4. EL SISTEMA DEBERÁ mantener contraste y legibilidad (accesibilidad) en todos los temas.

---

## Requisito 9 — Dashboard de publicaciones

**Historia de usuario:** Como comprador, quiero ver un feed con las publicaciones de las
tiendas que sigo y las que destaca el admin, para descubrir productos y servicios.

**Criterios de aceptación:**
1. CUANDO el usuario entre al dashboard, EL SISTEMA DEBERÁ mostrar un feed con publicaciones
   de las tiendas seguidas y las promovidas por el admin.
2. EL SISTEMA DEBERÁ distinguir visualmente las publicaciones "Promovidas" por el admin.
3. CADA publicación DEBERÁ mostrar: tienda (avatar y nombre), contenido (texto/imagen),
   contador de reacciones y de comentarios.
4. CUANDO el usuario toque una publicación, EL SISTEMA DEBERÁ abrir su detalle con reacciones
   y comentarios.
5. EL SISTEMA DEBERÁ permitir refrescar el feed (pull-to-refresh) mostrando datos de ejemplo.
6. SI el usuario no sigue ninguna tienda, ENTONCES EL SISTEMA DEBERÁ mostrar un estado vacío
   con sugerencias de tiendas a seguir.

---

## Requisito 10 — CRUD de publicaciones

**Historia de usuario:** Como vendedor o servicio, quiero crear, editar y eliminar mis
publicaciones, para mantener mi tienda actualizada.

**Criterios de aceptación:**
1. MIENTRAS un perfil vendedor o de servicios esté activo, EL SISTEMA DEBERÁ mostrar la acción
   "Crear publicación".
2. CUANDO el usuario cree una publicación, EL SISTEMA DEBERÁ pedir título, descripción,
   imagen (placeholder) y precio opcional, y agregarla al feed de esa tienda.
3. CUANDO el autor abra una publicación propia, EL SISTEMA DEBERÁ ofrecer "Editar" y
   "Eliminar".
4. CUANDO el autor elimine una publicación, EL SISTEMA DEBERÁ pedir confirmación antes de
   quitarla del feed.
5. EL SISTEMA DEBERÁ impedir que un perfil comprador cree, edite o elimine publicaciones.

---

## Requisito 11 — Reacciones

**Historia de usuario:** Como usuario, quiero reaccionar a las publicaciones, para expresar
interés rápidamente.

**Criterios de aceptación:**
1. CUANDO el usuario toque el control de reacción, EL SISTEMA DEBERÁ alternar su reacción y
   actualizar el contador al instante.
2. EL SISTEMA DEBERÁ ofrecer un conjunto de reacciones (p. ej. me gusta, me encanta, quiero).
3. EL SISTEMA DEBERÁ mostrar el estado de "ya reaccioné" de forma visual.

---

## Requisito 12 — Comentarios

**Historia de usuario:** Como usuario, quiero comentar en las publicaciones, para preguntar o
dar opinión.

**Criterios de aceptación:**
1. CUANDO el usuario abra el detalle de una publicación, EL SISTEMA DEBERÁ mostrar la lista de
   comentarios con autor, avatar, texto y tiempo relativo.
2. CUANDO el usuario escriba y envíe un comentario, EL SISTEMA DEBERÁ agregarlo al inicio de
   la lista y actualizar el contador.
3. EL SISTEMA DEBERÁ mostrar un estado vacío cuando no haya comentarios.
4. EL SISTEMA DEBERÁ identificar los comentarios del perfil activo del usuario.

---

## Requisito 13 — Chat básico (Contacto)

**Historia de usuario:** Como comprador, quiero contactar a una tienda por chat, para
preguntar por un producto o servicio.

**Criterios de aceptación:**
1. CUANDO el usuario toque "Contactar" en una tienda o publicación, EL SISTEMA DEBERÁ abrir
   una conversación de chat con esa tienda.
2. EL SISTEMA DEBERÁ mostrar una lista de conversaciones con último mensaje y hora.
3. CUANDO el usuario envíe un mensaje, EL SISTEMA DEBERÁ agregarlo a la conversación alineado
   a la derecha y simular una respuesta automática de la tienda.
4. EL SISTEMA DEBERÁ aplicar el tema del perfil activo a la pantalla de chat.
5. EL SISTEMA DEBERÁ mostrar el estado de los mensajes (enviado) y el tiempo relativo.

---

## Requisito 14 — Seguir tiendas

**Historia de usuario:** Como comprador, quiero seguir o dejar de seguir tiendas, para
controlar qué aparece en mi feed.

**Criterios de aceptación:**
1. CUANDO el usuario abra el perfil de una tienda, EL SISTEMA DEBERÁ mostrar un botón
   "Seguir"/"Siguiendo".
2. CUANDO el usuario siga una tienda, EL SISTEMA DEBERÁ incluir sus publicaciones en el feed.
3. CUANDO el usuario deje de seguir, EL SISTEMA DEBERÁ retirar sus publicaciones del feed
   (salvo las promovidas por el admin).
4. EL SISTEMA DEBERÁ mostrar contadores de seguidores y publicaciones en el perfil de la
   tienda.

---

## Requisito 15 — Verificación de cuenta por código OTP

**Historia de usuario:** Como persona que se registra con correo, quiero confirmar mi correo
con un código, para asegurar que la cuenta es mía antes de entrar.

> Relacionado con R1 (Registro tradicional). El SSO (R2) no requiere este paso.

**Criterios de aceptación:**
1. CUANDO el usuario envíe el formulario de registro con datos válidos, EL SISTEMA DEBERÁ
   (al implementarse) enviar un código OTP de 6 dígitos al correo indicado y mostrar la
   pantalla de verificación en lugar de entrar directamente a la app.
2. EL SISTEMA DEBERÁ mostrar a qué correo se envió el código y un campo de 6 casillas para
   ingresarlo.
3. EL SISTEMA DEBERÁ mostrar un contador con la vigencia del código de **15 minutos**
   (formato mm:ss) que descuenta en tiempo real.
4. MIENTRAS el código no haya expirado y no esté completo (6 dígitos), EL SISTEMA DEBERÁ
   mantener deshabilitada la acción "Verificar".
5. CUANDO el usuario ingrese un código válido antes de expirar, EL SISTEMA DEBERÁ crear la
   cuenta (con su perfil comprador) y continuar al onboarding.
6. CUANDO el contador llegue a 00:00, EL SISTEMA DEBERÁ marcar el código como expirado y
   mostrar la opción "Solicitar código de nuevo".
7. CUANDO el usuario solicite un nuevo código, EL SISTEMA DEBERÁ reiniciar el contador a
   15:00, limpiar el campo y (al implementarse) reenviar el código.
8. EL SISTEMA DEBERÁ permitir volver atrás para corregir el correo.

> **Nota de la fase mock:** no hay envío real de correo; se acepta cualquier código de 6
> dígitos para avanzar.
