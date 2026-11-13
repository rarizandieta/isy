import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/result.dart';
import '../../data/repositories/store_repository.dart';
import '../../domain/models/coverage_zone.dart';
import '../../domain/models/mini_store.dart';
import '../../domain/models/store_section.dart';
import 'store_editor_view_model.dart';
import 'store_ui.dart';

/// Paleta de acentos (hex #RRGGBB) para personalizar la tienda. Se excluyen el
/// verde (#2E7D32), el azul (#1565C0) y el morado (#6A1B9A) porque están
/// reservados como color de los perfiles (comprador/servicios/vendedor).
const List<String> _kAccentPalette = [
  '#EF6C00',
  '#D84315',
  '#00897B',
  '#AD1457',
  '#5D4037',
];

const Map<String, String> _kDeliveryLabels = {
  'pickup': 'Recoger en tienda',
  'delivery': 'Entrega a domicilio',
  'shipping': 'Envío',
};

const Map<String, String> _kPaymentLabels = {
  'cash': 'Efectivo',
  'transfer': 'Transferencia',
  'card': 'Tarjeta',
};

/// Editor de Mini Tienda: crea (cuando [existing] es null) o configura una
/// tienda existente. El `sellerProfileId` lo pone el gateway desde el perfil
/// activo.
class StoreEditorView extends StatelessWidget {
  const StoreEditorView({super.key, this.existing, this.createForName});

  final MiniStore? existing;
  final String? createForName;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => StoreEditorViewModel(ctx.read<StoreRepository>()),
      child: _StoreEditorScreen(existing: existing, createForName: createForName),
    );
  }
}

class _StoreEditorScreen extends StatefulWidget {
  const _StoreEditorScreen({this.existing, this.createForName});

  final MiniStore? existing;
  final String? createForName;

  @override
  State<_StoreEditorScreen> createState() => _StoreEditorScreenState();
}

