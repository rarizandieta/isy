/// Mensaje individual dentro de una conversación.
class Message {
  final String id;
  final String conversationId;
  final String text;

  /// true = enviado por el perfil activo del usuario.
  final bool isMine;
  final DateTime time;

  const Message({
    required this.id,
    required this.conversationId,
    required this.text,
    required this.isMine,
    required this.time,
  });
}
