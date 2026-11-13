import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/auth_repository.dart';
import '../../domain/models/profile.dart';
import '../shared/profile_ui.dart';
import 'create_profile_view_model.dart';

/// Pantalla para crear un perfil adicional. Solo ofrece Vendedor / Servicios
/// (el perfil Comprador se crea al registrarse).
class CreateProfileView extends StatelessWidget {
  const CreateProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => CreateProfileViewModel(ctx.read<AuthRepository>()),
      child: const _CreateProfileScreen(),
    );
  }
}

class _CreateProfileScreen extends StatefulWidget {
  const _CreateProfileScreen();

  @override
  State<_CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<_CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  ProfileType _type = ProfileType.seller;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final vm = context.read<CreateProfileViewModel>();

    final ok = await vm.submit(type: _type, displayName: _name.text.trim());
    if (!mounted) return;

    if (ok) {
      messenger.showSnackBar(
        SnackBar(content: Text('Perfil "${_name.text.trim()}" creado y activado')),
      );
      navigator.pop();
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(vm.error ?? 'No se pudo crear el perfil.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<CreateProfileViewModel>().submitting;
    final nameLabel =
        _type == ProfileType.seller ? 'Nombre de la tienda' : 'Nombre del servicio';

    return Scaffold(
      appBar: AppBar(title: const Text('Crear perfil')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'TIPO DE PERFIL',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 0.8),
              ),
              const SizedBox(height: 8),
              SegmentedButton<ProfileType>(
                segments: [
                  ButtonSegment(
                    value: ProfileType.seller,
                    label: Text(profileTypeLabel(ProfileType.seller)),
                    icon: Icon(profileTypeIcon(ProfileType.seller)),
                  ),
                  ButtonSegment(
                    value: ProfileType.serviceProvider,
                    label: Text(profileTypeLabel(ProfileType.serviceProvider)),
                    icon: Icon(profileTypeIcon(ProfileType.serviceProvider)),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: nameLabel,
                  prefixIcon: Icon(profileTypeIcon(_type)),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: busy ? null : _submit,
                child: busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Crear perfil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