class _StoreEditorScreenState extends State<_StoreEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _tagline;
  late final TextEditingController _description;
  late final TextEditingController _schedule;

  int? _categoryId;
  // Ids de las zonas de cobertura marcadas (catálogo fijo).
  Set<int> _coverageZoneIds = {};
  late String _accent;
  late bool _isOpen;
  late Set<String> _delivery;
  late Set<String> _payments;

  // Imágenes de identidad. La imagen EXISTENTE llega como URL del backend; una
  // nueva selección se guarda como data URI base64 (para subir). `_removed*`
  // marca que el usuario quitó la imagen que ya tenía.
  final ImagePicker _picker = ImagePicker();
  String? _existingLogoUrl;
  String? _existingCoverUrl;
  String? _pickedLogoBase64;
  String? _pickedCoverBase64;
  bool _removedLogo = false;
  bool _removedCover = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? widget.createForName ?? '');
    _tagline = TextEditingController(text: e?.tagline ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _schedule = TextEditingController(text: e?.scheduleText ?? '');
    _categoryId = e?.categoryId;
    _accent = e?.accentColor ?? _kAccentPalette.first;
    _isOpen = e?.isOpen ?? true;
    _delivery = {...?e?.deliveryOptions};
    if (_delivery.isEmpty) _delivery = {'pickup'};
    _payments = {...?e?.paymentMethods};
    if (_payments.isEmpty) _payments = {'cash'};
    _coverageZoneIds = {...?e?.coverageZones.map((z) => z.id)};
    _existingLogoUrl = e?.logoUrl;
    _existingCoverUrl = e?.coverUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _tagline.dispose();
    _description.dispose();
    _schedule.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final vm = context.read<StoreEditorViewModel>();
    final existing = widget.existing;

    final slug = existing?.slug ??
        '${_slugify(_name.text)}-${DateTime.now().millisecondsSinceEpoch % 100000}';

    final draft = StoreDraft(
      name: _name.text.trim(),
      slug: slug,
      categoryId: _categoryId!,
      accentColor: _accent,
      tagline: _tagline.text,
      description: _description.text,
      scheduleText: _schedule.text,
      isOpen: _isOpen,
      status: 'active',
      deliveryOptions: _delivery.isEmpty ? const ['pickup'] : _delivery.toList(),
      paymentMethods: _payments.isEmpty ? const ['cash'] : _payments.toList(),
      coverageZoneIds: _coverageZoneIds.toList(),
      setCoverageZones: true,
      // Solo enviamos la imagen si el usuario eligió una nueva o quitó la actual.
      // (picked => establece; removed sin picked => limpia; nada => se omite).
      setLogoImage: _pickedLogoBase64 != null || _removedLogo,
      logoImageBase64: _pickedLogoBase64,
      setCoverImage: _pickedCoverBase64 != null || _removedCover,
      coverImageBase64: _pickedCoverBase64,
    );

    final ok = await vm.save(storeId: existing?.id, draft: draft);
    if (!mounted) return;
    if (ok) {
      messenger.showSnackBar(
        SnackBar(content: Text(existing == null ? 'Mini Tienda creada' : 'Mini Tienda actualizada')),
      );
      navigator.pop();
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(vm.error ?? 'No se pudo guardar la tienda.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StoreEditorViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Configurar Mini Tienda' : 'Crear Mini Tienda'),
      ),
      body: SafeArea(
        child: vm.loadingCategories
            ? const Center(child: CircularProgressIndicator())
            : vm.categoriesError != null
                ? _CategoriesError(message: vm.categoriesError!)
                : _buildForm(context, vm),
      ),
    );
  }

  Widget _buildForm(BuildContext context, StoreEditorViewModel vm) {
    final categoryIds = vm.categories.map((c) => c.id).toSet();
    final dropdownValue =
        (_categoryId != null && categoryIds.contains(_categoryId)) ? _categoryId : null;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Label('Identidad'),
          _IdentityPickers(
            coverExistingUrl: _existingCoverUrl,
            coverPickedBytes: _bytesFromDataUri(_pickedCoverBase64),
            coverRemoved: _removedCover,
            logoExistingUrl: _existingLogoUrl,
            logoPickedBytes: _bytesFromDataUri(_pickedLogoBase64),
            logoRemoved: _removedLogo,
            onPickCover: () => _chooseImageSource(isCover: true),
            onPickLogo: () => _chooseImageSource(isCover: false),
            onRemoveCover: () => setState(() {
              _pickedCoverBase64 = null;
              _removedCover = true;
            }),
            onRemoveLogo: () => setState(() {
              _pickedLogoBase64 = null;
              _removedLogo = true;
            }),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Nombre de la tienda',
              prefixIcon: Icon(Icons.storefront_outlined),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _tagline,
            decoration: const InputDecoration(
              labelText: 'Eslogan (opcional)',
              hintText: 'Lo de siempre, fresquecito',
              prefixIcon: Icon(Icons.format_quote),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _description,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Descripción (opcional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          _Label('Giro'),
          DropdownButtonFormField<int>(
            initialValue: dropdownValue,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.category_outlined)),
            items: [
              for (final c in vm.categories) DropdownMenuItem(value: c.id, child: Text(c.name)),
            ],
            onChanged: (v) => setState(() => _categoryId = v),
            validator: (v) => v == null ? 'Selecciona un giro' : null,
          ),
          const SizedBox(height: 20),
          _Label('Color de acento'),
          _AccentPicker(
            selected: _accent,
            onSelected: (hex) => setState(() => _accent = hex),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _isOpen,
            onChanged: (v) => setState(() => _isOpen = v),
            title: const Text('Tienda abierta'),
            subtitle: Text(_isOpen ? 'Visible como "Abierto"' : 'Marcada como "Cerrado"'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _schedule,
            decoration: const InputDecoration(
              labelText: 'Horario (opcional)',
              hintText: 'Lun–Sáb · 7:00–19:00',
              prefixIcon: Icon(Icons.schedule),
            ),
          ),
          const SizedBox(height: 20),
          _Label('Zona de cobertura'),
          _CoveragePicker(
            zones: vm.coverageZones,
            selectedIds: _coverageZoneIds,
            onToggle: (id) => setState(() {
              if (_coverageZoneIds.contains(id)) {
                _coverageZoneIds.remove(id);
              } else {
                _coverageZoneIds.add(id);
              }
            }),
          ),
          const SizedBox(height: 20),
          _Label('Entrega'),
          Wrap(
            spacing: 8,
            children: [
              for (final entry in _kDeliveryLabels.entries)
                FilterChip(
                  label: Text(entry.value),
                  selected: _delivery.contains(entry.key),
                  onSelected: (on) => setState(() {
                    on ? _delivery.add(entry.key) : _delivery.remove(entry.key);
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _Label('Pagos'),
          Wrap(
            spacing: 8,
            children: [
              for (final entry in _kPaymentLabels.entries)
                FilterChip(
                  label: Text(entry.value),
                  selected: _payments.contains(entry.key),
                  onSelected: (on) => setState(() {
                    on ? _payments.add(entry.key) : _payments.remove(entry.key);
                  }),
                ),
            ],
          ),
          const SizedBox(height: 22),
          if (_isEditing)
            _SectionsManager(storeId: widget.existing!.id)
          else
            const _SectionsHint(),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: vm.submitting ? null : _save,
            child: vm.submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Text(_isEditing ? 'Guardar cambios' : 'Crear Mini Tienda'),
          ),
        ],
      ),
    );
  }

  /// Pregunta el origen (cámara o galería) y luego selecciona la imagen.
  Future<void> _chooseImageSource({required bool isCover}) async {
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
    await _pickImage(isCover: isCover, source: source);
  }

  Future<void> _pickImage({required bool isCover, required ImageSource source}) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        // Acota el tamaño tanto para galería como para FOTO de cámara: se
        // reescala y recomprime a JPEG, manteniendo el peso bien por debajo del
        // tope del backend (3 MB).
        maxWidth: isCover ? 1280 : 640,
        maxHeight: isCover ? 1280 : 640,
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
        if (isCover) {
          _pickedCoverBase64 = dataUri;
          _removedCover = false;
        } else {
          _pickedLogoBase64 = dataUri;
          _removedLogo = false;
        }
      });
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo seleccionar la imagen.')),
      );
    }
  }

  static Uint8List? _bytesFromDataUri(String? dataUri) {
    if (dataUri == null || dataUri.isEmpty) return null;
    final comma = dataUri.indexOf(',');
    final base64Part = comma >= 0 ? dataUri.substring(comma + 1) : dataUri;
    try {
      return base64Decode(base64Part);
    } catch (_) {
      return null;
    }
  }

  static String _slugify(String name) {
    final base = name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return base.isEmpty ? 'tienda' : base;
  }
}

