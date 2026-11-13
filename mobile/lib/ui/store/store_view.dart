import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/result.dart';
import '../../data/repositories/store_repository.dart';
import '../../domain/models/mini_store.dart';
import '../../domain/models/store_product.dart';
import '../../domain/models/store_section.dart';
import 'product_editor_view.dart';
import 'store_editor_view.dart';
import 'store_ui.dart';

/// Vitrina de la Mini Tienda ("tu tienda"): muestra cómo se ve la tienda
/// (portada, logo, datos) y sus productos. Desde aquí se abre el editor
/// ("Personalizar tienda") y se gestionan los productos (FAB + tap para editar).
class StoreView extends StatefulWidget {
  const StoreView({super.key, required this.store});

  final MiniStore store;

  @override
  State<StoreView> createState() => _StoreViewState();
}

class _StoreViewState extends State<StoreView> {
  late MiniStore _store;
  List<StoreProduct> _products = const [];
  List<StoreSection> _sections = const [];
  bool _loadingProducts = true;

  @override
  void initState() {
    super.initState();
    _store = widget.store;
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final repo = context.read<StoreRepository>();
    setState(() => _loadingProducts = true);
    final productsResult = await repo.listProducts(_store.id);
    final sectionsResult = await repo.listSections(_store.id);
    if (!mounted) return;
    setState(() {
      _loadingProducts = false;
      if (productsResult case Ok(:final value)) _products = value;
      if (sectionsResult case Ok(:final value)) _sections = value;
    });
  }

  Future<void> _personalize() async {
    final repo = context.read<StoreRepository>();
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => StoreEditorView(existing: _store)),
    );
    if (!mounted) return;
    // Al volver del editor, recargamos la tienda para reflejar los cambios.
    final result = await repo.getMyStore();
    if (!mounted) return;
    if (result case Ok(:final value)) {
      if (value != null) setState(() => _store = value);
    }
  }

  Future<void> _openProductEditor({StoreProduct? product}) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductEditorView(storeId: _store.id, existing: product),
      ),
    );
    if (!mounted) return;
    await _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = storeAccentColor(_store.accentColor);
    final store = _store;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openProductEditor(),
        backgroundColor: accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Producto'),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Cover(
            store: store,
            accent: accent,
            onBack: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        store.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _OpenBadge(isOpen: store.isOpen),
                  ],
                ),
                if (store.categoryName != null && store.categoryName!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _CategoryPill(label: store.categoryName!, accent: accent),
                ],
                if (store.tagline != null && store.tagline!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    '"${store.tagline!.trim()}"',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (store.description != null && store.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(store.description!.trim()),
                ],
                const SizedBox(height: 16),
                _StoreInfoCarousel(store: store, accent: accent),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _personalize,
                  icon: const Icon(Icons.tune),
                  label: const Text('Personalizar tienda'),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _ProductsSection(
            loading: _loadingProducts,
            products: _products,
            sections: _sections,
            accent: accent,
            onTapProduct: (p) => _openProductEditor(product: p),
          ),
          const SizedBox(height: 88), // espacio para el FAB
        ],
      ),
    );
  }
}

class _ProductsSection extends StatelessWidget {
  const _ProductsSection({
    required this.loading,
    required this.products,
    required this.sections,
    required this.accent,
    required this.onTapProduct,
  });

