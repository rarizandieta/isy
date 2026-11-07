import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatting.dart';
import '../../data/chat_controller.dart';
import '../../data/mini_store_controller.dart';
import '../../data/session_controller.dart';
import '../../models/mini_store.dart';
import '../../models/profile.dart';
import '../../models/store_product.dart';
import '../chat/chat_screen.dart';
import 'mini_store_editor_screen.dart';
import 'product_editor_screen.dart';

Color _darken(Color c, [double amount = .16]) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
}

class MiniStoreScreen extends StatelessWidget {
  final String storeId;

  const MiniStoreScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MiniStoreController>();
    final session = context.watch<SessionController>();
    final store = controller.storeById(storeId);

    if (store == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Esta Mini Tienda ya no existe.')),
      );
    }

    final isOwner =
        session.profiles.any((p) => p.id == store.sellerProfileId);

    // El dueño ve todo (incluidos borradores); el visitante solo lo publicado.
    List<StoreProduct> visible(List<StoreProduct> list) => isOwner
        ? list
        : list.where((p) => p.status == ProductStatus.published).toList();

    final featured = visible(controller.featured(store.id));

    return Scaffold(
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ProductEditorScreen(storeId: store.id),
                ),
              ),
              backgroundColor: store.accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Producto'),
            )
          : null,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Cover(store: store, isOwner: isOwner),
          _Header(store: store, isOwner: isOwner),
          if (featured.isNotEmpty) _FeaturedStrip(store: store, products: featured),
          for (final section in store.sections)
            _SectionBlock(
              store: store,
              title: section.name,
              products: visible(controller.productsOfSection(store.id, section.id)),
              isOwner: isOwner,
            ),
          // Productos sin sección
          _SectionBlock(
            store: store,
            title: 'Otros',
            products: visible(controller.productsOfSection(store.id, null)),
            isOwner: isOwner,
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  final MiniStore store;
  final bool isOwner;
  const _Cover({required this.store, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Stack(
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [store.accent, _darken(store.accent)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _RoundIcon(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                  ),
                  if (isOwner)
                    _RoundIcon(
                      icon: Icons.tune,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              MiniStoreEditorScreen(storeId: store.id),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 0,
            child: Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                color: store.accent,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: Theme.of(context).colorScheme.surface, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.storefront, color: Colors.white, size: 38),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onTap,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final MiniStore store;
  final bool isOwner;
  const _Header({required this.store, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  store.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              _OpenBadge(isOpen: store.isOpen),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: store.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(store.category,
                    style: TextStyle(
                        color: _darken(store.accent, .05),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (store.tagline.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('“${store.tagline}”',
                style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: scheme.onSurfaceVariant)),
          ],
          if (store.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(store.description),
          ],
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.schedule, text: store.schedule),
          const SizedBox(height: 4),
          _InfoRow(icon: Icons.place_outlined, text: store.zone),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in store.delivery)
                _Tag(icon: d.icon, label: d.label, color: store.accent),
              for (final p in store.payments)
                _Tag(icon: p.icon, label: p.label, color: scheme.secondary),
            ],
          ),
          const SizedBox(height: 14),
          if (isOwner)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            MiniStoreEditorScreen(storeId: store.id),
                      ),
                    ),
                    icon: const Icon(Icons.tune),
                    label: const Text('Personalizar tienda'),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _contact(context, store),
                    style: FilledButton.styleFrom(backgroundColor: store.accent),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Contactar'),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 4),
          const Divider(height: 24),
        ],
      ),
    );
  }

  void _contact(BuildContext context, MiniStore store) {
    final profile = Profile(
      id: store.sellerProfileId,
      type: ProfileType.seller,
      displayName: store.name,
      isOwnedByUser: false,
    );
    final conv =
        context.read<ChatController>().ensureConversationWithStore(profile);
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(conversationId: conv.id),
      ),
    );
  }
}

