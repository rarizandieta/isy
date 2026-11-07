import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/profile_palettes.dart';
import '../../data/session_controller.dart';
import '../../models/profile.dart';
import '../../widgets/profile_avatar.dart';
import 'create_profile_screen.dart';

/// Abre el selector de perfiles como bottom sheet.
Future<void> showProfileSwitcher(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _ProfileSwitcherSheet(),
  );
}

class _ProfileSwitcherSheet extends StatelessWidget {
  const _ProfileSwitcherSheet();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final active = session.activeProfile;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              'Cambiar de perfil',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          for (final type in ProfileType.values)
            ..._buildGroup(context, session, type, active.id),
          const Divider(height: 24),
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.add)),
            title: const Text('Crear nuevo perfil'),
            subtitle: const Text('Vendedor o servicios'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const CreateProfileScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  List<Widget> _buildGroup(
    BuildContext context,
    SessionController session,
    ProfileType type,
    String activeId,
  ) {
    final profiles = session.profilesOfType(type);
    if (profiles.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        child: Text(
          type.label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
        ),
      ),
      for (final p in profiles)
        ListTile(
          leading: ProfileAvatar(
            name: p.displayName,
            color: brandColorFor(p.type),
            icon: p.type.icon,
            radius: 20,
          ),
          title: Text(p.displayName),
          subtitle: p.category != null ? Text(p.category!) : null,
          trailing: p.id == activeId
              ? Icon(Icons.check_circle,
                  color: brandColorFor(p.type))
              : null,
          onTap: () {
            session.setActiveProfile(p.id);
            Navigator.pop(context);
          },
        ),
    ];
  }
}
