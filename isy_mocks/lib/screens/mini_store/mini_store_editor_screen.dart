import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mini_store_controller.dart';
import '../../models/mini_store.dart';
import 'mini_store_screen.dart';

/// Crea o personaliza una Mini Tienda.
/// - Edición: pasar [storeId].
/// - Creación: pasar [createForProfileId] (+ [createForName]).
class MiniStoreEditorScreen extends StatefulWidget {
  final String? storeId;
  final String? createForProfileId;
  final String? createForName;

  const MiniStoreEditorScreen({
    super.key,
    this.storeId,
    this.createForProfileId,
    this.createForName,
  });

  @override
  State<MiniStoreEditorScreen> createState() => _MiniStoreEditorScreenState();
}

class _MiniStoreEditorScreenState extends State<MiniStoreEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _tagline;
  late final TextEditingController _description;
  late final TextEditingController _schedule;
  late final TextEditingController _zone;
  late final TextEditingController _customCategory;

  late String _category;
  late int _accent;
  late bool _isOpen;
  late Set<DeliveryOption> _delivery;
  late Set<PaymentMethod> _payments;
  late List<StoreSection> _sections;
  late int _coverSeed;

  bool get isEditing => widget.storeId != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.storeId != null
        ? context.read<MiniStoreController>().storeById(widget.storeId!)
        : null;

    _name = TextEditingController(
        text: existing?.name ?? widget.createForName ?? '');
    _tagline = TextEditingController(text: existing?.tagline ?? '');
    _description = TextEditingController(text: existing?.description ?? '');
    _schedule = TextEditingController(text: existing?.schedule ?? '');
    _zone = TextEditingController(text: existing?.zone ?? '');

    final cat = existing?.category ?? 'Abarrotes';
    final known = kStoreCategories.contains(cat);
    _category = known ? cat : 'Otro';
    _customCategory = TextEditingController(text: known ? '' : cat);

    _accent = existing?.accentColor ?? kAccentPalette.first;
    _isOpen = existing?.isOpen ?? true;
    _delivery = {...?existing?.delivery};
    if (_delivery.isEmpty) _delivery = {DeliveryOption.pickup};
    _payments = {...?existing?.payments};
    if (_payments.isEmpty) _payments = {PaymentMethod.cash};
    _sections = [...?existing?.sections];
    _coverSeed = existing?.coverSeed ?? DateTime.now().millisecond;
  }

  @override
  void dispose() {
    _name.dispose();
    _tagline.dispose();
    _description.dispose();
    _schedule.dispose();
    _zone.dispose();
    _customCategory.dispose();
    super.dispose();
  }

  String get _resolvedCategory {
    if (_category == 'Otro') {
      final c = _customCategory.text.trim();
      return c.isEmpty ? 'Otro' : c;
    }
    return _category;
  }

  Future<void> _addSection() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva sección'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ej. Del día, Bebidas, Ofertas',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      setState(() {
        _sections = [
          ..._sections,
          StoreSection(id: 'sec_${DateTime.now().microsecondsSinceEpoch}', name: name),
        ];
      });
    }
  }

  Future<void> _renameSection(StoreSection section) async {
    final controller = TextEditingController(text: section.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renombrar sección'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nombre de la sección'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      setState(() {
        final i = _sections.indexWhere((s) => s.id == section.id);
        if (i >= 0) _sections[i] = StoreSection(id: section.id, name: name);
      });
    }
  }

  void _reorderSections(int oldIndex, int newIndex) {
    // onReorderItem ya entrega newIndex ajustado para el item removido.
    setState(() {
      final item = _sections.removeAt(oldIndex);
      _sections.insert(newIndex, item);
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final controller = context.read<MiniStoreController>();

    if (isEditing) {
      final existing = controller.storeById(widget.storeId!);
      if (existing == null) return;
      controller.updateStore(existing.copyWith(
        name: _name.text.trim(),
        tagline: _tagline.text.trim(),
        description: _description.text.trim(),
        category: _resolvedCategory,
        accentColor: _accent,
        isOpen: _isOpen,
        schedule: _schedule.text.trim(),
        zone: _zone.text.trim(),
        delivery: _delivery,
        payments: _payments,
        sections: _sections,
      ));
      Navigator.pop(context);
    } else {
      final store = MiniStore(
        id: controller.newStoreId(),
        sellerProfileId: widget.createForProfileId ?? 'p_unknown',
        name: _name.text.trim(),
        tagline: _tagline.text.trim(),
        description: _description.text.trim(),
        category: _resolvedCategory,
        coverSeed: _coverSeed,
        accentColor: _accent,
        isOpen: _isOpen,
        schedule: _schedule.text.trim(),
        zone: _zone.text.trim(),
        delivery: _delivery,
        payments: _payments,
        sections: _sections,
      );
      controller.createStore(store);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => MiniStoreScreen(storeId: store.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Personalizar tienda' : 'Crear Mini Tienda'),
        actions: [
          IconButton(onPressed: _save, icon: const Icon(Icons.check)),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _label(context, 'Identidad'),
              _PhotoPickers(
                accent: _accent,
                onPick: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Selección de imagen (demo)')),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la tienda',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
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
              _label(context, 'Giro'),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  for (final c in kStoreCategories)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => setState(() => _category = v ?? 'Otro'),
              ),
              if (_category == 'Otro') ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _customCategory,
                  decoration: const InputDecoration(
                    labelText: 'Especifica tu giro',
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _label(context, 'Color de acento'),
              _AccentPicker(
                selected: _accent,
                onSelected: (c) => setState(() => _accent = c),
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
              const SizedBox(height: 14),
              TextFormField(
                controller: _zone,
                decoration: const InputDecoration(
                  labelText: 'Zona / cobertura (opcional)',
                  hintText: 'Zona 1 · entregas a 3 km',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 20),
              _label(context, 'Entrega'),
              Wrap(
                spacing: 8,
                children: [
                  for (final d in DeliveryOption.values)
                    FilterChip(
                      label: Text(d.label),
                      avatar: Icon(d.icon, size: 18),
                      selected: _delivery.contains(d),
                      onSelected: (on) => setState(() {
                        on ? _delivery.add(d) : _delivery.remove(d);
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _label(context, 'Pagos'),
              Wrap(
                spacing: 8,
                children: [
                  for (final p in PaymentMethod.values)
                    FilterChip(
                      label: Text(p.label),
                      avatar: Icon(p.icon, size: 18),
                      selected: _payments.contains(p),
                      onSelected: (on) => setState(() {
                        on ? _payments.add(p) : _payments.remove(p);
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _label(context, 'Secciones de la vitrina'),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _addSection,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Agregar'),
                  ),
                ],
              ),
              Text(
                'Agrupan tus productos en la vitrina (ej. "Del día", "Bebidas"). '
                'Renómbralas, elimínalas o arrástralas para ordenar.',
                style:
                    TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              if (_sections.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: scheme.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.dashboard_customize_outlined,
                          color: scheme.onSurfaceVariant),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                            'Aún no tienes secciones. Toca "Agregar" para crear la primera.'),
                      ),
                    ],
                  ),
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: _sections.length,
                  onReorderItem: _reorderSections,
                  itemBuilder: (context, i) {
                    final s = _sections[i];
                    return Card(
                      key: ValueKey(s.id),
                      elevation: 0,
                      color: scheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: ReorderableDragStartListener(
                          index: i,
                          child: const Icon(Icons.drag_indicator),
                        ),
                        title: Text(s.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Renombrar',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _renameSection(s),
                            ),
                            IconButton(
                              tooltip: 'Eliminar',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () =>
                                  setState(() => _sections.removeAt(i)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _save,
                child: Text(isEditing ? 'Guardar cambios' : 'Crear Mini Tienda'),
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

class _AccentPicker extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;
  const _AccentPicker({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final c in kAccentPalette)
          GestureDetector(
            onTap: () => onSelected(c),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Color(c),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected == c
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.transparent,
                  width: 3,
                ),
              ),
              child: selected == c
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          ),
      ],
    );
  }
}

Color _darken(Color c, [double amount = .16]) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
}

/// Selectores de imagen (mock) para la vitrina: foto de portada (banner ancho)
/// y foto de perfil (logo). No suben imágenes reales; muestran un aviso demo.
class _PhotoPickers extends StatelessWidget {
  final int accent;
  final VoidCallback onPick;
  const _PhotoPickers({required this.accent, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accentColor = Color(accent);
    return SizedBox(
      height: 150,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Foto de portada (la "biografía": banner ancho detrás de la vitrina).
          GestureDetector(
            onTap: onPick,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor, _darken(accentColor)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        color: Colors.white, size: 30),
                    SizedBox(height: 6),
                    Text('Foto de portada',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
          // Foto de perfil (logo de la tienda), superpuesta como en la vitrina.
          Positioned(
            left: 16,
            bottom: 0,
            child: GestureDetector(
              onTap: onPick,
              child: Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: scheme.surface, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.storefront, color: Colors.white, size: 34),
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Icon(Icons.photo_camera,
                          color: Colors.white, size: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
