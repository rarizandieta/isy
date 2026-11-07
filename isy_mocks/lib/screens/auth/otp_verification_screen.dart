import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/routing/routes.dart';
import '../../data/session_controller.dart';
import '../../widgets/auth_panel.dart';
import '../../widgets/brand_background.dart';
import '../../widgets/isy_logo.dart';

/// Verificación de cuenta por código OTP enviado al correo.
/// En esta fase (mock) se acepta cualquier código de 6 dígitos. El código
/// "vence" a los 15 minutos; al expirar se ofrece solicitarlo de nuevo.
class OtpVerificationScreen extends StatefulWidget {
  final String name;
  final String email;

  const OtpVerificationScreen({
    super.key,
    required this.name,
    required this.email,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const _codeLength = 6;
  // TODO: temporal para probar la expiración. Restaurar a Duration(minutes: 15).
  static const _validity = Duration(seconds: 15);

  final _otp = TextEditingController();
  final _otpFocus = FocusNode();
  Timer? _timer;
  Duration _remaining = _validity;
  String _code = '';

  bool get _expired => _remaining == Duration.zero;
  bool get _complete => _code.length == _codeLength;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _otpFocus.requestFocus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otp.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _remaining = _validity);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining.inSeconds <= 1) {
        t.cancel();
        setState(() => _remaining = Duration.zero);
      } else {
        setState(() => _remaining -= const Duration(seconds: 1));
      }
    });
  }

  void _resend() {
    _otp.clear();
    setState(() => _code = '');
    _startTimer();
    _otpFocus.requestFocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Enviamos un nuevo código a ${widget.email} (demo)'),
      ),
    );
  }

  void _verify() {
    if (_expired) return;
    if (!_complete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el código de 6 dígitos')),
      );
      return;
    }
    // Mock: cualquier código de 6 dígitos es válido. Aquí se crearía la cuenta.
    context
        .read<SessionController>()
        .register(name: widget.name, email: widget.email);
    Navigator.pushNamedAndRemoveUntil(
        context, Routes.onboarding, (_) => false);
  }

  String _formatRemaining() {
    final mm = _remaining.inMinutes.toString().padLeft(2, '0');
    final ss = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
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
                  'Verifica tu correo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(height: 20),
              AuthPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.mark_email_read_outlined,
                        size: 56, color: scheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      'Enviamos un código de 6 dígitos a:',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 24),
                    _OtpField(
                      controller: _otp,
                      focusNode: _otpFocus,
                      length: _codeLength,
                      value: _code,
                      enabled: !_expired,
                      onChanged: (v) => setState(() => _code = v),
                      onCompleted: _verify,
                    ),
                    const SizedBox(height: 20),
                    _CountdownOrResend(
                      expired: _expired,
                      remainingLabel: _formatRemaining(),
                      onResend: _resend,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: (_expired || !_complete) ? null : _verify,
                      child: const Text('Verificar y crear cuenta'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Demo: ingresa cualquier código de 6 dígitos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('¿Correo equivocado? Cambiar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Contador de vigencia o, si expiró, botón para solicitar un nuevo código.
class _CountdownOrResend extends StatelessWidget {
  final bool expired;
  final String remainingLabel;
  final VoidCallback onResend;

  const _CountdownOrResend({
    required this.expired,
    required this.remainingLabel,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (expired) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_off_outlined,
                  size: 18, color: scheme.error),
              const SizedBox(width: 6),
              Text(
                'El código expiró',
                style: TextStyle(
                    color: scheme.error, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onResend,
            icon: const Icon(Icons.refresh),
            label: const Text('Solicitar código de nuevo'),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.timer_outlined,
            size: 18, color: scheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text.rich(
          TextSpan(
            style: TextStyle(color: scheme.onSurfaceVariant),
            children: [
              const TextSpan(text: 'El código vence en '),
              TextSpan(
                text: remainingLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Campo de código OTP: una fila de casillas alimentada por un TextField
/// invisible superpuesto (patrón robusto sin dependencias externas).
class _OtpField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;
  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onCompleted;

  const _OtpField({
    required this.controller,
    required this.focusNode,
    required this.length,
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? () => focusNode.requestFocus() : null,
      child: SizedBox(
        height: 56,
        child: Stack(
          children: [
            Row(
              children: [
                for (var i = 0; i < length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _Cell(
                        char: i < value.length ? value[i] : '',
                        active: enabled &&
                            focusNode.hasFocus &&
                            i == value.length,
                        enabled: enabled,
                      ),
                    ),
                  ),
              ],
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: enabled,
                  autofocus: false,
                  showCursor: false,
                  keyboardType: TextInputType.number,
                  maxLength: length,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(color: Colors.transparent),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(length),
                  ],
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                  ),
                  onChanged: (v) {
                    onChanged(v);
                    if (v.length == length) {
                      focusNode.unfocus();
                      onCompleted();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String char;
  final bool active;
  final bool enabled;

  const _Cell({
    required this.char,
    required this.active,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor = active
        ? scheme.primary
        : scheme.outlineVariant;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: enabled
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: active ? 2 : 1),
      ),
      child: Text(
        char,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
