import 'package:flutter/material.dart';

import '../core/theme/theme_extensions.dart';
import '../models/post.dart';
import '../models/reaction.dart';

/// Barra de reacciones con toggle y contador por tipo.
class ReactionBar extends StatelessWidget {
  final Post post;
  final void Function(ReactionType type) onToggle;
  final bool compact;

  const ReactionBar({
    super.key,
    required this.post,
    required this.onToggle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final type in ReactionType.values) ...[
          _ReactionChip(
            type: type,
            count: post.reactionCounts[type] ?? 0,
            active: post.myReaction == type,
            compact: compact,
            onTap: () => onToggle(type),
          ),
          if (type != ReactionType.values.last)
            SizedBox(width: compact ? 4 : 8),
        ],
      ],
    );
  }
}

class _ReactionChip extends StatelessWidget {
  final ReactionType type;
  final int count;
  final bool active;
  final bool compact;
  final VoidCallback onTap;

  const _ReactionChip({
    required this.type,
    required this.count,
    required this.active,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeColor =
        type == ReactionType.love ? context.isyColors.love : scheme.primary;
    final fg = active ? activeColor : scheme.onSurfaceVariant;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 10,
          vertical: compact ? 4 : 7,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? type.filledIcon : type.outlinedIcon,
              size: compact ? 18 : 20,
              color: fg,
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Text(
                '$count',
                style: TextStyle(
                  color: fg,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  fontSize: compact ? 12.5 : 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
