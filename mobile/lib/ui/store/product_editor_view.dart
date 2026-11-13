import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/store_repository.dart';
import '../../domain/models/store_product.dart';
import 'product_editor_view_model.dart';
import 'store_ui.dart';

const Map<String, String> _kStockLabels = {
  'available': 'Disponible',
  'sold_out': 'Agotado',
  'made_to_order': 'Por encargo',
};

/// Editor de producto: crea ([existing] null) o edita un producto de la tienda.
class ProductEditorView extends StatelessWidget {
  const ProductEditorView({super.key, required this.storeId, this.existing});

  final int storeId;
  final StoreProduct? existing;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => ProductEditorViewModel(ctx.read<StoreRepository>(), storeId),
      child: _ProductEditorScreen(storeId: storeId, existing: existing),
    );
  }
}

class _ProductEditorScreen extends StatefulWidget {
  const _ProductEditorScreen({required this.storeId, this.existing});

  final int storeId;
  final StoreProduct? existing;

  @override
  State<_ProductEditorScreen> createState() => _ProductEditorScreenState();
}

class _ProductEditorScreenState extends State<_ProductEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _offerPrice;

  int? _unitId;
  late String _stock;
  late bool _published;
  late bool _featured;
  late Set<int> _tagIds;
  int? _sectionId;
  // Imagen existente como URL del backend; nueva selección como data URI base64;
  // `_removedImage` marca que el usuario quitó la que ya tenía.
  String? _existingImageUrl;
  String? _pickedImageBase64;
  bool _removedImage = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _price = TextEditingController(text: e != null ? e.price.toStringAsFixed(2) : '');
    _offerPrice = TextEditingController(
      text: e?.offerPrice != null ? e!.offerPrice!.toStringAsFixed(2) : '',
    );
    _unitId = e?.unitId;
    _stock = e?.stock ?? 'available';
    _published = e?.status != 'draft'; // nuevos nacen publicados; borrador si lo era
    _featured = e?.isFeatured ?? false;
    _tagIds = {...?e?.tags.map((t) => t.id)};
    _sectionId = e?.sectionId;
    _existingImageUrl = e?.imageUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _offerPrice.dispose();
    super.dispose();
  }

  double? _parsePrice(String raw) => double.tryParse(raw.trim().replaceAll(',', '.'));

  Future<void> _chooseImageSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    await _pickImage(source);
  }

  Future<void> _pickImage(ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > 3 * 1024 * 1024) {
        messenger.showSnackBar(
          const SnackBar(content: Text('La imagen es muy grande (máx. 3 MB). Intenta con otra.')),
        );
        return;
      }
      final mime = file.mimeType ?? 'image/jpeg';
      final dataUri = 'data:$mime;base64,${base64Encode(bytes)}';
      if (!mounted) return;
      setState(() {
        _pickedImageBase64 = dataUri;
        _removedImage = false;
      });
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo seleccionar la imagen.')),
      );
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final vm = context.read<ProductEditorViewModel>();
    final existing = widget.existing;
    final offer = _offerPrice.text.trim().isEmpty ? null : _parsePrice(_offerPrice.text);

    final draft = ProductDraft(
      name: _name.text.trim(),
      description: _description.text,
      price: _parsePrice(_price.text) ?? 0,
      offerPrice: offer,
      unitId: _unitId!,
      tagIds: _tagIds.toList(),
      stock: _stock,
      status: _published ? 'published' : 'draft',
      isFeatured: _featured,
      // picked => establece; removed sin picked => limpia; nada => se omite.
      setImage: _pickedImageBase64 != null || _removedImage,
      imageBase64: _pickedImageBase64,
      // El selector es la fuente de verdad: siempre enviamos la sección elegida
      // (un id o null = sin sección).
      sectionId: _sectionId,
      setSection: true,
    );

    final ok = await vm.save(productId: existing?.id, draft: draft);
    if (!mounted) return;
    if (ok) {
      messenger.showSnackBar(
        SnackBar(content: Text(existing == null ? 'Producto creado' : 'Producto actualizado')),
      );
      navigator.pop();
    } else {
      messenger.showSnackBar(SnackBar(content: Text(vm.error ?? 'No se pudo guardar el producto.')));
    }
  }

  Future<void> _confirmDelete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: const Text('¿Quitar este producto de tu vitrina?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final vm = context.read<ProductEditorViewModel>();
    final ok = await vm.delete(existing.id);
    if (!mounted) return;
    if (ok) {
      messenger.showSnackBar(const SnackBar(content: Text('Producto eliminado')));
      navigator.pop();
    } else {
      messenger.showSnackBar(SnackBar(content: Text(vm.error ?? 'No se pudo eliminar.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductEditorViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar producto' : 'Nuevo producto'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Eliminar',
              onPressed: vm.submitting ? null : _confirmDelete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: SafeArea(
        child: vm.loadingCatalog
            ? const Center(child: CircularProgressIndicator())
            : vm.catalogError != null
                ? _CatalogError(message: vm.catalogError!)
                : _buildForm(context, vm),
      ),
    );
  }

  Widget _buildForm(BuildContext context, ProductEditorViewModel vm) {
    final scheme = Theme.of(context).colorScheme;
    final pickedBytes = storeImageBytes(_pickedImageBase64);
    final showExisting =
        pickedBytes == null && !_removedImage && _existingImageUrl != null;
    final hasImage = pickedBytes != null || showExisting;
    final unitIds = vm.units.map((u) => u.id).toSet();
    final unitValue = (_unitId != null && unitIds.contains(_unitId)) ? _unitId : null;
    final sectionValue =
        (_sectionId != null && vm.sections.any((s) => s.id == _sectionId)) ? _sectionId : null;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Imagen
          GestureDetector(
            onTap: _chooseImageSource,
            child: Container(
              height: 170,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: hasImage
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        if (pickedBytes != null)
                          Image.memory(pickedBytes, fit: BoxFit.cover)
                        else
                          MediaImage(url: _existingImageUrl, fit: BoxFit.cover),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: _RemoveBadge(
                            onTap: () => setState(() {
                              _pickedImageBase64 = null;
                              _removedImage = true;
                            }),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, color: scheme.onSurfaceVariant),
                        const SizedBox(height: 6),
                        Text('Agregar foto', style: TextStyle(color: scheme.onSurfaceVariant)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nombre del producto'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
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
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Precio', prefixText: '$kCurrencySymbol '),
                  validator: (v) {
                    final parsed = _parsePrice(v ?? '');
                    if (parsed == null || parsed <= 0) return 'Precio inválido';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: unitValue,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Unidad'),
                  items: [
                    for (final u in vm.units) DropdownMenuItem(value: u.id, child: Text(u.name)),
                  ],
                  onChanged: (v) => setState(() => _unitId = v),
                  validator: (v) => v == null ? 'Elige unidad' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _offerPrice,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Precio de oferta (opcional)',
              prefixText: '$kCurrencySymbol ',
              helperText: 'Debe ser menor al precio normal',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              final offer = _parsePrice(v);
              if (offer == null || offer <= 0) return 'Oferta inválida';
              final price = _parsePrice(_price.text);
              if (price != null && offer >= price) return 'Debe ser menor al precio';
              return null;
            },
          ),
          if (vm.sections.isNotEmpty) ...[
            const SizedBox(height: 14),
            DropdownButtonFormField<int?>(
              initialValue: sectionValue,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Sección de la vitrina (opcional)',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Sin sección')),
                for (final s in vm.sections)
                  DropdownMenuItem<int?>(value: s.id, child: Text(s.name)),
              ],
              onChanged: (v) => setState(() => _sectionId = v),
            ),
          ],
          const SizedBox(height: 20),
          _Label('Disponibilidad'),
          SegmentedButton<String>(
            segments: [
              for (final entry in _kStockLabels.entries)
                ButtonSegment(value: entry.key, label: Text(entry.value)),
            ],
            selected: {_stock},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _stock = s.first),
          ),
          const SizedBox(height: 20),
          if (vm.tags.isNotEmpty) ...[
            _Label('Etiquetas'),
            Wrap(
              spacing: 8,
              children: [
                for (final t in vm.tags)
                  FilterChip(
                    label: Text(t.name),
                    selected: _tagIds.contains(t.id),
                    onSelected: (on) => setState(() {
                      on ? _tagIds.add(t.id) : _tagIds.remove(t.id);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _featured,
            onChanged: (v) => setState(() => _featured = v),
            title: const Text('Destacar en la vitrina'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _published,
            onChanged: (v) => setState(() => _published = v),
            title: const Text('Publicar'),
            subtitle: Text(_published ? 'Visible en tu Mini Tienda' : 'Guardado como borrador'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: vm.submitting ? null : _save,
            child: vm.submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Text(_isEditing ? 'Guardar cambios' : 'Crear producto'),
          ),
        ],
      ),
    );
  }
}

class _RemoveBadge extends StatelessWidget {
  const _RemoveBadge({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.close, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => context.read<ProductEditorViewModel>().retry(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 0.6,
            ),
      ),
    );
  }
}

/// Mapea el código de stock a su etiqueta en español (para mostrar en tarjetas).
String stockLabel(String code) => _kStockLabels[code] ?? code;
