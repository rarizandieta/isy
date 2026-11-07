import 'package:flutter/material.dart';

import '../core/formatting.dart';
import '../models/comment.dart';
import 'profile_avatar.dart';

/// Fila de comentario: avatar, autor, tiempo y texto. Resalta los propios.
class CommentTile extends StatelessWidget {
  final Comment comment;

  const CommentTile({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileAvatar(
            name: comment.authorName,
            seed: comment.authorAvatarSeed,
            radius: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: comment.isMine
                    ? scheme.primaryContainer.withValues(alpha: 0.5)
                    : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          comment.isMine ? 'Tú' : comment.authorName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeAgo(comment.createdAt),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(comment.text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
