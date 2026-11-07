import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/feed_controller.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/post_card.dart';
import '../profiles/store_profile_screen.dart';
import 'post_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _refresh() => Future.delayed(const Duration(milliseconds: 700));

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<FeedController>();
    final posts = feed.feed();

    if (posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: EmptyState(
                icon: Icons.storefront_outlined,
                title: 'Tu feed está vacío',
                message:
                    'Sigue tiendas desde Explorar para ver sus publicaciones aquí.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: posts.length,
        itemBuilder: (context, i) {
          final post = posts[i];
          return PostCard(
            post: post,
            onOpen: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => PostDetailScreen(postId: post.id),
              ),
            ),
            onOpenStore: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) =>
                    StoreProfileScreen(storeId: post.storeProfileId),
              ),
            ),
          );
        },
      ),
    );
  }
}
