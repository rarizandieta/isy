# Diseño — Mocks de Isy

## 1. Visión general

Los mocks son una app Flutter **navegable** con datos simulados en memoria. Reutilizamos
Material 3 (el estándar de Flutter) y construimos un **sistema de theming dinámico** que
cambia el esquema de color según el perfil activo. Todo lo que se documenta aquí se traduce
directamente al proyecto real: modelos, pantallas, navegación y temas.

**Principios de diseño:**
- **Estándar primero:** Material 3, componentes nativos (`NavigationBar`, `Card`, `FilledButton`…).
- **Identidad por color:** cada perfil tiene un tema (verde / morado / azul) que tiñe toda la UI.
- **Datos falsos realistas:** repositorios en memoria con datos de ejemplo que se sienten reales.
- **Sin dependencias pesadas:** solo `provider` para el estado. Sin backend ni fuentes remotas.

---

## 2. Arquitectura y decisiones técnicas

| Aspecto | Decisión | Razón |
|---|---|---|
| UI toolkit | Flutter + Material 3 (`useMaterial3: true`) | Estándar pedido por el usuario |
| Gestión de estado | `provider` (`ChangeNotifier`) | Estándar, ligero, ideal para theming reactivo |
| Navegación | `Navigator` 1.0 + rutas nombradas | Suficiente y claro para mocks |
| Datos | Repositorios en memoria con seed de ejemplo | Sin backend en esta fase |
| Tipografía | Roboto (default M3) | Evita descargas remotas y mantiene el estándar |
| Plataforma de preview | Flutter Web (Chrome) | Único target 100% listo en el entorno |

**Capas:**
```
UI (screens + widgets)
      │  escucha / lee
      ▼
Controllers (ChangeNotifier)   ← SessionController, ProfileController, FeedController, ChatController
      │  usa
      ▼
Repositories en memoria        ← datos seed (MockData)
      │
      ▼
Models (inmutables)            ← User, Profile, Post, Comment, Reaction, Conversation, Message
```

---

## 3. Estructura de carpetas

```
lib/
├── main.dart                        # Entry point + MaterialApp con tema dinámico
├── app.dart                         # IsyApp: wiring de providers y rutas
├── core/
│   ├── theme/
│   │   ├── app_theme.dart           # buildTheme(ProfileType, Brightness)
│   │   ├── profile_palettes.dart    # Seeds y ColorScheme por perfil
│   │   └── theme_extensions.dart    # Colores custom (promovido, éxito, etc.)
│   └── routing/
│       └── routes.dart              # Nombres de ruta + onGenerateRoute
├── models/
│   ├── app_user.dart
│   ├── profile.dart                 # Profile + ProfileType enum
│   ├── post.dart
│   ├── reaction.dart
│   ├── comment.dart
│   ├── conversation.dart
│   └── message.dart
├── data/
│   ├── mock_data.dart               # Datos seed de ejemplo
│   ├── session_controller.dart      # usuario + perfil activo + auth simulada
│   ├── profile_controller.dart      # crear/cambiar/eliminar perfiles
│   ├── feed_controller.dart         # feed, CRUD posts, reacciones, comentarios
│   └── chat_controller.dart         # conversaciones y mensajes
├── screens/
│   ├── auth/
│   │   ├── welcome_screen.dart
│   │   ├── register_screen.dart
│   │   ├── otp_verification_screen.dart
│   │   ├── login_screen.dart
│   │   └── forgot_password_screen.dart
│   ├── onboarding/
│   │   └── buyer_onboarding_screen.dart
│   ├── shell/
│   │   └── home_shell.dart          # NavigationBar + tabs
│   ├── feed/
│   │   ├── dashboard_screen.dart
│   │   ├── post_detail_screen.dart
│   │   └── post_editor_screen.dart  # crear / editar
│   ├── profiles/
│   │   ├── profile_switcher_sheet.dart
│   │   ├── create_profile_screen.dart
│   │   ├── store_profile_screen.dart
│   │   └── account_screen.dart
│   └── chat/
│       ├── conversations_screen.dart
│       └── chat_screen.dart
└── widgets/
    ├── isy_logo.dart
    ├── sso_buttons.dart             # Botones Apple / Google
    ├── post_card.dart
    ├── reaction_bar.dart
    ├── comment_tile.dart
    ├── profile_avatar.dart
    ├── profile_badge.dart           # chip con tipo+color de perfil
    └── empty_state.dart
```

