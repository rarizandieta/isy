import 'package:flutter/material.dart';

import '../account/account_view.dart';
import 'feed_view.dart';

/// Pantalla principal tras iniciar sesión: contenedor con la barra de
/// navegación inferior (Inicio, Explorar, Mensajes, Cuenta). Cada pestaña es una
/// pantalla completa (con su propio Scaffold) y se mantiene viva al cambiar de
/// pestaña gracias al [IndexedStack].
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _index = 0;

  static const _tabs = [
    FeedView(),
    _ComingSoon(
      title: 'Explorar',
      icon: Icons.search,
      message: 'Pronto podrás descubrir tiendas y buscar productos aquí.',
    ),
    _ComingSoon(
      title: 'Mensajes',
      icon: Icons.chat_bubble_outline,
      message: 'Pronto podrás chatear con las tiendas desde aquí.',
    ),
    AccountView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Mensajes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Cuenta',
          ),
        ],
      ),
    );
  }
}

/// Marcador de posición para pestañas aún no implementadas (Explorar/Mensajes).
class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.title, required this.icon, required this.message});

  final String title;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: scheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text('Próximamente', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
