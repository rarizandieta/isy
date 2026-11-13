import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/store_repository.dart';
import '../../domain/models/mini_store.dart';
import '../../domain/models/profile.dart';
import '../profile/create_profile_view.dart';
import '../shared/profile_ui.dart';
import '../store/store_editor_view.dart';
import '../store/store_view.dart';
import '../theme/theme_controller.dart';
import 'account_view_model.dart';

/// Pantalla "Cuenta": perfil del usuario, acceso a la Mini Tienda (cuando el
/// perfil activo es vendedor), cambio de perfil y cierre de sesión.
class AccountView extends StatelessWidget {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AccountViewModel(
        ctx.read<AuthRepository>(),
        ctx.read<StoreRepository>(),
      ),
      child: const _AccountScreen(),
    );
  }
}

class _AccountScreen extends StatelessWidget {
  const _AccountScreen();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AccountViewModel>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Cuenta')),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => context.read<AccountViewModel>().refresh(),
              child: ListView(
                children: [
                  const SizedBox(height: 12),
                  _Header(vm: vm),
                  const SizedBox(height: 16),
                  if (vm.isSellerActive) ...[
                    const _SectionHeader('Mi Mini Tienda'),
                    _MiniStoreTile(vm: vm),
                    const Divider(height: 24),
                  ],
                  const _SectionHeader('Mis perfiles'),
                  for (final p in vm.profiles)
                    _ProfileTile(
                      profile: p,
                      isActive: p.id == vm.activeProfile?.id,
                      onTap: () => _switchProfile(context, p.id),
                    ),
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.add)),
                    title: const Text('Crear nuevo perfil'),
                    subtitle: const Text('Vendedor o servicios'),
                    onTap: () => _openCreateProfile(context),
                  ),
                  const Divider(height: 24),
                  const _SectionHeader('Ajustes'),
                  _ThemeTile(
                    mode: context.watch<ThemeController>().mode,
                    onChanged: (m) => context.read<ThemeController>().setMode(m),
                  ),
                  ListTile(
                    leading: Icon(Icons.logout, color: scheme.error),
                    title: Text('Cerrar sesión', style: TextStyle(color: scheme.error)),
                    onTap: () => _logout(context),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Future<void> _switchProfile(BuildContext context, int profileId) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<AccountViewModel>().switchProfile(profileId);
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _openCreateProfile(BuildContext context) async {
    final vm = context.read<AccountViewModel>();
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const CreateProfileView()),
    );
    await vm.refresh();
  }

  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    await context.read<AccountViewModel>().logout();
    // El AuthGate (raíz) detecta el fin de sesión y muestra la bienvenida.
    navigator.popUntil((route) => route.isFirst);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.vm});
  final AccountViewModel vm;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = vm.user;
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: scheme.primaryContainer,
            child: Text(
              _initials(user?.fullName ?? 'Usuario'),
              style: TextStyle(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            user?.fullName ?? 'Usuario',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(user?.email ?? '', style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  static String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.substring(0, 1);
    final last = parts.length > 1 ? parts.last.substring(0, 1) : '';
    return (first + last).toUpperCase();
  }
}

/// Tile de la Mini Tienda: "Crear Mini Tienda" si el perfil vendedor aún no tiene
/// tienda, o "Configurar Mini Tienda" si ya existe.
class _MiniStoreTile extends StatelessWidget {
  const _MiniStoreTile({required this.vm});
  final AccountViewModel vm;

  @override
  Widget build(BuildContext context) {
    const sellerColor = Color(0xFF8E24AA);

    if (vm.storeLoading) {
      return const Card(
        margin: EdgeInsets.symmetric(horizontal: 12),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: sellerColor,
            child: Icon(Icons.storefront, color: Colors.white),
          ),
          title: Text('Mi Mini Tienda'),
          trailing: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    final store = vm.myStore;
    final hasStore = store != null;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: sellerColor,
          child: Icon(Icons.storefront, color: Colors.white),
        ),
        title: Text(
          hasStore ? 'Configurar Mini Tienda' : 'Crear Mini Tienda',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(hasStore ? store.name : 'Arma tu vitrina de productos'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _open(context, store),
      ),
    );
  }

  /// Con tienda -> abre la vitrina (desde ahí se personaliza). Sin tienda ->
  /// abre el editor en modo creación.
  Future<void> _open(BuildContext context, MiniStore? store) async {
    final vm = context.read<AccountViewModel>();
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => store != null
            ? StoreView(store: store)
            : StoreEditorView(createForName: vm.activeProfile?.displayName),
      ),
    );
    await vm.refresh();
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.profile,
    required this.isActive,
    required this.onTap,
  });

  final Profile profile;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = profileTypeColor(profile.type);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(profileTypeIcon(profile.type), color: color),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              profileDisplayName(profile),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: 8),
            Icon(Icons.check_circle, size: 18, color: color),
          ],
        ],
      ),
      subtitle: Row(
        children: [
          Text(profileTypeLabel(profile.type)),
          if (profile.type == ProfileType.buyer) ...[
            const SizedBox(width: 6),
            Text('(tú)', style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}

/// Fila de ajuste de tema: muestra el modo actual y permite elegir entre
/// "Según el sistema", "Claro" y "Oscuro".
class _ThemeTile extends StatelessWidget {
  const _ThemeTile({required this.mode, required this.onChanged});

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.brightness_6_outlined),
      title: const Text('Tema'),
      subtitle: Text(themeModeLabel(mode)),
      trailing: PopupMenuButton<ThemeMode>(
        initialValue: mode,
        onSelected: onChanged,
        icon: const Icon(Icons.arrow_drop_down),
        itemBuilder: (_) => const [
          PopupMenuItem(value: ThemeMode.system, child: Text('Según el sistema')),
          PopupMenuItem(value: ThemeMode.light, child: Text('Claro')),
          PopupMenuItem(value: ThemeMode.dark, child: Text('Oscuro')),
        ],
      ),
      onTap: null,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

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
