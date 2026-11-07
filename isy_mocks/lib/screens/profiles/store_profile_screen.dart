import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatting.dart';
import '../../core/theme/profile_palettes.dart';
import '../../data/chat_controller.dart';
import '../../data/feed_controller.dart';
import '../../data/mini_store_controller.dart';
import '../../models/profile.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/profile_badge.dart';
import '../chat/chat_screen.dart';
import '../feed/post_detail_screen.dart';
import '../mini_store/mini_store_screen.dart';

class StoreProfileScreen extends StatelessWidget {
  final String storeId;

  const StoreProfileScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<FeedController>();
    final store = feed.storeById(storeId);
    final posts = feed.postsByStore(storeId);
    final scheme = Theme.of(context).colorScheme;

    if (store == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tienda')),
        body: const Center(child: Text('Tienda no encontrada.')),
      );
    }

    final color = brandColorFor(store.type);
    final following = feed.isFollowing(store.id);
    final miniStore =
        context.watch<MiniStoreController>().storeForProfile(storeId);

    return Scaffold(
      appBar: AppBar(title: Text(store.displayName)),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  ProfileAvatar(
                    name: store.displayName,
                    color: color,
                    icon: store.type.icon,
                    radius: 42,
                  ),
                  const SizedBox(height: 12),
                  Text(store.displayName,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  ProfileBadge(type: store.type),
                  const SizedBox(height: 10),
                  Text(
                    '${_fmt(store.followers)} seguidores · ${posts.length} publicaciones',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  if (store.description != null) ...[
                    const SizedBox(height: 10),
                    Text(store.description!, textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 16),
                  if (store.isOwnedByUser)
                    const Chip(
                      avatar: Icon(Icons.verified, size: 18),
                      label: Text('Tu tienda'),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: following
                              ? OutlinedButton.icon(
                                  onPressed: () =>
                                      feed.toggleFollow(store.id),
                                  icon: const Icon(Icons.check),
                                  label: const Text('Siguiendo'),
                                )
                              : FilledButton.icon(
                                  onPressed: () =>
                                      feed.toggleFollow(store.id),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Seguir'),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _contact(context, store),
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Contactar'),
                          ),
                        ),
                      ],
                    ),
                  if (miniStore != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                MiniStoreScreen(storeId: miniStore.id),
                          ),
                        ),
                        icon: const Icon(Icons.storefront_outlined),
                        label: const Text('Ver Mini Tienda'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (posts.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text('Aún no hay publicaciones',
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final post = posts[i];
                    final gradient = gradientForSeed(post.imageSeed);
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              PostDetailScreen(postId: post.id),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(colors: gradient),
                              ),
                              child: Icon(post.storeType.icon,
                                  color:
                                      Colors.white.withValues(alpha: 0.85)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(post.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          if (post.price != null)
                            Text(priceLabel(post.price),
                                style: TextStyle(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w700)),
                        ],
                      ),
                    );
                  },
                  childCount: posts.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  void _contact(BuildContext context, Profile store) {
    final conv =
        context.read<ChatController>().ensureConversationWithStore(store);
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(conversationId: conv.id),
      ),
    );
  }

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}
