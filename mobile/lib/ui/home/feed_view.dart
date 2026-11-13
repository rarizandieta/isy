import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/store_repository.dart';
import '../../domain/models/feed_item.dart';
import '../../domain/models/store_product.dart';
import '../shared/widgets/isy_logo.dart';
import '../store/product_editor_view.dart' show stockLabel;
import '../store/store_ui.dart';
import 'feed_view_model.dart';

/// Pestaña "Inicio": feed del marketplace con los productos publicados de todas
/// las tiendas activas. Se autoenvuelve con su [FeedViewModel].
class FeedView extends StatelessWidget {
  const FeedView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => FeedViewModel(ctx.read<StoreRepository>()),
      child: const _FeedScreen(),
    );
  }
}

class _FeedScreen extends StatefulWidget {
  const _FeedScreen();

  @override
  State<_FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<_FeedScreen> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 320) {
      context.read<FeedViewModel>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FeedViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const IsyLogo(fontSize: 24),
        actions: [
          IconButton(
            tooltip: 'Notificaciones',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No tienes notificaciones nuevas')),
            ),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _body(context, vm),
    );
  }

  Widget _body(BuildContext context, FeedViewModel vm) {
    if (vm.loading && vm.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.error != null && vm.items.isEmpty) {
      return _FeedError(message: vm.error!, onRetry: () => context.read<FeedViewModel>().load());
    }

    return RefreshIndicator(
      onRefresh: () => context.read<FeedViewModel>().refresh(),
      child: vm.isEmpty
          ? const _FeedEmpty()
          : ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: vm.items.length + (vm.hasMore ? 1 : 0),
              itemBuilder: (context, i) {
                if (i >= vm.items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      ),
                    ),
                  );
                }
                final item = vm.items[i];
                return _FeedCard(
                  item: item,
                  onTap: () => _showProductDetails(context, item),
                );
              },
            ),
    );
  }
}

/// Estado vacío (dentro de un scroll para que el "pull to refresh" funcione).
class _FeedEmpty extends StatelessWidget {
  const _FeedEmpty();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.storefront_outlined, size: 56, color: scheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text(
                    'Aún no hay productos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Cuando las tiendas publiquen sus productos, aparecerán aquí.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedError extends StatelessWidget {
  const _FeedError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 44),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de un producto del feed: encabezado de la tienda, imagen, nombre,
/// precio (con oferta) y disponibilidad.
class _FeedCard extends StatelessWidget {
  const _FeedCard({required this.item, required this.onTap});

  final FeedItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final product = item.product;
    final store = item.store;
    final accent = storeAccentColor(store.accentColor);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado: tienda
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  _StoreAvatar(store: store, accent: accent, radius: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      store.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                  if (product.isFeatured) _FeaturedChip(color: accent),
                ],
              ),
            ),
            // Imagen del producto
            AspectRatio(
              aspectRatio: 16 / 10,
              child: MediaImage(url: product.imageUrl, fit: BoxFit.cover),
            ),
            // Contenido
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _PriceTag(product: product, accent: accent),
                    ],
                  ),
                  if (product.description != null && product.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      product.description!.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 15, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _availabilityLabel(product),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatar circular del logo de la tienda (o inicial/ícono si no tiene logo).
class _StoreAvatar extends StatelessWidget {
  const _StoreAvatar({required this.store, required this.accent, required this.radius});

  final FeedStoreRef store;
  final Color accent;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = mediaAbsoluteUrl(store.logoUrl);
    return CircleAvatar(
      radius: radius,
      backgroundColor: accent.withValues(alpha: 0.15),
      foregroundImage: url != null ? NetworkImage(url) : null,
      child: url == null ? Icon(Icons.storefront, size: radius, color: accent) : null,
    );
  }
}

class _FeaturedChip extends StatelessWidget {
  const _FeaturedChip({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 13, color: Colors.white),
          SizedBox(width: 3),
          Text('Destacado', style: TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}

/// Precio efectivo (con oferta tachando el precio normal cuando aplica).
class _PriceTag extends StatelessWidget {
  const _PriceTag({required this.product, required this.accent});
  final StoreProduct product;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(8)),
          child: Text(
            formatPrice(product.effectivePrice),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        if (product.hasOffer)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              formatPrice(product.price),
              style: TextStyle(
                fontSize: 11,
                decoration: TextDecoration.lineThrough,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

String _availabilityLabel(StoreProduct p) {
  final unit = p.unit?.name;
  final stock = stockLabel(p.stock);
  return unit == null || unit.isEmpty ? stock : '$stock · por $unit';
}

/// Hoja inferior con el detalle del producto (solo lectura).
void _showProductDetails(BuildContext context, FeedItem item) {
  final product = item.product;
  final accent = storeAccentColor(item.store.accentColor);
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: MediaImage(url: product.imageUrl, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StoreAvatar(store: item.store, accent: accent, radius: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.store.name,
                    style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              product.name,
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatPrice(product.effectivePrice),
                  style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 22),
                ),
                if (product.hasOffer) ...[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      formatPrice(product.price),
                      style: TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.inventory_2_outlined, size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(_availabilityLabel(product), style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
            if (product.description != null && product.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Descripción', style: Theme.of(ctx).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(product.description!.trim()),
            ],
          ],
        ),
      );
    },
  );
}
