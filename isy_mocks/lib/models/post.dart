import 'profile.dart';
import 'reaction.dart';

const Object _sentinel = Object();

/// Publicación de una tienda (perfil vendedor o de servicios).
class Post {
  final String id;
  final String storeProfileId;
  final String storeName;
  final ProfileType storeType;
  final String title;
  final String body;

  /// Semilla determinística para generar el color/placeholder de imagen.
  final int imageSeed;
  final double? price;
  final bool isPromoted;
  final DateTime createdAt;
  final Map<ReactionType, int> reactionCounts;
  final ReactionType? myReaction;
  final int commentCount;

  const Post({
    required this.id,
    required this.storeProfileId,
    required this.storeName,
    required this.storeType,
    required this.title,
    required this.body,
    required this.imageSeed,
    required this.createdAt,
    this.price,
    this.isPromoted = false,
    this.reactionCounts = const {},
    this.myReaction,
    this.commentCount = 0,
  });

  int get totalReactions =>
      reactionCounts.values.fold(0, (sum, value) => sum + value);

  Post copyWith({
    String? title,
    String? body,
    int? imageSeed,
    Object? price = _sentinel,
    Map<ReactionType, int>? reactionCounts,
    Object? myReaction = _sentinel,
    int? commentCount,
  }) {
    return Post(
      id: id,
      storeProfileId: storeProfileId,
      storeName: storeName,
      storeType: storeType,
      title: title ?? this.title,
      body: body ?? this.body,
      imageSeed: imageSeed ?? this.imageSeed,
      price: identical(price, _sentinel) ? this.price : price as double?,
      isPromoted: isPromoted,
      createdAt: createdAt,
      reactionCounts: reactionCounts ?? this.reactionCounts,
      myReaction: identical(myReaction, _sentinel)
          ? this.myReaction
          : myReaction as ReactionType?,
      commentCount: commentCount ?? this.commentCount,
    );
  }
}
