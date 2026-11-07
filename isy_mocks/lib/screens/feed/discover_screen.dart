import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/profile_palettes.dart';
import '../../data/feed_controller.dart';
import '../../models/profile.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/profile_badge.dart';
import '../profiles/store_profile_screen.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<FeedController>();
    final stores = feed.discoverStores;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: stores.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, i) {
        final Profile store = stores[i];
        final following = feed.isFollowing(store.id);
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: ProfileAvatar(
            name: store.displayName,
            color: brandColorFor(store.type),
            icon: store.type.icon,
            radius: 24,
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  store.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ProfileBadge(type: store.type, dense: true),
            ],
          ),
          subtitle: Text(
            '${_followersLabel(store.followers)} · ${store.category ?? ''}',
          ),
          trailing: following
              ? OutlinedButton(
                  onPressed: () => feed.toggleFollow(store.id),
                  child: const Text('Siguiendo'),
                )
              : FilledButton(
                  onPressed: () => feed.toggleFollow(store.id),
                  child: const Text('Seguir'),
                ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => StoreProfileScreen(storeId: store.id),
            ),
          ),
        );
      },
    );
  }

  String _followersLabel(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k seguidores';
    return '$n seguidores';
  }
}