  final bool loading;
  final List<StoreProduct> products;
  final List<StoreSection> sections;
  final Color accent;
  final ValueChanged<StoreProduct> onTapProduct;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRODUCTOS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0.8,
                ),
          ),
          const SizedBox(height: 10),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (products.isEmpty)
            _ProductsEmpty()
          else
            ..._buildGroups(),
        ],
      ),
    );
  }

  /// Agrupa los productos por sección (ordenadas por posición). Si la tienda no
  /// tiene secciones, muestra una sola grilla. Los productos sin sección (o cuya
  /// sección ya no existe) van bajo "Sin sección".
  List<Widget> _buildGroups() {
    if (sections.isEmpty) {
      return [_grid(products)];
    }
    final sorted = [...sections]..sort((a, b) => a.position.compareTo(b.position));
    final sectionIds = sections.map((s) => s.id).toSet();
    final widgets = <Widget>[];
    for (final s in sorted) {
      final items = products.where((p) => p.sectionId == s.id).toList();
      if (items.isEmpty) continue;
      widgets.add(_SectionTitle(name: s.name));
      widgets.add(_grid(items));
    }
    final orphans = products
        .where((p) => p.sectionId == null || !sectionIds.contains(p.sectionId))
        .toList();
    if (orphans.isNotEmpty) {
      widgets.add(const _SectionTitle(name: 'Sin sección'));
      widgets.add(_grid(orphans));
    }
    return widgets;
  }

  Widget _grid(List<StoreProduct> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (_, i) => _ProductCard(
        product: items[i],
        accent: accent,
        onTap: () => onTapProduct(items[i]),
      ),
    );
  }
}

/// Título de un grupo de productos (nombre de la sección) en la vitrina.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Text(
        name,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ProductsEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 36, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          const Text('Aún no has agregado productos',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            'Toca "Producto" para crear el primero.',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.accent, required this.onTap});

  final StoreProduct product;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDraft = product.status == 'draft';

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MediaImage(url: product.imageUrl, fit: BoxFit.cover),
                  if (product.isFeatured)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: _Chip(icon: Icons.star, label: 'Destacado', color: accent),
                    ),
                  if (isDraft)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: _Chip(icon: Icons.edit_note, label: 'Borrador', color: Colors.grey.shade700),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        formatPrice(product.effectivePrice),
                        style: TextStyle(color: accent, fontWeight: FontWeight.w700),
                      ),
                      if (product.hasOffer) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            formatPrice(product.price),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              decoration: TextDecoration.lineThrough,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stockLabel(product.stock),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
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

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 10.5)),
        ],
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.store, required this.accent, this.onBack});
  final MiniStore store;
  final Color accent;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final coverUrl = mediaAbsoluteUrl(store.coverUrl);
    final logoUrl = mediaAbsoluteUrl(store.logoUrl);
    final topInset = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: 190 + topInset,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 150 + topInset,
              decoration: BoxDecoration(
                gradient: coverUrl == null
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [accent, darken(accent)],
                      )
                    : null,
                image: coverUrl != null
                    ? DecorationImage(image: NetworkImage(coverUrl), fit: BoxFit.cover)
                    : null,
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: 114 + topInset,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surface,
                border: Border.all(color: scheme.surface, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: logoUrl != null
                    ? Image.network(
                        logoUrl,
                        fit: BoxFit.cover,
                        width: 76,
                        height: 76,
                        errorBuilder: (_, _, _) => Container(
                          color: accent,
                          child: const Icon(Icons.storefront, color: Colors.white, size: 32),
                        ),
                      )
                    : Container(
                        color: accent,
                        child: const Icon(Icons.storefront, color: Colors.white, size: 32),
                      ),
              ),
            ),
          ),
          if (onBack != null)
            Positioned(
              top: topInset + 6,
              left: 8,
              child: _CoverIconButton(icon: Icons.arrow_back, onTap: onBack!),
            ),
        ],
      ),
    );
  }
}

/// Botón circular semitransparente para la portada (back), legible sobre imagen.
class _CoverIconButton extends StatelessWidget {
  const _CoverIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _OpenBadge extends StatelessWidget {
  const _OpenBadge({required this.isOpen});
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? const Color(0xFF2E7D32) : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            isOpen ? 'Abierto' : 'Cerrado',
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label, required this.accent});
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: accent, fontWeight: FontWeight.w600, fontSize: 12.5),
      ),
    );
  }
}