---

## 4. Modelos de datos (mock)

```dart
enum ProfileType { buyer, seller, service }   // comprador, vendedor, servicios

class AppUser {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;          // placeholder (iniciales / color)
  final List<Profile> profiles;    // siempre incluye 1 comprador
  final String activeProfileId;
}

class Profile {
  final String id;
  final ProfileType type;
  final String displayName;        // "Juan" (comprador) o "Tienda La Esquina" (vendedor)
  final String? description;
  final String? category;
  final int followers;
  final bool isOwnedByUser;        // true = perfil propio
}

class Post {
  final String id;
  final String storeProfileId;     // autor (vendedor/servicios)
  final String title;
  final String body;
  final String? imageSeed;         // color/placeholder de imagen
  final double? price;
  final bool isPromoted;           // destacado por admin
  final DateTime createdAt;
  final Map<ReactionType, int> reactionCounts;
  final ReactionType? myReaction;  // reacción del perfil activo
  final int commentCount;
}

enum ReactionType { like, love, want }   // me gusta, me encanta, lo quiero

class Comment {
  final String id;
  final String postId;
  final String authorName;
  final String authorAvatar;
  final String text;
  final DateTime createdAt;
  final bool isMine;
}

class Conversation {
  final String id;
  final String storeProfileId;
  final String storeName;
  final String lastMessage;
  final DateTime lastTime;
  final int unread;
}

class Message {
  final String id;
  final String conversationId;
  final String text;
  final bool isMine;               // true = lo envió el perfil activo
  final DateTime time;
}
```

---

## 5. Sistema de theming y paletas por perfil

### 5.1 Cómo funciona
- Cada `ProfileType` tiene un **color semilla (seed)**. Generamos el `ColorScheme` con
  `ColorScheme.fromSeed(seedColor: seed, brightness: ...)` para claro y oscuro.
- `SessionController` expone el `ProfileType` activo. `MaterialApp.theme` se reconstruye con
  `buildTheme(activeType, brightness)` cuando cambia el perfil.
- La transición de color se anima con el `AnimatedTheme` implícito de `MaterialApp`.

```dart
ThemeData buildTheme(ProfileType type, Brightness brightness) {
  final seed = kProfileSeeds[type]!;
  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  return ThemeData(useMaterial3: true, colorScheme: scheme, /* ... */);
}
```

### 5.2 Paletas (Material 3, modo claro)

> El `seed` define todo el esquema. Abajo se listan el seed y los tokens principales que
> produce, redondeados para documentación. Los contenedores y "on-colors" los deriva M3.

#### 🟢 Comprador — Verde
Transmite confianza, exploración y "todo bien para comprar".

| Token | Hex | Uso |
|---|---|---|
| **Seed** | `#2E7D32` | Base del esquema |
| Primary | `#2E6C31` | Botones primarios, barra activa |
| On Primary | `#FFFFFF` | Texto sobre primary |
| Primary Container | `#B0F1AC` | Chips, destacados suaves |
| Secondary | `#52634F` | Acentos secundarios |
| Tertiary | `#38656A` | Detalles (teal) |
| Surface | `#F7FBF2` | Fondos |
| Accent de marca | `#43A047` | Logo e íconos del perfil |

#### 🟣 Vendedor — Morado
Transmite identidad de marca, creatividad y estatus de "tienda".

| Token | Hex | Uso |
|---|---|---|
| **Seed** | `#6A1B9A` | Base del esquema |
| Primary | `#7B3FA0` | Botones primarios, barra activa |
| On Primary | `#FFFFFF` | Texto sobre primary |
| Primary Container | `#F0DBFF` | Chips, destacados suaves |
| Secondary | `#66596C` | Acentos secundarios |
| Tertiary | `#815250` | Detalles cálidos |
| Surface | `#FEF7FF` | Fondos |
| Accent de marca | `#8E24AA` | Logo e íconos del perfil |

#### 🔵 Servicios — Azul
Transmite profesionalismo, calma y confianza en el servicio.

