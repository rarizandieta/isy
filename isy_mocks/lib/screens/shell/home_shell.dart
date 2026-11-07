import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/profile_palettes.dart';
import '../../data/chat_controller.dart';
import '../../data/session_controller.dart';
import '../../models/profile.dart';
import '../../widgets/isy_logo.dart';
import '../../widgets/profile_avatar.dart';
import '../chat/conversations_screen.dart';
import '../feed/dashboard_screen.dart';
import '../feed/discover_screen.dart';
import '../feed/post_editor_screen.dart';
import '../profiles/account_screen.dart';
import '../profiles/profile_switcher_sheet.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    DiscoverScreen(),
    ConversationsScreen(),
    AccountScreen(),
  ];

  Widget _title() {
    switch (_index) {
      case 0:
        return const IsyLogo(fontSize: 24);
      case 1:
        return const Text('Explorar');
      case 2:
        return const Text('Mensajes');
      default:
        return const Text('Cuenta');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final scheme = Theme.of(context).colorScheme;
    final unread = context.watch<ChatController>().totalUnread;
    final active = session.activeProfile;
    final showFab = session.canPublish && (_index == 0 || _index == 1);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        elevation: 4,
        scrolledUnderElevation: 4,
        title: _title(),
        actions: [
          IconButton(
            tooltip: 'Notificaciones',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No tienes notificaciones nuevas')),
            ),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _ProfilePill(
                profile: active,
                onTap: () => showProfileSwitcher(context),
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(index: _index, children: _screens),
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const PostEditorScreen(),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Publicar'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: unread > 0
                ? Badge(
                    label: Text('$unread'),
                    child: const Icon(Icons.chat_bubble_outline),
                  )
                : const Icon(Icons.chat_bubble_outline),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: 'Mensajes',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Cuenta',
          ),
        ],
      ),
    );
  }
}

/// Píldora del perfil activo en el header. Muestra avatar + nombre y abre el
/// selector de perfiles. Teñida con el color de marca del perfil.
class _ProfilePill extends StatelessWidget {
  final Profile profile;
  final VoidCallback onTap;

  const _ProfilePill({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brand = brandColorFor(profile.type);

    return Material(
      color: brand.withValues(alpha: isDark ? 0.22 : 0.10),
      shape: StadiumBorder(
        side: BorderSide(color: brand.withValues(alpha: 0.45)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5, 4, 12, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProfileAvatar(
                name: profile.displayName,
                color: brand,
                icon: profile.type.icon,
                radius: 15,
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Actuando como · ${profile.type.label}',
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.1,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    profile.displayName,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Icon(Icons.unfold_more, size: 18, color: brand),
            ],
          ),
        ),
      ),
    );
  }
}
