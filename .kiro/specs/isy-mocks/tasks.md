# Plan de implementación — Mocks de Isy

Tareas incrementales para construir los mocks navegables en Flutter. Cada tarea referencia los
requisitos que cubre. El objetivo es un prototipo que levante en Chrome (web) con datos simulados.

> ✅ **Estado: mocks implementados.** El proyecto Flutter está en `isy_mocks/`.
> `flutter analyze` pasa sin issues y `flutter build web` compila correctamente.
>
> **Cómo correrlo:**
> ```bash
> cd isy_mocks
> flutter run -d chrome        # o: flutter run -d web-server --web-port 8080
> ```
> Nota de implementación: la gestión de perfiles se consolidó dentro de
> `SessionController` (en lugar de un `ProfileController` aparte) para tener una sola
> fuente de verdad del usuario, sus perfiles y el perfil activo.

- [ ] 1. Scaffolding del proyecto y base
  - [ ] 1.1 Crear proyecto Flutter `isy_mocks` y limpiar el contador de ejemplo
  - [ ] 1.2 Agregar dependencia `provider` en `pubspec.yaml` y correr `flutter pub get`
  - [ ] 1.3 Crear la estructura de carpetas (`core/`, `models/`, `data/`, `screens/`, `widgets/`)
  - _Requisitos: base para todos_

- [ ] 2. Sistema de theming y paletas por perfil
  - [ ] 2.1 Implementar `profile_palettes.dart` con los seeds (verde/morado/azul) y mapa `kProfileSeeds`
  - [ ] 2.2 Implementar `app_theme.dart` con `buildTheme(ProfileType, Brightness)` usando `ColorScheme.fromSeed`
  - [ ] 2.3 Implementar `theme_extensions.dart` con colores transversales (promovido, éxito, peligro, "me encanta")
  - _Requisitos: R8_

- [ ] 3. Modelos de datos
  - [ ] 3.1 Crear enums `ProfileType` y `ReactionType`
  - [ ] 3.2 Crear modelos `AppUser`, `Profile`, `Post`, `Comment`, `Conversation`, `Message` (inmutables con `copyWith`)
  - _Requisitos: R4, R5, R6, R9, R11, R12, R13_

- [ ] 4. Datos de ejemplo y controladores de estado
  - [ ] 4.1 Crear `mock_data.dart` con usuario Juan (comprador + 2 vendedores + 1 servicio), tiendas, ~10 posts, 3 chats
  - [ ] 4.2 Implementar `SessionController` (auth simulada, perfil activo, `ThemeMode`)
  - [ ] 4.3 Implementar `ProfileController` (crear/cambiar/eliminar perfiles; comprador no eliminable)
  - [ ] 4.4 Implementar `FeedController` (feed, CRUD de posts, reacciones, comentarios, seguir tiendas)
  - [ ] 4.5 Implementar `ChatController` (conversaciones, enviar mensaje, respuesta automática)
  - _Requisitos: R4, R5, R6, R7, R9, R10, R11, R12, R13, R14_

- [ ] 5. Widgets reutilizables
  - [ ] 5.1 `isy_logo.dart`, `profile_avatar.dart`, `profile_badge.dart`, `empty_state.dart`
  - [ ] 5.2 `sso_buttons.dart` (Apple / Google con estilo de marca)
  - [ ] 5.3 `post_card.dart`, `reaction_bar.dart`, `comment_tile.dart`, `promoted_badge.dart`
  - _Requisitos: R2, R8, R9, R11, R12_

- [ ] 6. Wiring de la app (providers + rutas)
  - [ ] 6.1 `routes.dart` con nombres de ruta y `onGenerateRoute`
  - [ ] 6.2 `app.dart`: `MultiProvider` + `MaterialApp` con tema dinámico según perfil activo
  - [ ] 6.3 `main.dart`: entry point; decide ruta inicial según sesión (welcome vs home)
  - _Requisitos: R7, R8_

- [ ] 7. Flujo de autenticación
  - [ ] 7.1 `welcome_screen.dart` (crear cuenta / iniciar sesión / SSO)
  - [ ] 7.2 `register_screen.dart` con validación en línea y SSO
  - [ ] 7.3 `login_screen.dart` + `forgot_password_screen.dart`
  - [ ] 7.4 Conectar éxito de registro → onboarding; login → home
  - _Requisitos: R1, R2, R3_

- [ ] 8. Onboarding del comprador
  - [ ] 8.1 `buyer_onboarding_screen.dart` (explica perfil comprador, tema verde) → home
  - _Requisitos: R4_

- [ ] 9. Shell principal con navegación
  - [ ] 9.1 `home_shell.dart` con `NavigationBar` (Inicio, Explorar, Mensajes, Cuenta)
  - [ ] 9.2 AppBar con avatar que abre el Profile Switcher; FAB "Crear publicación" condicional al perfil
  - _Requisitos: R7, R8, R10_

- [ ] 10. Dashboard / Feed
  - [ ] 10.1 `dashboard_screen.dart`: lista de `PostCard`, badge "Promovido", pull-to-refresh
  - [ ] 10.2 Estado vacío con sugerencias cuando no sigue tiendas
  - _Requisitos: R9_

- [ ] 11. Detalle de publicación (reacciones + comentarios)
  - [ ] 11.1 `post_detail_screen.dart`: contenido, `ReactionBar`, lista de comentarios, input
  - [ ] 11.2 Menú ⋮ con Editar/Eliminar (solo autor) + confirmación de borrado
  - _Requisitos: R10, R11, R12_

- [ ] 12. Editor de publicación (CRUD)
  - [ ] 12.1 `post_editor_screen.dart` para crear y editar (precarga en edición)
  - [ ] 12.2 Bloquear creación/edición para perfil comprador
  - _Requisitos: R10_

- [ ] 13. Perfiles anidados
  - [ ] 13.1 `profile_switcher_sheet.dart` (agrupado por tipo, marca el activo, re-tema animado)
  - [ ] 13.2 `create_profile_screen.dart` (vendedor/servicios, segmented control)
  - [ ] 13.3 `account_screen.dart` (lista de perfiles, ajustes, cerrar sesión)
  - _Requisitos: R5, R6, R7_

- [ ] 14. Perfil de tienda y seguir
  - [ ] 14.1 `store_profile_screen.dart` (header, seguidores, grid de posts, Seguir/Contactar)
  - [ ] 14.2 Conectar seguir/dejar de seguir con el feed
  - _Requisitos: R9, R13, R14_

- [ ] 15. Chat básico
  - [ ] 15.1 `conversations_screen.dart` (lista con último mensaje, no leídos)
  - [ ] 15.2 `chat_screen.dart` (burbujas, envío con color del perfil, respuesta automática)
  - _Requisitos: R13_

- [ ] 16. Verificación y pulido
  - [ ] 16.1 Correr `flutter analyze` y resolver warnings
  - [ ] 16.2 Verificar navegación completa y cambio de tema entre perfiles
  - [ ] 16.3 Correr en Chrome (`flutter run -d chrome`) y validar los flujos principales
  - _Requisitos: todos_
```