| Token | Hex | Uso |
|---|---|---|
| **Seed** | `#1565C0` | Base del esquema |
| Primary | `#3660A8` | Botones primarios, barra activa |
| On Primary | `#FFFFFF` | Texto sobre primary |
| Primary Container | `#D7E2FF` | Chips, destacados suaves |
| Secondary | `#565E71` | Acentos secundarios |
| Tertiary | `#705574` | Detalles |
| Surface | `#FAF8FF` | Fondos |
| Accent de marca | `#1E88E5` | Logo e íconos del perfil |

### 5.3 Colores transversales (independientes del tema)
Definidos en un `ThemeExtension` para que no cambien con el perfil:

| Nombre | Claro | Oscuro | Uso |
|---|---|---|---|
| Promovido (admin) | `#FFB300` | `#FFCA28` | Badge "Promovido" en el feed |
| Éxito | `#2E7D32` | `#81C784` | Confirmaciones |
| Peligro | `#C62828` | `#EF9A9A` | Eliminar / errores |
| Reacción "me encanta" | `#E91E63` | `#F48FB1` | Corazón activo |

### 5.4 Modo oscuro (superficies teñidas)
Cada perfil usa `ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark)` con el
mismo seed. Para evitar el **negro plano** (que se sentía frío), las superficies del esquema
oscuro se **tiñen con el tono del perfil** y se suben ligeramente en luminosidad:

| Token | Luminosidad (HSL) | Resultado |
|---|---|---|
| surfaceContainerLowest | ~8% | base más profunda |
| surface | ~11% | fondo con matiz del perfil (no negro) |
| surfaceContainer | ~15% | tarjetas |
| surfaceContainerHighest | ~22% | campos, chips |

La saturación se mantiene baja (~16%) para no competir con el contenido. En **modo claro**
se aplica el mismo principio pero al revés: un matiz muy sutil (blancos cálidos ~0.3% sat)
para que no sea blanco plano. Se respeta el `ThemeMode` del sistema (claro/oscuro/automático).

### 5.5 Fondo de marca en autenticación
Las pantallas de bienvenida, login, registro, recuperación y onboarding usan
`BrandBackground`: un **degradado vertical** derivado del `hue` del perfil activo
(`colorScheme.primary`). Como sin sesión el perfil activo es comprador, el login luce un
degradado **verde** suave en claro y verde-oscuro cálido en oscuro. El formulario va dentro
de un `AuthPanel` (tarjeta de `surface` con sombra) para destacar sobre el degradado. El
`AppBar` es transparente con `extendBodyBehindAppBar` para que el color llegue hasta arriba.

---

## 6. Mapa de navegación

```
[Welcome] ──► [Register] ──► [OTP: código 6 díg · 15 min] ──► [Buyer Onboarding] ──┐
    │             │                                 │
    │             └──(SSO)───────────────────────┐  │
    └──► [Login] ──────────────────────────────┐ │  │
                                                ▼ ▼  ▼
                                        ┌──────────────────┐
                                        │   HomeShell      │  (NavigationBar, tiñe según perfil)
                                        ├──────────────────┤
                                        │ ◉ Inicio (feed)  │──► [Post Detail] ──► (reacciones/comentarios)
                                        │ ◉ Explorar       │──► [Store Profile] ──► [Chat]
                                        │ ◉ Mensajes       │──► [Chat]
                                        │ ◉ Cuenta         │──► [Create Profile]
                                        └──────────────────┘
                                                │  (avatar en AppBar)
                                                ▼
                                      [Profile Switcher] (bottom sheet)
                                                │
                                                ├─► cambiar perfil (re-tema)
                                                └─► [Create Profile] (vendedor/servicios)

FAB "Crear publicación" visible solo si el perfil activo es vendedor/servicios:
   [HomeShell] ──FAB──► [Post Editor] (crear) ; desde Post Detail propio ──► [Post Editor] (editar)
```

**Tabs del `NavigationBar`:**
1. **Inicio** — feed/dashboard.
2. **Explorar** — descubrir tiendas y seguirlas.
3. **Mensajes** — lista de conversaciones.
4. **Cuenta** — perfil activo, gestión de perfiles, cerrar sesión.

---

## 7. Pantallas (wireframes)

