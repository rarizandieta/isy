import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formatting.dart';
import '../core/theme/profile_palettes.dart';
import '../data/feed_controller.dart';
import '../models/post.dart';
import '../models/profile.dart';
import 'profile_avatar.dart';
import 'promoted_badge.dart';
import 'reaction_bar.dart';

/// Tarjeta de publicación para el feed.
class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onOpen;
  final VoidCallback? onOpenStore;

  const PostCard({
    super.key,
    required this.post,
    required this.onOpen,
    this.onOpenStore,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final feed = context.read<FeedController>();
    final gradient = gradientForSeed(post.imageSeed);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  ProfileAvatar(
                    name: post.storeName,
                    seed: post.imageSeed,
                    color: brandColorFor(post.storeType),
                    radius: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: onOpenStore,
                          child: Text(
                            post.storeName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Text(
                          timeAgo(post.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (post.isPromoted) const PromotedBadge(),
                ],
              ),
            ),
            // Imagen placeholder
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    post.storeType.icon,
                    size: 56,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),
            // Contenido
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          post.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (post.price != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            priceLabel(post.price),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    post.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Acciones
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Row(
                children: [
                  ReactionBar(
                    post: post,
                    compact: true,
                    onToggle: (type) => feed.toggleReaction(post.id, type),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.mode_comment_outlined, size: 18),
                    label: Text('${post.commentCount}'),
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
