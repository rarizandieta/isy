import 'package:flutter/material.dart';

import '../models/conversation.dart';
import '../models/message.dart';
import '../models/profile.dart';
import 'mock_data.dart';

/// Maneja conversaciones y mensajes del chat básico. Simula respuestas
/// automáticas de las tiendas tras un breve retraso.
class ChatController extends ChangeNotifier {
  final List<Conversation> _conversations = MockData.conversations();
  final Map<String, List<Message>> _messages = MockData.messages();

  List<Conversation> get conversations {
    final list = [..._conversations];
    list.sort((a, b) => b.lastTime.compareTo(a.lastTime));
    return list;
  }

  int get totalUnread =>
      _conversations.fold(0, (sum, c) => sum + c.unread);

  List<Message> messagesFor(String conversationId) =>
      List.unmodifiable(_messages[conversationId] ?? const []);

  Conversation? conversationById(String id) {
    for (final c in _conversations) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Devuelve la conversación con la tienda, creándola si no existe.
  Conversation ensureConversationWithStore(Profile store) {
    final existing = _conversations
        .where((c) => c.storeProfileId == store.id)
        .toList();
    if (existing.isNotEmpty) return existing.first;

    final conv = Conversation(
      id: 'conv_${DateTime.now().microsecondsSinceEpoch}',
      storeProfileId: store.id,
      storeName: store.displayName,
      storeType: store.type,
      lastMessage: 'Inicia la conversación',
      lastTime: DateTime.now(),
    );
    _conversations.add(conv);
    _messages[conv.id] = [];
    notifyListeners();
    return conv;
  }

  void markRead(String conversationId) {
    final index =
        _conversations.indexWhere((c) => c.id == conversationId);
    if (index < 0 || _conversations[index].unread == 0) return;
    _conversations[index] = _conversations[index].copyWith(unread: 0);
    notifyListeners();
  }

  void sendMessage(String conversationId, String text) {
    final list = _messages.putIfAbsent(conversationId, () => []);
    list.add(
      Message(
        id: 'm_${DateTime.now().microsecondsSinceEpoch}',
        conversationId: conversationId,
        text: text,
        isMine: true,
        time: DateTime.now(),
      ),
    );
    _touchConversation(conversationId, text, unread: 0);
    notifyListeners();

    // Respuesta automática simulada de la tienda.
    Future.delayed(const Duration(milliseconds: 900), () {
      final current = _messages[conversationId];
      if (current == null) return;
      const reply = '¡Gracias por tu mensaje! En breve te atendemos 🙌';
      current.add(
        Message(
          id: 'm_${DateTime.now().microsecondsSinceEpoch}',
          conversationId: conversationId,
          text: reply,
          isMine: false,
          time: DateTime.now(),
        ),
      );
      _touchConversation(conversationId, reply, unread: 0);
      notifyListeners();
    });
  }

  void _touchConversation(String id, String lastMessage, {int unread = 0}) {
    final index = _conversations.indexWhere((c) => c.id == id);
    if (index < 0) return;
    _conversations[index] = _conversations[index].copyWith(
      lastMessage: lastMessage,
      lastTime: DateTime.now(),
      unread: unread,
    );
  }
}