### 7.1 Welcome (Bienvenida)
```
┌───────────────────────────┐
│                           │
│          [ Isy ]          │  logo centrado
│   Tu mercado, tu gente    │  tagline
│                           │
│                           │
│  ┌─────────────────────┐  │
│  │    Crear cuenta     │  │  FilledButton
│  └─────────────────────┘  │
│  ┌─────────────────────┐  │
│  │   Iniciar sesión    │  │  OutlinedButton
│  └─────────────────────┘  │
│   ──────  o  ──────       │
│  [  Continuar con Apple ] │  SSO
│  [ Continuar con Google ] │  SSO
└───────────────────────────┘
```

### 7.2 Register (Registro)
```
┌───────────────────────────┐
│ ←  Crear cuenta           │
│                           │
│  Nombre      [__________] │
│  Correo      [__________] │
│  Contraseña  [________ 👁] │
│  Confirmar   [________ 👁] │
│                           │
│  ┌─────────────────────┐  │
│  │   Crear cuenta      │  │
│  └─────────────────────┘  │
│   ──────  o  ──────       │
│  [  Continuar con Apple ] │
│  [ Continuar con Google ] │
│  ¿Ya tienes cuenta? Entrar│
└───────────────────────────┘
```
Validación en línea (correo, contraseñas que coinciden). Al éxito → **Verificación OTP**.

### 7.2.1 Verificación OTP
```
┌───────────────────────────┐
│ ←                         │
│          [ isi ]          │
│    Verifica tu correo     │
│ ╭───────────────────────╮ │
│ │  ✉  código enviado a: │ │
│ │     juan@correo.com   │ │
│ │  ┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐   │ │  6 casillas (auto-foco)
│ │  └─┘└─┘└─┘└─┘└─┘└─┘   │ │
│ │  ⏱ El código vence    │ │  contador 15:00 → 00:00
│ │     en 14:59          │ │
│ │  [ Verificar y crear ]│ │  deshab. si incompleto/expira
│ ╰───────────────────────╯ │
│  ¿Correo equivocado?      │
└───────────────────────────┘
```
Al llegar a **00:00** el contador se reemplaza por "El código expiró" + botón
**"Solicitar código de nuevo"** (reinicia a 15:00 y limpia el campo). Mock: cualquier código
de 6 dígitos es válido; al verificar se crea la cuenta → Buyer Onboarding.

### 7.3 Login
```
┌───────────────────────────┐
│ ←  Iniciar sesión         │
│  Correo      [__________] │
│  Contraseña  [________ 👁] │
│          ¿Olvidaste? →    │
│  ┌─────────────────────┐  │
│  │      Entrar         │  │
│  └─────────────────────┘  │
│   ──────  o  ──────       │
│  [  Continuar con Apple ] │
│  [ Continuar con Google ] │
└───────────────────────────┘
```

### 7.4 Buyer Onboarding
Pantalla breve: "¡Bienvenido! Naciste con tu perfil de **Comprador** 🟢". Explica que puede
crear tiendas y servicios luego. Botón "Explorar Isy" → HomeShell (tema verde).

### 7.5 Dashboard / Feed (Inicio)
```
┌───────────────────────────┐
│ isi                    🔔 │  logo + notificaciones
│ ╭───────────────────────╮ │
│ │🟢 Actuando como·Compr.│ │  píldora de perfil (abre
│ │   Juan            ⇅   │ │   el switcher al tocar)
│ ╰───────────────────────╯ │
│▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀│  sombra: separa header y feed
│ ┌───────────────────────┐ │
│ │ ⭐ PROMOVIDO          │ │  badge ámbar si isPromoted
│ │ (avatar) Tienda X     │ │
│ │ [   imagen/color    ] │ │
│ │ Título · $precio      │ │
│ │ ❤ 120  💬 14          │ │  reaction bar + comentarios
│ └───────────────────────┘ │
│ ┌───────────────────────┐ │
│ │ (avatar) Servicio Y   │ │
│ │ ...                   │ │
│ └───────────────────────┘ │
│                      (＋)  │  FAB solo vendedor/servicios
├───────────────────────────┤
│  Inicio Explorar Msjs Cta │  NavigationBar
└───────────────────────────┘
```
Pull-to-refresh. Estado vacío si no sigue tiendas → sugerencias.