class _OpenBadge extends StatelessWidget {
  final bool isOpen;
  const _OpenBadge({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? const Color(0xFF2E7D32) : const Color(0xFF9E9E9E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 9, color: color),
          const SizedBox(width: 5),
          Text(isOpen ? 'Abierto' : 'Cerrado',
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13))),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Tag({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}

class _FeaturedStrip extends StatelessWidget {
  final MiniStore store;
  final List<StoreProduct> products;
  const _FeaturedStrip({required this.store, required this.products});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Icon(Icons.star_rounded, color: store.accent, size: 20),
              const SizedBox(width: 6),
              Text('Destacados',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(
              width: 150,
              child: ProductCard(store: store, product: products[i]),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SectionBlock extends StatelessWidget {
  final MiniStore store;
  final String title;
  final List<StoreProduct> products;
  final bool isOwner;
  const _SectionBlock({
    required this.store,
    required this.title,
    required this.products,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.72,
          ),
          itemCount: products.length,
          itemBuilder: (_, i) =>
              ProductCard(store: store, product: products[i]),
        ),
      ],
    );
  }
}

/// Tarjeta de producto. Al tocarla: dueño → editor; visitante → detalle.
class ProductCard extends StatelessWidget {
  final MiniStore store;
  final StoreProduct product;
  const ProductCard({super.key, required this.store, required this.product});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final session = context.read<SessionController>();
    final isOwner =
        session.profiles.any((p) => p.id == store.sellerProfileId);
    final gradient = gradientForSeed(product.imageSeed);
    final soldOut = product.stock == StockStatus.soldOut;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        if (isOwner) {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) =>
                  ProductEditorScreen(storeId: store.id, existing: product),
            ),
          );
        } else {
          _showProductSheet(context, store, product);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient),
                    ),
                    child: Icon(Icons.shopping_basket_outlined,
                        color: Colors.white.withValues(alpha: 0.8), size: 34),
                  ),
                  if (product.isFeatured)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Icon(Icons.star_rounded,
                          color: store.accent, size: 20),
                    ),
                  if (product.stock != StockStatus.available)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: _StockBadge(stock: product.stock),
                    ),
                  if (soldOut)
                    Container(color: Colors.black.withValues(alpha: 0.25)),
                  if (product.status == ProductStatus.draft)
                    const Positioned(
                      bottom: 6,
                      left: 6,
                      child: _DraftBadge(),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13.5)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(priceLabel(product.effectivePrice),
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: store.accent,
                              fontSize: 15)),
                      const SizedBox(width: 3),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 1.5),
                        child: Text('/ ${product.unit}',
                            style: TextStyle(
                                fontSize: 11.5,
                                color: scheme.onSurfaceVariant)),
                      ),
                    ],
                  ),
                  if (product.hasOffer)
                    Text(priceLabel(product.price),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: scheme.onSurfaceVariant,
                          decoration: TextDecoration.lineThrough,
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final StockStatus stock;
  const _StockBadge({required this.stock});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: stock.color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(stock.label,
          style: const TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

/// Distintivo para productos en borrador (solo visible para el dueño).
class _DraftBadge extends StatelessWidget {
  const _DraftBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit_note, color: Colors.white, size: 13),
          SizedBox(width: 3),
          Text('Borrador',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

void _showProductSheet(
    BuildContext context, MiniStore store, StoreProduct product) {
  final gradient = gradientForSeed(product.imageSeed);
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration:
                      BoxDecoration(gradient: LinearGradient(colors: gradient)),
                  child: Icon(Icons.shopping_basket_outlined,
                      color: Colors.white.withValues(alpha: 0.85), size: 48),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(product.name,
                        style: Theme.of(ctx)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                  _StockBadge(stock: product.stock),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(priceLabel(product.effectivePrice),
                      style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                          color: store.accent, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('/ ${product.unit}',
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                  ),
                  if (product.hasOffer) ...[
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(priceLabel(product.price),
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            decoration: TextDecoration.lineThrough,
                          )),
                    ),
                  ],
                ],
              ),
              if (product.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(product.description),
              ],
              if (product.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in product.tags)
                      Chip(
                        label: Text(t),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: store.accent),
                  onPressed: () {
                    Navigator.pop(ctx);
                    final profile = Profile(
                      id: store.sellerProfileId,
                      type: ProfileType.seller,
                      displayName: store.name,
                      isOwnedByUser: false,
                    );
                    final conv = context
                        .read<ChatController>()
                        .ensureConversationWithStore(profile);
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => ChatScreen(conversationId: conv.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Contactar para pedir'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
