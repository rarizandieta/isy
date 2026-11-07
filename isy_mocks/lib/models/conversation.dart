import 'profile.dart';

/// Conversación de chat entre el usuario y una tienda.
class Conversation {
  final String id;
  final String storeProfileId;
  final String storeName;
  final ProfileType storeType;
  final String lastMessage;
  final DateTime lastTime;
  final int unread;

  const Conversation({
    required this.id,
    required this.storeProfileId,
    required this.storeName,
    required this.storeType,
    required this.lastMessage,
    required this.lastTime,
    this.unread = 0,
  });

  Conversation copyWith({
    String? lastMessage,
    DateTime? lastTime,
    int? unread,
  }) {
    return Conversation(
      id: id,
      storeProfileId: storeProfileId,
      storeName: storeName,
      storeType: storeType,
      lastMessage: lastMessage ?? this.lastMessage,
      lastTime: lastTime ?? this.lastTime,
      unread: unread ?? this.unread,
    );
  }
}