**Header:** el AppBar lleva elevación con sombra (`elevation`/`shadowColor`) para separarse
visualmente del feed. El perfil activo se muestra como una **píldora** (`_ProfilePill`):
avatar + "Actuando como · {tipo}" + nombre + ícono de cambio (⇅), teñida con el color de
marca del perfil; al tocarla se abre el selector de perfiles. Sustituye al avatar suelto y a
la antigua fila de texto.

### 7.6 Post Detail
```
┌───────────────────────────┐
│ ←  Publicación       ⋮    │  ⋮ = editar/eliminar (si es propio)
│ (avatar) Tienda X · 2h    │
│ [     imagen/color      ] │
│ Título                    │
│ Descripción...            │
│ $precio   [ Contactar ]   │  → Chat
│ ── Reacciones ──          │
│  👍 me gusta  ❤ encanta   │  ReactionBar (toggle)
│  🛒 lo quiero             │
│ ── Comentarios (14) ──    │
│ (av) Ana: ¿Hay stock?  1h │
│ (av) Yo: Me interesa   5m │
│ [ Escribe un comentario ⟶]│
└───────────────────────────┘
```

### 7.7 Post Editor (Crear / Editar) — CRUD
```
┌───────────────────────────┐
│ ←  Nueva publicación  ✓   │
│ [  + Agregar imagen     ] │  placeholder
│ Título       [__________] │
│ Descripción  [__________] │
│              [__________] │
│ Precio (opc) [__________] │
│ ┌─────────────────────┐   │
│ │      Publicar       │   │
│ └─────────────────────┘   │
└───────────────────────────┘
```
Solo accesible con perfil vendedor/servicios. Editar precarga valores. Eliminar pide
confirmación (dialog).

### 7.8 Profile Switcher (bottom sheet)
```
┌───────────────────────────┐
│ Cambiar de perfil         │
│ COMPRADOR                 │
│  🟢 Juan            ✓     │  activo
│ VENDEDOR                  │
│  🟣 Tienda La Esquina     │
│  🟣 Moda JP               │
│ SERVICIOS                 │
│  🔵 Plomería Express      │
│ ─────────────────────     │
│  ＋ Crear nuevo perfil    │
└───────────────────────────┘
```
Al elegir perfil: cierra sheet, re-aplica tema con animación.

### 7.9 Create Profile
```
┌───────────────────────────┐
│ ←  Crear perfil           │
│ Tipo:  (•) Vendedor 🟣    │  segmented
│        ( ) Servicios 🔵   │
│ Nombre       [__________] │
│ Categoría    [ ▼ ]        │
│ Descripción  [__________] │
│ [ Avatar: elegir color ]  │
│ ┌─────────────────────┐   │
│ │   Crear perfil      │   │
│ └─────────────────────┘   │
└───────────────────────────┘
```

### 7.10 Store Profile (Tienda)
```
┌───────────────────────────┐
│ ←  Tienda La Esquina   ⋮  │
│   (avatar grande 🟣)      │
│   Tienda La Esquina       │
│   1.2k seguidores · 24 pub│
│  [ Siguiendo ] [Contactar]│
│   Descripción de la tienda│
│ ── Publicaciones ──       │
│ ▦ ▦ ▦   (grid de posts)   │
│ ▦ ▦ ▦                     │
└───────────────────────────┘
```

### 7.11 Conversations (Mensajes)
```
┌───────────────────────────┐
│ Mensajes                  │
│ (av) Tienda X   2h    (2) │  unread badge
│ Hola, ¿sigue disponible?  │
│ ─────────────────────     │
│ (av) Servicio Y  1d       │
│ Gracias por tu compra     │
├───────────────────────────┤
│  Inicio Explorar Msjs Cta │
└───────────────────────────┘
```

### 7.12 Chat
```
┌───────────────────────────┐
│ ←  (av) Tienda X          │
│                           │
│  [ Hola, ¿precio? ]       │  recibido (izq)
│          [ $350 😊 ]      │  enviado (der, color perfil)
│  [ ¿Hacen envío? ]        │
│                           │
│ [ Escribe un mensaje  ⟶ ] │
└───────────────────────────┘
```
Envío agrega burbuja a la derecha con color del perfil activo; respuesta automática simulada.

