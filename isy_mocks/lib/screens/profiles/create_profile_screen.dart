import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/profile_palettes.dart';
import '../../data/session_controller.dart';
import '../../models/profile.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _category = TextEditingController();
  final _description = TextEditingController();
  ProfileType _type = ProfileType.seller;

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _description.dispose();
    super.dispose();
  }

  void _create() {
    if (!_formKey.currentState!.validate()) return;
    context.read<SessionController>().createProfile(
          type: _type,
          displayName: _name.text.trim(),
          category: _category.text.trim().isEmpty
              ? null
              : _category.text.trim(),
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Perfil "${_name.text.trim()}" creado y activado')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final color = brandColorFor(_type);
    return Scaffold(
      appBar: AppBar(title: const Text('Crear perfil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Tipo de perfil',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                SegmentedButton<ProfileType>(
                  segments: const [
                    ButtonSegment(
                      value: ProfileType.seller,
                      label: Text('Vendedor'),
                      icon: Icon(Icons.storefront_outlined),
                    ),
                    ButtonSegment(
                      value: ProfileType.service,
                      label: Text('Servicios'),
                      icon: Icon(Icons.handyman_outlined),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() => _type = s.first),
                ),
                const SizedBox(height: 20),
                Center(
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(_type.icon, size: 36, color: color),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: _type == ProfileType.seller
                        ? 'Nombre de la tienda'
                        : 'Nombre del servicio',
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa un nombre'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _category,
                  decoration: const InputDecoration(
                    labelText: 'Categoría (opcional)',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _create,
                  style: FilledButton.styleFrom(backgroundColor: color),
                  child: const Text('Crear perfil'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
