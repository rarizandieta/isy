import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatting.dart';
import '../../core/theme/profile_palettes.dart';
import '../../data/chat_controller.dart';
import '../../data/feed_controller.dart';
import '../../data/session_controller.dart';
import '../../models/profile.dart';
import '../../widgets/comment_tile.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/promoted_badge.dart';
import '../../widgets/reaction_bar.dart';
import '../chat/chat_screen.dart';
import 'post_editor_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _addComment(FeedController feed, SessionController session) {
    final text = _comment.text.trim();
    if (text.isEmpty) return;
    final profile = session.activeProfile;
    feed.addComment(
      widget.postId,
      authorName: profile.displayName,
      avatarSeed: profile.displayName.hashCode,
      text: text,
    );
    _comment.clear();
    FocusScope.of(context).unfocus();
  }

  Future<void> _confirmDelete(FeedController feed) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content:
            const Text('¿Seguro que quieres eliminar esta publicación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      feed.deletePost(widget.postId);
      Navigator.pop(context);
    }
  }

  void _contactStore(FeedController feed, ChatController chat, Profile store) {
    final conv = chat.ensureConversationWithStore(store);
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(conversationId: conv.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<FeedController>();
    final session = context.watch<SessionController>();
    final post = feed.postById(widget.postId);

    if (post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Publicación')),
        body: const Center(child: Text('La publicación ya no existe.')),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final comments = feed.commentsFor(post.id);
    final isOwnPost =
        session.profiles.any((p) => p.id == post.storeProfileId);
    final gradient = gradientForSeed(post.imageSeed);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicación'),
        actions: [
          if (isOwnPost)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => PostEditorScreen(existing: post),
                    ),
                  );
                } else if (value == 'delete') {
                  _confirmDelete(feed);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
            ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                ProfileAvatar(
                  name: post.storeName,
                  seed: post.imageSeed,
                  color: brandColorFor(post.storeType),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.storeName,
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                      Text(timeAgo(post.createdAt),
                          style: TextStyle(
                              fontSize: 12, color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                if (post.isPromoted) const PromotedBadge(),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(post.storeType.icon,
                    size: 72, color: Colors.white.withValues(alpha: 0.85)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(post.body, style: const TextStyle(height: 1.4)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (post.price != null)
                      Text(
                        priceLabel(post.price),
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    const Spacer(),
                    if (!isOwnPost)
                      FilledButton.icon(
                        onPressed: () {
                          final store = feed.storeById(post.storeProfileId) ??
                              Profile(
                                id: post.storeProfileId,
                                type: post.storeType,
                                displayName: post.storeName,
                                isOwnedByUser: false,
                              );
                          _contactStore(
                              feed, context.read<ChatController>(), store);
                        },
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text('Contactar'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 44),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text('Reacciones',
                    style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                Text('${post.totalReactions}',
                    style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ReactionBar(
              post: post,
              onToggle: (type) => feed.toggleReaction(post.id, type),
            ),
          ),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Comentarios (${post.commentCount})',
                style: Theme.of(context).textTheme.titleSmall),
          ),
          const SizedBox(height: 4),
          if (comments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('Sé el primero en comentar',
                    style: TextStyle(color: scheme.onSurfaceVariant)),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (final c in comments) CommentTile(comment: c),
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _comment,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _addComment(feed, session),
                  decoration: const InputDecoration(
                    hintText: 'Escribe un comentario',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () => _addComment(feed, session),
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