### 7.13 Account (Cuenta)
```
┌───────────────────────────┐
│ Cuenta                    │
│ (avatar) Juan             │
│ juan@correo.com           │
│ ── Mis perfiles ──        │
│  🟢 Comprador (tú)        │
│  🟣 Tienda La Esquina   ⋮ │
│  🔵 Plomería Express    ⋮ │
│  ＋ Crear nuevo perfil    │
│ ── Ajustes ──             │
│  Tema del sistema  [▼]    │
│  Cerrar sesión            │
└───────────────────────────┘
```

---

## 8. Inventario de componentes reutilizables

| Widget | Descripción |
|---|---|
| `IsyLogo` | Wordmark con el color de acento del perfil activo |
| `SsoButtons` | Botones Apple/Google con estilo de marca |
| `PostCard` | Tarjeta de publicación (avatar, imagen, título, precio, reacciones) |
| `ReactionBar` | Toggle de reacciones con contador animado |
| `CommentTile` | Fila de comentario (avatar, autor, texto, tiempo) |
| `ProfileAvatar` | Avatar con iniciales y color según tipo de perfil |
| `ProfileBadge` | Chip que muestra tipo + color del perfil |
| `PromotedBadge` | Etiqueta ámbar "Promovido" |
| `EmptyState` | Ilustración + texto para estados vacíos |
| `BrandBackground` | Degradado de marca (según perfil) para pantallas de auth |
| `AuthPanel` / `OrDivider` | Tarjeta del formulario y separador "o" de auth |

---

## 9. Datos de ejemplo (seed)

- **Usuario:** "Juan Pérez" (juan@correo.com) con: 1 comprador, 2 vendedores
  ("Tienda La Esquina", "Moda JP"), 1 servicio ("Plomería Express").
- **Tiendas externas** que sigue: "TecnoMax", "Dulce Hogar", "FitLife".
- **Posts:** ~10 publicaciones, 2 marcadas como `isPromoted`, con reacciones y comentarios variados.
- **Conversaciones:** 3 chats con historial corto.
- Imágenes = bloques de color determinísticos a partir de `imageSeed` (sin assets remotos).

---

## 10. Mapa requerimiento → implementación

| Requisito | Dónde se cubre |
|---|---|
| R1 Registro tradicional | `register_screen.dart` → navega a verificación OTP |
| R2 SSO Apple/Google | `sso_buttons.dart` + flujo simulado en `SessionController` |
| R3 Login | `login_screen.dart` + `forgot_password_screen.dart` |
| R4 Comprador por defecto | `MockData` + `SessionController` (perfil buyer no eliminable) |
| R5 Vendedor múltiple | `create_profile_screen.dart` + `ProfileController` |
| R6 Servicios múltiple | `create_profile_screen.dart` + `ProfileController` |
| R7 Perfiles anidados | `profile_switcher_sheet.dart` + `account_screen.dart` |
| R8 Theming por perfil | `app_theme.dart` + `profile_palettes.dart` |
| R9 Dashboard | `dashboard_screen.dart` + `FeedController` |
| R10 CRUD posts | `post_editor_screen.dart` + `FeedController` |
| R11 Reacciones | `reaction_bar.dart` + `FeedController.toggleReaction()` |
| R12 Comentarios | `post_detail_screen.dart` + `FeedController.addComment()` |
| R13 Chat | `conversations_screen.dart` + `chat_screen.dart` + `ChatController` |
| R14 Seguir tiendas | `store_profile_screen.dart` + `FeedController.toggleFollow()` |
| R15 Verificación OTP | `otp_verification_screen.dart` (contador 15 min + reenvío) |


---

## 11. Feature — Mini Tiendas (mockup inicial)

Vitrina de productos **personalizable** para perfiles **vendedor**. El reto es que sea
**genérica** (abarrotes, comida, verduras, carnicería, panadería…) pero que cada tienda
conserve su **esencia**.

### 11.1 Cómo se logra "genérico + con esencia"
- **Unidad de venta** por producto (pieza, docena, kg, libra, manojo, porción, litro, bolsa,
  caja): el comodín que adapta el catálogo a casi cualquier giro.
