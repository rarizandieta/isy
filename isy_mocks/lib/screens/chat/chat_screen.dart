import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatting.dart';
import '../../core/theme/profile_palettes.dart';
import '../../data/chat_controller.dart';
import '../../models/message.dart';
import '../../models/profile.dart';
import '../../widgets/profile_avatar.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatController>().markRead(widget.conversationId);
      _jumpToBottom();
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _jumpToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent + 80,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    context.read<ChatController>().sendMessage(widget.conversationId, text);
    _input.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();
    final conversation = chat.conversationById(widget.conversationId);
    final messages = chat.messagesFor(widget.conversationId);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ProfileAvatar(
              name: conversation?.storeName ?? '?',
              color: brandColorFor(conversation?.storeType ?? ProfileType.buyer),
              icon: (conversation?.storeType ?? ProfileType.buyer).icon,
              radius: 16,
            ),
            const SizedBox(width: 10),
            Text(conversation?.storeName ?? 'Chat'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, i) => _Bubble(message: messages[i]),
            ),
          ),
          _Composer(controller: _input, onSend: _send),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final Message message;

  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mine = message.isMine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: mine ? scheme.onPrimary : scheme.onSurface,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              mine ? '${timeAgo(message.time)} · Enviado' : timeAgo(message.time),
              style: TextStyle(
                fontSize: 10.5,
                color: (mine ? scheme.onPrimary : scheme.onSurfaceVariant)
                    .withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _Composer({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Escribe un mensaje',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: onSend,
              icon: const Icon(Icons.send),
              style: IconButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