class _AccentPicker extends StatelessWidget {
  const _AccentPicker({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    const gap = 8.0;
    final count = _kAccentPalette.length;
    // Una sola fila: el diámetro se ajusta al ancho disponible para que los
    // acentos entren siempre, con un tope para que no crezcan demasiado.
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth - gap * (count - 1);
        final diameter = (available / count).clamp(28.0, 44.0).toDouble();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final hex in _kAccentPalette)
              GestureDetector(
                onTap: () => onSelected(hex),
                child: Container(
                  width: diameter,
                  height: diameter,
                  decoration: BoxDecoration(
                    color: _hexColor(hex),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected == hex ? onSurface : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: selected == hex
                      ? Icon(Icons.check, color: Colors.white, size: diameter * 0.52)
                      : null,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CategoriesError extends StatelessWidget {
  const _CategoriesError({required this.message});
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
              onPressed: () => context.read<StoreEditorViewModel>().retryCategories(),
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

Color _hexColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse(h, radix: 16) | 0xFF000000);
}

/// Selectores de imagen de portada (banner) y logo/perfil (círculo). Muestran
/// previsualización, permiten elegir de la galería y quitar la imagen.
class _IdentityPickers extends StatelessWidget {
  const _IdentityPickers({
    required this.coverExistingUrl,
    required this.coverPickedBytes,
    required this.coverRemoved,
    required this.logoExistingUrl,
    required this.logoPickedBytes,
    required this.logoRemoved,
    required this.onPickCover,
    required this.onPickLogo,
    required this.onRemoveCover,
    required this.onRemoveLogo,
  });

  final String? coverExistingUrl;
  final Uint8List? coverPickedBytes;
  final bool coverRemoved;
  final String? logoExistingUrl;
  final Uint8List? logoPickedBytes;
  final bool logoRemoved;
  final VoidCallback onPickCover;
  final VoidCallback onPickLogo;
  final VoidCallback onRemoveCover;
  final VoidCallback onRemoveLogo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Portada: nueva selección (memoria) > existente (URL) > placeholder.
    final bool hasCover =
        coverPickedBytes != null || (!coverRemoved && coverExistingUrl != null);
    Widget coverChild;
    if (coverPickedBytes != null) {
      coverChild = Image.memory(coverPickedBytes!, fit: BoxFit.cover);
    } else if (!coverRemoved && coverExistingUrl != null) {
      coverChild = MediaImage(url: coverExistingUrl, fit: BoxFit.cover);
    } else {
      coverChild = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, color: scheme.onSurfaceVariant),
          const SizedBox(height: 6),
          Text('Foto de portada', style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      );
    }

    // Logo: selección (memoria) > existente (URL) > sin imagen.
    ImageProvider? logoProvider;
    if (logoPickedBytes != null) {
      logoProvider = MemoryImage(logoPickedBytes!);
    } else if (!logoRemoved && logoExistingUrl != null) {
      final abs = mediaAbsoluteUrl(logoExistingUrl);
      if (abs != null) logoProvider = NetworkImage(abs);
    }
    final bool hasLogo = logoProvider != null;

    return SizedBox(
      height: 168,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Portada (banner).
          GestureDetector(
            onTap: onPickCover,
            child: Container(
              height: 132,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: coverChild,
            ),
          ),
          if (hasCover)
            Positioned(
              top: 6,
              right: 6,
              child: _RemoveBadge(onTap: onRemoveCover),
            ),
          // Logo / foto de perfil (círculo) que solapa el banner.
          Positioned(
            left: 16,
            bottom: 0,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: onPickLogo,
                  child: CircleAvatar(
                    radius: 38,
                    backgroundColor: scheme.surfaceContainerHighest,
                    foregroundImage: logoProvider,
                    child: !hasLogo
                        ? Icon(Icons.storefront, color: scheme.onSurfaceVariant)
                        : null,
                  ),
                ),
                // Badge de cámara/editar (abajo-derecha).
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: GestureDetector(
                    onTap: onPickLogo,
                    child: CircleAvatar(
                      radius: 13,
                      backgroundColor: scheme.primary,
                      child: Icon(
                        hasLogo ? Icons.edit : Icons.camera_alt,
                        size: 14,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
                ),
                // Botón para quitar el logo (arriba-derecha) si hay imagen.
                if (hasLogo)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: _RemoveBadge(onTap: onRemoveLogo),
                  ),
              ],
            ),
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

/// Gestor de secciones de vitrina (solo en modo edición: requiere una tienda ya
/// creada). Cada acción —crear, renombrar, eliminar— se persiste de inmediato
/// vía los endpoints `/stores/:id/sections`. Se mantiene aparte del botón
/// "Guardar" del formulario (que solo toca los datos de la tienda).
class _SectionsManager extends StatefulWidget {
  const _SectionsManager({required this.storeId});
  final int storeId;

  @override
  State<_SectionsManager> createState() => _SectionsManagerState();
}

class _SectionsManagerState extends State<_SectionsManager> {
  late final StoreRepository _repo;
  List<StoreSection> _sections = const [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = context.read<StoreRepository>();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repo.listSections(widget.storeId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Ok(:final value):
          _sections = value;
        case Err(:final failure):
          _error = messageFor(failure);
      }
    });
  }

  int get _nextPosition => _sections.isEmpty
      ? 1
      : _sections.map((s) => s.position).reduce((a, b) => a > b ? a : b) + 1;

  Future<void> _add() async {
    final name = await _promptName(title: 'Nueva sección');
    if (name == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final result = await _repo.createSection(widget.storeId, name: name, position: _nextPosition);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Ok(:final value):
        setState(() => _sections = [..._sections, value]);
      case Err(:final failure):
        messenger.showSnackBar(SnackBar(content: Text(messageFor(failure))));
    }
  }

  Future<void> _rename(StoreSection section) async {
    final name = await _promptName(title: 'Renombrar sección', initial: section.name);
    if (name == null || name == section.name || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final result = await _repo.updateSection(widget.storeId, section.id, name: name);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Ok(:final value):
        setState(() {
          final copy = [..._sections];
          final i = copy.indexWhere((s) => s.id == section.id);
          if (i >= 0) copy[i] = value;
          _sections = copy;
        });
      case Err(:final failure):
        messenger.showSnackBar(SnackBar(content: Text(messageFor(failure))));
    }
  }

  Future<void> _delete(StoreSection section) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar sección'),
        content: Text(
          '¿Eliminar "${section.name}"? Los productos de esta sección quedarán sin sección.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final result = await _repo.deleteSection(widget.storeId, section.id);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Ok():
        setState(() => _sections = _sections.where((s) => s.id != section.id).toList());
      case Err(:final failure):
        messenger.showSnackBar(SnackBar(content: Text(messageFor(failure))));
    }
  }

  Future<String?> _promptName({required String title, String? initial}) async {
    final controller = TextEditingController(text: initial ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 60,
          decoration: const InputDecoration(hintText: 'Nombre de la sección'),
          onSubmitted: (_) => Navigator.pop(ctx, controller.text),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    final name = result?.trim() ?? '';
    return name.isEmpty ? null : name;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _Label('Secciones de vitrina')),
            TextButton.icon(
              onPressed: _busy ? null : _add,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar'),
            ),
          ],
        ),
        Text(
          'Agrupan tus productos en la vitrina (p. ej. "Del día", "Bebidas"). '
          'Arrástralas por el asa para cambiar el orden.',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5),
        ),
        const SizedBox(height: 10),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.4)),
            ),
          )
        else if (_error != null)
          Row(
            children: [
              Expanded(child: Text(_error!, style: TextStyle(color: scheme.error))),
              TextButton(onPressed: _load, child: const Text('Reintentar')),
            ],
          )
        else if (_sections.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Text(
              'Aún no tienes secciones. Toca "Agregar" para crear la primera.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: _sections.length,
            onReorderItem: _onReorder,
            itemBuilder: (context, i) {
              final s = _sections[i];
              return Card(
                key: ValueKey(s.id),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: ReorderableDragStartListener(
                    index: i,
                    enabled: !_busy,
                    child: Icon(Icons.drag_handle, color: scheme.onSurfaceVariant),
                  ),
                  title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Renombrar',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: _busy ? null : () => _rename(s),
                      ),
                      IconButton(
                        tooltip: 'Eliminar',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: _busy ? null : () => _delete(s),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // onReorderItem entrega newIndex ya ajustado para el item removido.
  void _onReorder(int oldIndex, int newIndex) {
    if (_busy) return;
    setState(() {
      final updated = [..._sections];
      final item = updated.removeAt(oldIndex);
      updated.insert(newIndex, item);
      _sections = updated;
    });
    _persistOrder();
  }

  /// Persiste el nuevo orden en el backend; al volver adopta la lista ya
  /// ordenada (autoritativa). Si falla, recarga desde el servidor.
  Future<void> _persistOrder() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final ids = _sections.map((s) => s.id).toList();
    final result = await _repo.reorderSections(widget.storeId, ids);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Ok(:final value):
        setState(() => _sections = value);
      case Err(:final failure):
        messenger.showSnackBar(SnackBar(content: Text(messageFor(failure))));
        _load();
    }
  }
}

/// Aviso en modo creación: las secciones se crean una vez exista la tienda.
class _SectionsHint extends StatelessWidget {
  const _SectionsHint();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('Secciones de vitrina'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Text(
            'Crea la tienda primero. Luego podrás añadir secciones para agrupar tus productos.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

/// Selector de zonas de cobertura: mapa de Google con las ubicaciones fijas
/// (pin verde = seleccionada) más una lista con checks. Solo deja marcar entre
/// estas zonas; no permite elegir otra ubicación.
class _CoveragePicker extends StatelessWidget {
  const _CoveragePicker({
    required this.zones,
    required this.selectedIds,
    required this.onToggle,
  });

  final List<CoverageZone> zones;
  final Set<int> selectedIds;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (zones.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Text(
          'No se pudieron cargar las zonas de cobertura.',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }

    final avgLat =
        zones.map((z) => z.latitude).reduce((a, b) => a + b) / zones.length;
    final avgLng =
        zones.map((z) => z.longitude).reduce((a, b) => a + b) / zones.length;

    final markers = <Marker>{
      for (final z in zones)
        Marker(
          markerId: MarkerId('${z.id}'),
          position: LatLng(z.latitude, z.longitude),
          infoWindow: InfoWindow(title: z.name),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            selectedIds.contains(z.id)
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueRose,
          ),
          onTap: () => onToggle(z.id),
        ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 220,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(avgLat, avgLng),
                zoom: 14,
              ),
              markers: markers,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Toca un pin o marca en la lista las zonas donde entregas.',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5),
        ),
        const SizedBox(height: 4),
        for (final z in zones)
          CheckboxListTile(
            value: selectedIds.contains(z.id),
            onChanged: (_) => onToggle(z.id),
            title: Text(z.name),
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
      ],
    );
  }
}