/// Datos de un panel del carrusel (una categoría de información de la tienda).
class _InfoPanel {
  const _InfoPanel({required this.icon, required this.title, required this.chips});
  final IconData icon;
  final String title;
  final List<(IconData, String)> chips;
}

/// Carrusel de tarjetas con los datos de la tienda: una categoría por tarjeta
/// (Opciones de entrega, Opciones de pago, Zonas de cobertura, Horario).
/// Auto-avanza cada 3 s en bucle y muestra indicadores de página. Compacto.
class _StoreInfoCarousel extends StatefulWidget {
  const _StoreInfoCarousel({required this.store, required this.accent});

  final MiniStore store;
  final Color accent;

  @override
  State<_StoreInfoCarousel> createState() => _StoreInfoCarouselState();
}

class _StoreInfoCarouselState extends State<_StoreInfoCarousel> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _index = 0;
  late List<_InfoPanel> _panels;

  @override
  void initState() {
    super.initState();
    _panels = _buildPanels();
    _startAutoplay();
  }

  @override
  void didUpdateWidget(covariant _StoreInfoCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _panels = _buildPanels();
    if (_index >= _panels.length) {
      _index = _panels.isEmpty ? 0 : _panels.length - 1;
    }
  }

  void _startAutoplay() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _panels.length <= 1 || !_controller.hasClients) return;
      final next = (_index + 1) % _panels.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  List<_InfoPanel> _buildPanels() {
    final s = widget.store;
    final panels = <_InfoPanel>[];
    if (s.scheduleText != null && s.scheduleText!.trim().isNotEmpty) {
      panels.add(_InfoPanel(
        icon: Icons.schedule,
        title: 'Horario',
        chips: [(Icons.schedule, s.scheduleText!.trim())],
      ));
    }
    if (s.deliveryOptions.isNotEmpty) {
      panels.add(_InfoPanel(
        icon: Icons.local_shipping_outlined,
        title: 'Opciones de entrega',
        chips: [
          for (final d in s.deliveryOptions)
            (storeDeliveryIcon(d), kStoreDeliveryLabels[d] ?? d),
        ],
      ));
    }
    if (s.paymentMethods.isNotEmpty) {
      panels.add(_InfoPanel(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Opciones de pago',
        chips: [
          for (final p in s.paymentMethods)
            (storePaymentIcon(p), kStorePaymentLabels[p] ?? p),
        ],
      ));
    }
    if (s.coverageZones.isNotEmpty) {
      panels.add(_InfoPanel(
        icon: Icons.map_outlined,
        title: 'Zonas de cobertura',
        chips: [for (final z in s.coverageZones) (Icons.place_outlined, z.name)],
      ));
    }
    return panels;
  }

  @override
  Widget build(BuildContext context) {
    if (_panels.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        // Pausa el autoplay mientras se toca; al soltar reinicia el temporizador
        // (así un swipe manual también reinicia la cuenta de 3 s).
        Listener(
          onPointerDown: (_) => _timer?.cancel(),
          onPointerUp: (_) => _startAutoplay(),
          onPointerCancel: (_) => _startAutoplay(),
          child: SizedBox(
            height: 126,
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (i) => setState(() => _index = i),
              itemCount: _panels.length,
              itemBuilder: (_, i) => _InfoPanelCard(panel: _panels[i], accent: widget.accent),
            ),
          ),
        ),
        if (_panels.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _panels.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _index ? widget.accent : scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Una tarjeta del carrusel: título de la categoría + chips.
class _InfoPanelCard extends StatelessWidget {
  const _InfoPanelCard({required this.panel, required this.accent});

  final _InfoPanel panel;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(panel.icon, size: 17, color: accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    panel.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (icon, label) in panel.chips)
                      _InfoChip(icon: icon, label: label, accent: accent),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip tintado del color de la tienda (más amable que el gris neutro).
class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, required this.accent});

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}