- **Categoría del negocio** (presets + "Otro").
- **Secciones** personalizables dentro de la tienda (ej. "Del día", "Café", "Abarrotes").
- **Disponibilidad** por producto: disponible / agotado / por encargo (clave en perecederos).
- **Personalización visual**: **foto de portada** (banner) y **foto de perfil / logo**
  —selectores tipo placeholder en el editor—, **color de acento**, eslogan y descripción.
- **Entrega** (recoger / domicilio / envío) y **pagos** (efectivo / transferencia / tarjeta).
- **Destacados** (productos fijados arriba).

### 11.2 Campos por producto
Base: nombre, descripción, **precio**, **imagen**. Además: **unidad**, **precio de oferta**,
**disponibilidad**, **sección**, **etiquetas** (nuevo, oferta, picante, vegano, hecho a mano…)
y **destacado**. Cada producto tiene también un **estado de publicación**: **Publicar**
(visible en la vitrina y anunciado en el Feed) o **Borrador** (solo lo ve el dueño).

### 11.3 A considerar en próximas iteraciones
- **Variantes/opciones** (sabor, tamaño, extras) — ej. tamal de pollo/cerdo, tallas.
- **Galería** de múltiples imágenes por producto.
- **Stock numérico** y control de "pedido mínimo/máximo".
- **Horario por día** y estado "abierto/cerrado" automático.
- **Tiempo de preparación / disponibilidad por día** (comida).
- **Búsqueda y filtrado** dentro de la tienda; orden manual de productos.
- **Reseñas/calificaciones** y **zonas de envío con costo**.

### 11.4 Modelo de datos (mock, en memoria)
```
MiniStore { id, sellerProfileId, name, tagline, description, category,
            coverSeed, accentColor, isOpen, schedule, zone,
            delivery:Set<DeliveryOption>, payments:Set<PaymentMethod>,
            sections:List<StoreSection> }

StoreProduct { id, storeId, sectionId?, name, description, price, offerPrice?,
               unit, imageSeed, stock:StockStatus, isFeatured, tags:List,
               status:ProductStatus }

enum DeliveryOption { pickup, delivery, shipping }
enum PaymentMethod  { cash, transfer, card }
enum StockStatus    { available, soldOut, madeToOrder }
enum ProductStatus  { draft, published }
```

### 11.5 Pantallas (en `lib/screens/mini_store/`)
- **Vitrina** (`mini_store_screen.dart`): portada con acento + logo, abierto/cerrado,
  info (horario/zona/entregas/pagos), **destacados** (carrusel) y **secciones** con tarjetas
  de producto. Funciona en modo **visitante** (botón Contactar + detalle en bottom sheet) y
  **dueño** (editar tienda, agregar/editar productos, FAB "Producto").
- **Editor de tienda** (`mini_store_editor_screen.dart`): identidad (con selectores de
  **foto de portada** y **foto de perfil / logo**), giro, color de acento,
  abierto/cerrado, horario, zona, entregas, pagos y **gestión de secciones** (crear,
  renombrar, eliminar y reordenar arrastrando). Sirve para crear o editar. Las secciones
  creadas aquí son las que luego se eligen al crear/editar un producto.
- **Editor de producto** (`product_editor_screen.dart`): nombre, descripción, precio, oferta,
  unidad, sección, disponibilidad, etiquetas, destacado y **estado de publicación**
  (**Publicar** o **Guardar borrador**). Al publicar un producto (uno nuevo, o un borrador que
  pasa a publicado) se crea automáticamente una **publicación en el Feed**. En la vitrina el
  dueño ve sus borradores con un distintivo **"Borrador"**; los visitantes solo ven lo publicado.

### 11.6 Entradas de navegación
- **Cuenta** → tarjeta **"Mi Mini Tienda"** cuando el perfil activo es vendedor (ver/crear).
- **Perfil de tienda** → botón **"Ver Mini Tienda"** si la tienda tiene una.

### 11.7 Estado del mock
Datos en memoria (`MiniStoreController`): 2 tiendas seed — "Tienda La Esquina" (propia,
editable) y "Dulce Hogar" (externa, vista de visitante). Pendiente: módulo de BD de Mini
Tiendas (tablas `mini_stores`, `store_sections`, `store_products`) cuando refinemos el mock.
