import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routing/routes.dart';
import 'core/theme/app_theme.dart';
import 'data/chat_controller.dart';
import 'data/feed_controller.dart';
import 'data/mini_store_controller.dart';
import 'data/session_controller.dart';

/// Raíz de la app. Conecta los providers y aplica el tema del perfil activo.
class IsyApp extends StatelessWidget {
  const IsyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionController()),
        ChangeNotifierProvider(create: (_) => FeedController()),
        ChangeNotifierProvider(create: (_) => ChatController()),
        ChangeNotifierProvider(create: (_) => MiniStoreController()),
      ],
      child: Consumer<SessionController>(
        builder: (context, session, _) {
          final type = session.activeType;
          return MaterialApp(
            title: 'isi',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(type, Brightness.light),
            darkTheme: buildTheme(type, Brightness.dark),
            themeMode: session.themeMode,
            initialRoute: session.isLoggedIn ? Routes.home : Routes.welcome,
            onGenerateRoute: Routes.onGenerateRoute,
          );
        },
      ),
    );
  }
}
