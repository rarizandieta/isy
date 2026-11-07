import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatting.dart';
import '../../core/theme/profile_palettes.dart';
import '../../data/chat_controller.dart';
import '../../models/profile.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/profile_avatar.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();
    final conversations = chat.conversations;

    if (conversations.isEmpty) {
      return const EmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'Sin conversaciones',
        message: 'Contacta una tienda desde una publicación para empezar.',
      );
    }

    return ListView.separated(
      itemCount: conversations.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, i) {
        final c = conversations[i];
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: ProfileAvatar(
            name: c.storeName,
            color: brandColorFor(c.storeType),
            icon: c.storeType.icon,
            radius: 24,
          ),
          title: Text(
            c.storeName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            c.lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeAgo(c.lastTime),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              if (c.unread > 0)
                Badge(label: Text('${c.unread}'))
              else
                const SizedBox(height: 16),
            ],
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ChatScreen(conversationId: c.id),
            ),
          ),
        );
      },
    );
  }
}
