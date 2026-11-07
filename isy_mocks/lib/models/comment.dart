/// Comentario en una publicación.
class Comment {
  final String id;
  final String postId;
  final String authorName;
  final int authorAvatarSeed;
  final String text;
  final DateTime createdAt;
  final bool isMine;

  const Comment({
    required this.id,
    required this.postId,
    required this.authorName,
    required this.authorAvatarSeed,
    required this.text,
    required this.createdAt,
    this.isMine = false,
  });
}
