import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatting.dart';
import '../../data/feed_controller.dart';
import '../../data/session_controller.dart';
import '../../models/post.dart';
import '../../models/profile.dart';
import '../../widgets/profile_badge.dart';

class PostEditorScreen extends StatefulWidget {
  /// Si se pasa, la pantalla edita una publicación existente.
  final Post? existing;

  const PostEditorScreen({super.key, this.existing});

  @override
  State<PostEditorScreen> createState() => _PostEditorScreenState();
}

class _PostEditorScreenState extends State<PostEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _body;
  late final TextEditingController _price;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _body = TextEditingController(text: e?.body ?? '');
    _price = TextEditingController(
      text: e?.price != null ? e!.price!.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _price.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final feed = context.read<FeedController>();
    final priceText = _price.text.trim().replaceAll(',', '.');
    final price = priceText.isEmpty ? null : double.tryParse(priceText);

    if (isEditing) {
      feed.updatePost(
        widget.existing!.id,
        title: _title.text.trim(),
        body: _body.text.trim(),
        price: price,
      );
    } else {
      final store = context.read<SessionController>().activeProfile;
      feed.createPost(
        store: store,
        title: _title.text.trim(),
        body: _body.text.trim(),
        price: price,
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEditing ? 'Publicación actualizada' : 'Publicación creada'),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final store =
        isEditing ? null : session.activeProfile; // perfil autor en creación
    final scheme = Theme.of(context).colorScheme;

    // Un comprador no puede publicar.
    if (!isEditing && !session.activeType.canPublish) {
      return Scaffold(
        appBar: AppBar(title: const Text('Crear publicación')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Cambia a un perfil de vendedor o servicios para publicar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar publicación' : 'Nueva publicación'),
        actions: [
          IconButton(onPressed: _save, icon: const Icon(Icons.check)),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (store != null) ...[
                  Row(
                    children: [
                      Text('Publicando como ',
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                      ProfileBadge(type: store.type),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          store.displayName,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                _ImagePlaceholder(seed: widget.existing?.imageSeed),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa un título'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _body,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa una descripción'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Precio (opcional)',
                    prefixText: '\$ ',
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _save,
                  child: Text(isEditing ? 'Guardar cambios' : 'Publicar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final int? seed;

  const _ImagePlaceholder({this.seed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gradient = seed != null ? gradientForSeed(seed!) : null;
    return Container(
      height: 150,
      decoration: BoxDecoration(
        gradient: gradient != null
            ? LinearGradient(colors: gradient)
            : null,
        color: gradient == null ? scheme.surfaceContainerHighest : null,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                size: 36,
                color: gradient != null ? Colors.white : scheme.primary),
            const SizedBox(height: 6),
            Text(
              'Agregar imagen',
              style: TextStyle(
                  color: gradient != null ? Colors.white : scheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
