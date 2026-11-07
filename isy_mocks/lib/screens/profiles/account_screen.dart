import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routing/routes.dart';
import '../../core/theme/profile_palettes.dart';
import '../../data/mini_store_controller.dart';
import '../../data/session_controller.dart';
import '../../models/profile.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/profile_badge.dart';
import '../mini_store/mini_store_editor_screen.dart';
import '../mini_store/mini_store_screen.dart';
import 'create_profile_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> _confirmDelete(
      BuildContext context, SessionController session, Profile p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar "${p.displayName}"'),
        content: const Text(
            'Se eliminará este perfil y sus publicaciones de la demo.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true) session.removeProfile(p.id);
  }

  void _logout(BuildContext context) {
    context.read<SessionController>().logout();
    Navigator.pushNamedAndRemoveUntil(context, Routes.welcome, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final user = session.user;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      children: [
        const SizedBox(height: 12),
        Center(
          child: Column(
            children: [
              ProfileAvatar(
                name: user?.name ?? 'Usuario',
                seed: user?.avatarSeed ?? 0,
                radius: 40,
              ),
              const SizedBox(height: 10),
              Text(user?.name ?? 'Usuario',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              Text(user?.email ?? '',
                  style: TextStyle(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (session.activeType == ProfileType.seller) ...[
          _SectionHeader(title: 'Mi Mini Tienda'),
          _MiniStoreTile(profile: session.activeProfile),
          const Divider(height: 24),
        ],
        _SectionHeader(title: 'Mis perfiles'),
        for (final p in session.profiles)
          ListTile(
            leading: ProfileAvatar(
              name: p.displayName,
              color: brandColorFor(p.type),
              icon: p.type.icon,
              radius: 20,
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(p.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                if (p.id == session.activeProfile.id)
                  Icon(Icons.check_circle,
                      size: 18, color: brandColorFor(p.type)),
              ],
            ),
            subtitle: Row(
              children: [
                ProfileBadge(type: p.type, dense: true),
                if (p.type == ProfileType.buyer) ...[
                  const SizedBox(width: 6),
                  Text('(tú)', style: TextStyle(color: scheme.onSurfaceVariant)),
                ],
              ],
            ),
            trailing: p.type == ProfileType.buyer
                ? null
                : IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(context, session, p),
                  ),
            onTap: () => session.setActiveProfile(p.id),
          ),
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.add)),
          title: const Text('Crear nuevo perfil'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => const CreateProfileScreen(),
            ),
          ),
        ),
        const Divider(height: 24),
        _SectionHeader(title: 'Ajustes'),
        ListTile(
          leading: const Icon(Icons.brightness_6_outlined),
          title: const Text('Tema'),
          subtitle: Text(_themeLabel(session.themeMode)),
          trailing: _ThemeMenu(
            value: session.themeMode,
            onChanged: session.setThemeMode,
          ),
        ),
        ListTile(
          leading: Icon(Icons.logout, color: scheme.error),
          title: Text('Cerrar sesión', style: TextStyle(color: scheme.error)),
          onTap: () => _logout(context),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Según el sistema';
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Oscuro';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

class _ThemeMenu extends StatelessWidget {
  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeMenu({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ThemeMode>(
      initialValue: value,
      onSelected: onChanged,
      icon: const Icon(Icons.arrow_drop_down),
      itemBuilder: (_) => const [
        PopupMenuItem(value: ThemeMode.system, child: Text('Según el sistema')),
        PopupMenuItem(value: ThemeMode.light, child: Text('Claro')),
        PopupMenuItem(value: ThemeMode.dark, child: Text('Oscuro')),
      ],
    );
  }
}


class _MiniStoreTile extends StatelessWidget {
  final Profile profile;
  const _MiniStoreTile({required this.profile});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MiniStoreController>();
    final store = controller.storeForProfile(profile.id);
    final accent = store != null ? store.accent : brandColorFor(profile.type);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: accent,
          child: const Icon(Icons.storefront, color: Colors.white),
        ),
        title: Text(
          store != null ? store.name : 'Crear tu Mini Tienda',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          store != null
              ? 'Ver y administrar tu vitrina'
              : 'Arma tu vitrina de productos',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          if (store != null) {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => MiniStoreScreen(storeId: store.id),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => MiniStoreEditorScreen(
                  createForProfileId: profile.id,
                  createForName: profile.displayName,
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
