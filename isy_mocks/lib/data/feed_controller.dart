import 'package:flutter/material.dart';

import '../models/comment.dart';
import '../models/post.dart';
import '../models/profile.dart';
import '../models/reaction.dart';
import 'mock_data.dart';

/// Maneja el feed, el CRUD de publicaciones, reacciones, comentarios y el
/// seguimiento de tiendas. Todo en memoria.
class FeedController extends ChangeNotifier {
  final List<Post> _posts = MockData.posts();
  final Map<String, List<Comment>> _comments = MockData.comments();
  final Set<String> _followed = MockData.followedStoreIds();
  final List<Profile> _stores = [
    ...MockData.externalStores(),
    ...MockData.ownedProfiles().where((p) => p.type.canPublish),
  ];

  /// Feed del dashboard: publicaciones promovidas (admin) + tiendas seguidas.
  /// Las promovidas se muestran primero.
  List<Post> feed() {
    final list = _posts
        .where((p) => p.isPromoted || _followed.contains(p.storeProfileId))
        .toList();
    list.sort((a, b) {
      if (a.isPromoted != b.isPromoted) return a.isPromoted ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  /// Tiendas externas sugeridas en Explorar.
  List<Profile> get discoverStores =>
      _stores.where((s) => !s.isOwnedByUser).toList();

  Post? postById(String id) {
    for (final p in _posts) {
      if (p.id == id) return p;
    }
    return null;
  }

  Profile? storeById(String id) {
    for (final s in _stores) {
      if (s.id == id) return s;
    }
    return null;
  }

  List<Post> postsByStore(String storeId) {
    final list = _posts.where((p) => p.storeProfileId == storeId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<Comment> commentsFor(String postId) =>
      List.unmodifiable(_comments[postId] ?? const []);

  // --- Reacciones ---
  void toggleReaction(String postId, ReactionType type) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index < 0) return;
    final post = _posts[index];
    final counts = Map<ReactionType, int>.from(post.reactionCounts);
    ReactionType? mine;

    if (post.myReaction == type) {
      counts[type] = (counts[type] ?? 1) - 1;
      if ((counts[type] ?? 0) <= 0) counts.remove(type);
      mine = null;
    } else {
      final previous = post.myReaction;
      if (previous != null) {
        counts[previous] = (counts[previous] ?? 1) - 1;
        if ((counts[previous] ?? 0) <= 0) counts.remove(previous);
      }
      counts[type] = (counts[type] ?? 0) + 1;
      mine = type;
    }

    _posts[index] = post.copyWith(reactionCounts: counts, myReaction: mine);
    notifyListeners();
  }

  // --- Comentarios ---
  void addComment(
    String postId, {
    required String authorName,
    required int avatarSeed,
    required String text,
  }) {
    final list = _comments.putIfAbsent(postId, () => []);
    list.insert(
      0,
      Comment(
        id: 'c_${DateTime.now().microsecondsSinceEpoch}',
        postId: postId,
        authorName: authorName,
        authorAvatarSeed: avatarSeed,
        text: text,
        createdAt: DateTime.now(),
        isMine: true,
      ),
    );
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index >= 0) {
      _posts[index] =
          _posts[index].copyWith(commentCount: _posts[index].commentCount + 1);
    }
    notifyListeners();
  }

  // --- CRUD de publicaciones ---
  Post createPost({
    required Profile store,
    required String title,
    required String body,
    double? price,
  }) {
    final post = Post(
      id: 'post_${DateTime.now().microsecondsSinceEpoch}',
      storeProfileId: store.id,
      storeName: store.displayName,
      storeType: store.type,
      title: title,
      body: body,
      imageSeed: DateTime.now().millisecond + 1,
      price: price,
      createdAt: DateTime.now(),
      reactionCounts: const {},
      commentCount: 0,
    );
    _posts.insert(0, post);
    notifyListeners();
    return post;
  }

  void updatePost(
    String postId, {
    required String title,
    required String body,
    double? price,
  }) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index < 0) return;
    _posts[index] =
        _posts[index].copyWith(title: title, body: body, price: price);
    notifyListeners();
  }

  void deletePost(String postId) {
    _posts.removeWhere((p) => p.id == postId);
    _comments.remove(postId);
    notifyListeners();
  }

  // --- Seguir tiendas ---
  bool isFollowing(String storeId) => _followed.contains(storeId);

  void toggleFollow(String storeId) {
    if (!_followed.add(storeId)) {
      _followed.remove(storeId);
    }
    notifyListeners();
  }
}
