import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routing/routes.dart';
import '../../data/session_controller.dart';
import '../../widgets/auth_panel.dart';
import '../../widgets/brand_background.dart';
import '../../widgets/isy_logo.dart';
import '../../widgets/sso_buttons.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController(text: 'juan@correo.com');
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<SessionController>().login();
    Navigator.pushNamedAndRemoveUntil(context, Routes.home, (_) => false);
  }

  void _sso(String provider) {
    context.read<SessionController>().loginWithSso(provider);
    Navigator.pushNamedAndRemoveUntil(context, Routes.home, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final topInset =
        MediaQuery.of(context).padding.top + kToolbarHeight + 8;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
      ),
      body: BrandBackground(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, topInset, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: IsyLogo(fontSize: 40)),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Bienvenido de vuelta',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 20),
              AuthPanel(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Correo',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Ingresa tu correo'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Ingresa tu contraseña'
                            : null,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, Routes.forgot),
                          child: const Text('¿Olvidaste tu contraseña?'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _submit,
                        child: const Text('Entrar'),
                      ),
                      const SizedBox(height: 20),
                      const OrDivider(),
                      const SizedBox(height: 20),
                      SsoButtons(onPressed: _sso),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(
                    context, Routes.register),
                child: const Text('¿No tienes cuenta? Crear una'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
