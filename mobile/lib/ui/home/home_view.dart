import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/auth_repository.dart';
import '../shared/widgets/isy_logo.dart';
import 'home_view_model.dart';

/// Pantalla tras iniciar sesión. Superficie de pruebas del microservicio
/// identity: muestra el usuario (de /auth/me) y permite ejercitar /auth/me,
/// /auth/refresh y /auth/logout. Se autoenvuelve con su ViewModel.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => HomeViewModel(ctx.read<AuthRepository>()),
      child: const _HomeScreen(),
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final vm = context.watch<HomeViewModel>();
    final user = vm.user;

    return Scaffold(
      appBar: AppBar(
        title: const IsyLogo(fontSize: 26),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: vm.busy ? null : () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: scheme.primaryContainer,
                      child: Text(
                        _initials(user.fullName),
                        style: TextStyle(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Hola, ${user.fullName}!',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Roles', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final role in user.roles)
                      Chip(
                        avatar:
                            const Icon(Icons.verified_user_outlined, size: 18),
                        label: Text(role),
                      ),
                    if (user.roles.isEmpty) const Text('— sin roles —'),
                  ],
                ),
                const SizedBox(height: 24),
                _SessionCard(
                  accessToken: vm.accessToken,
                  refreshToken: vm.refreshToken,
                ),
                const SizedBox(height: 24),
                Text(
                  'Probar endpoints',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: vm.busy ? null : () => _reloadMe(context),
                  icon: const Icon(Icons.person_search_outlined),
                  label: const Text('Probar GET /auth/me'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: vm.busy ? null : () => _refresh(context),
                  icon: const Icon(Icons.autorenew),
                  label: const Text('Refrescar token (POST /auth/refresh)'),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: vm.busy ? null : () => _logout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión (POST /auth/logout)'),
                ),
                if (vm.busy) ...[
                  const SizedBox(height: 20),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
    );
  }

  Future<void> _reloadMe(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = await context.read<HomeViewModel>().reloadMe();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _refresh(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = await context.read<HomeViewModel>().refreshSession();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _logout(BuildContext context) async {
    // El AuthGate detecta el cambio de estado y vuelve a la bienvenida.
    await context.read<HomeViewModel>().logout();
  }

  static String _initials(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.substring(0, 1);
    final last = parts.length > 1 ? parts.last.substring(0, 1) : '';
    return (first + last).toUpperCase();
  }
}

/// Tarjeta con los datos de la sesión actual (tokens enmascarados).
class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.accessToken, required this.refreshToken});

  final String? accessToken;
  final String? refreshToken;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.vpn_key_outlined, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'Sesión activa',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _TokenRow(label: 'Access token', value: accessToken),
          const SizedBox(height: 8),
          _TokenRow(label: 'Refresh token', value: refreshToken),
        ],
      ),
    );
  }
}

class _TokenRow extends StatelessWidget {
  const _TokenRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        SelectableText(
          _mask(value),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          maxLines: 2,
        ),
      ],
    );
  }

  static String _mask(String? token) {
    if (token == null || token.isEmpty) return '—';
    if (token.length <= 24) return token;
    return '${token.substring(0, 14)}…${token.substring(token.length - 8)}';
  }
}
