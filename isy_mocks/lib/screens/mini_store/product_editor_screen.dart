import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/feed_controller.dart';
import '../../data/mini_store_controller.dart';
import '../../models/mini_store.dart';
import '../../models/profile.dart';
import '../../models/store_product.dart';

/// Crea o edita un producto de la Mini Tienda.
class ProductEditorScreen extends StatefulWidget {
  final String storeId;
  final StoreProduct? existing;

  const ProductEditorScreen({
    super.key,
    required this.storeId,
    this.existing,
  });

  @override
  State<ProductEditorScreen> createState() => _ProductEditorScreenState();
}

class _ProductEditorScreenState extends State<ProductEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _offer;

  late String _unit;
  String? _sectionId;
  late StockStatus _stock;
  late bool _featured;
  late Set<String> _tags;
  late bool _published;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _price = TextEditingController(
        text: e?.price != null ? e!.price.toStringAsFixed(2) : '');
    _offer = TextEditingController(
        text: e?.offerPrice != null ? e!.offerPrice!.toStringAsFixed(2) : '');
    _unit = e?.unit ?? 'pieza';
    _sectionId = e?.sectionId;
    _stock = e?.stock ?? StockStatus.available;
    _featured = e?.isFeatured ?? false;
    _tags = {...?e?.tags};
    _published = (e?.status ?? ProductStatus.published) == ProductStatus.published;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _offer.dispose();
    super.dispose();
  }

  double? _parse(String s) =>
      s.trim().isEmpty ? null : double.tryParse(s.trim().replaceAll(',', '.'));

  void _save() =>
      _persist(_published ? ProductStatus.published : ProductStatus.draft);

  void _saveDraft() => _persist(ProductStatus.draft);

  void _persist(ProductStatus status) {
    if (!_formKey.currentState!.validate()) return;
    final controller = context.read<MiniStoreController>();
    final price = _parse(_price.text) ?? 0;
    final offer = _parse(_offer.text);

    final product = StoreProduct(
      id: widget.existing?.id ?? controller.newProductId(),
      storeId: widget.storeId,
      sectionId: _sectionId,
      name: _name.text.trim(),
      description: _description.text.trim(),
      price: price,
      offerPrice: (offer != null && offer < price) ? offer : null,
      unit: _unit,
      imageSeed: widget.existing?.imageSeed ??
          (_name.text.hashCode.abs() % 90 + 1),
      stock: _stock,
      isFeatured: _featured,
      tags: _tags.toList(),
      status: status,
    );

    if (isEditing) {
      controller.updateProduct(product);
    } else {
      controller.addProduct(product);
    }

    // Al quedar publicado (y no estarlo antes), se anuncia en el Feed.
    final wasPublished = widget.existing?.status == ProductStatus.published;
    if (status == ProductStatus.published && !wasPublished) {
      final store = controller.storeById(widget.storeId);
      if (store != null) {
        final sellerProfile = Profile(
          id: store.sellerProfileId,
          type: ProfileType.seller,
          displayName: store.name,
          isOwnedByUser: true,
        );
        context.read<FeedController>().createPost(
              store: sellerProfile,
              title: product.name,
              body: product.description,
              price: product.effectivePrice,
            );
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(status == ProductStatus.draft
            ? 'Borrador guardado'
            : (isEditing ? 'Producto actualizado' : 'Producto publicado')),
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: const Text('¿Quitar este producto de tu vitrina?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true && mounted) {
      context.read<MiniStoreController>().deleteProduct(widget.existing!.id);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<MiniStoreController>().storeById(widget.storeId);
    final sections = store?.sections ?? const <StoreSection>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar producto' : 'Nuevo producto'),
        actions: [
          if (isEditing)
            IconButton(
              tooltip: 'Eliminar',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
          IconButton(onPressed: _save, icon: const Icon(Icons.check)),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _ImagePlaceholder(),
              const SizedBox(height: 18),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Nombre del producto',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _description,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Precio',
                        prefixText: '\$ ',
                      ),
                      validator: (v) {
                        final n = _parse(v ?? '');
                        if (n == null || n <= 0) return 'Precio inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _unit,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Unidad'),
                      items: [
                        for (final u in kSaleUnits)
                          DropdownMenuItem(value: u, child: Text('por $u')),
                      ],
                      onChanged: (v) => setState(() => _unit = v ?? 'pieza'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _offer,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Precio de oferta (opcional)',
                  prefixText: '\$ ',
                  helperText: 'Debe ser menor al precio normal',
                ),
              ),
              const SizedBox(height: 18),
              _label(context, 'Sección'),
              DropdownButtonFormField<String?>(
                initialValue: _sectionId,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.dashboard_outlined),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                      value: null, child: Text('Sin sección')),
                  for (final s in sections)
                    DropdownMenuItem<String?>(value: s.id, child: Text(s.name)),
                ],
                onChanged: (v) => setState(() => _sectionId = v),
              ),
              const SizedBox(height: 18),
              _label(context, 'Disponibilidad'),
              SegmentedButton<StockStatus>(
                segments: const [
                  ButtonSegment(
                      value: StockStatus.available, label: Text('Disponible')),
                  ButtonSegment(
                      value: StockStatus.soldOut, label: Text('Agotado')),
                  ButtonSegment(
                      value: StockStatus.madeToOrder,
                      label: Text('Por encargo')),
                ],
                selected: {_stock},
                onSelectionChanged: (s) => setState(() => _stock = s.first),
              ),
              const SizedBox(height: 18),
              _label(context, 'Etiquetas'),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final t in kProductTags)
                    FilterChip(
                      label: Text(t),
                      selected: _tags.contains(t),
                      onSelected: (on) => setState(() {
                        on ? _tags.add(t) : _tags.remove(t);
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _featured,
                onChanged: (v) => setState(() => _featured = v),
                title: const Text('Destacar en la vitrina'),
                secondary: const Icon(Icons.star_outline),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _published,
                onChanged: (v) => setState(() => _published = v),
                title: const Text('Publicar'),
                subtitle: const Text(
                    'Aparecerá en tu Mini Tienda y en el Feed de publicaciones'),
                secondary: const Icon(Icons.campaign_outlined),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _save,
                child: Text(_published ? 'Publicar' : 'Guardar'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _saveDraft,
                child: const Text('Guardar borrador'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 0.6,
                )),
      );
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                size: 34, color: scheme.primary),
            const SizedBox(height: 6),
            Text('Agregar foto', style: TextStyle(color: scheme.primary)),
          ],
        ),
      ),
    );
  }
}
