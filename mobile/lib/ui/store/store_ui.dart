import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';

/// Etiquetas, iconos y utilidades compartidas para la Mini Tienda.

const Map<String, String> kStoreDeliveryLabels = {
  'pickup': 'Recoger en tienda',
  'delivery': 'Entrega a domicilio',
  'shipping': 'Envío',
};

const Map<String, String> kStorePaymentLabels = {
  'cash': 'Efectivo',
  'transfer': 'Transferencia',
  'card': 'Tarjeta',
};

IconData storeDeliveryIcon(String key) => switch (key) {
      'pickup' => Icons.storefront_outlined,
      'delivery' => Icons.delivery_dining_outlined,
      'shipping' => Icons.local_shipping_outlined,
      _ => Icons.local_shipping_outlined,
    };

IconData storePaymentIcon(String key) => switch (key) {
      'cash' => Icons.payments_outlined,
      'transfer' => Icons.account_balance_outlined,
      'card' => Icons.credit_card_outlined,
      _ => Icons.payments_outlined,
    };

/// Convierte un color hex `#RRGGBB` a [Color] (naranja por defecto si es inválido).
Color storeAccentColor(String hex) {
  final normalized = hex.replaceFirst('#', '');
  final value = int.tryParse(normalized, radix: 16);
  if (value == null) return const Color(0xFFEF6C00);
  return Color(value | 0xFF000000);
}

/// Oscurece un color (para degradados de portada).
Color darken(Color color, [double amount = 0.18]) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
}

/// Extrae los bytes de una imagen en data URI base64 (o null si no aplica).
Uint8List? storeImageBytes(String? dataUri) {
  if (dataUri == null || dataUri.isEmpty) return null;
  final comma = dataUri.indexOf(',');
  final base64Part = comma >= 0 ? dataUri.substring(comma + 1) : dataUri;
  try {
    return base64Decode(base64Part);
  } catch (_) {
    return null;
  }
}

/// Convierte una URL de media del backend en una URL absoluta y usable.
///
/// El backend guarda las imágenes como RUTAS RELATIVAS (`/media/files/...`)
/// para ser agnósticas del entorno; aquí les anteponemos la base del gateway
/// ([AppConfig.gatewayBaseUrl]). Si ya viene absoluta (http/https) se respeta.
/// Devuelve null cuando no hay imagen.
String? mediaAbsoluteUrl(String? pathOrUrl) {
  if (pathOrUrl == null) return null;
  final value = pathOrUrl.trim();
  if (value.isEmpty) return null;
  if (value.startsWith('http://') || value.startsWith('https://')) return value;
  final base = AppConfig.gatewayBaseUrl;
  final path = value.startsWith('/') ? value : '/$value';
  return '$base$path';
}

/// Muestra una imagen servida por el backend a partir de su URL (relativa o
/// absoluta), con estados de carga y de error/placeholder. Reutilizable para
/// logo, portada y productos.
class MediaImage extends StatelessWidget {
  const MediaImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
  });

  /// URL relativa (`/media/files/...`) o absoluta. Null => se muestra placeholder.
  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;

  /// Widget a mostrar cuando no hay imagen o falla la carga. Si es null, se usa
  /// un recuadro neutro con un icono.
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final absolute = mediaAbsoluteUrl(url);
    if (absolute == null) return _placeholder(context);
    return Image.network(
      absolute,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _box(
          context,
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (context, _, _) => _placeholder(context),
    );
  }

  Widget _placeholder(BuildContext context) {
    if (placeholder != null) return placeholder!;
    return _box(
      context,
      child: Icon(
        Icons.image_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _box(BuildContext context, {required Widget child}) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: child,
    );
  }
}

/// Símbolo de moneda de la app (Quetzal guatemalteco). Centralizado aquí para
/// poder cambiarlo en un solo lugar.
const String kCurrencySymbol = 'Q';

/// Formatea un precio con el símbolo de moneda, p. ej. "Q2.50".
String formatPrice(double value) => '$kCurrencySymbol${value.toStringAsFixed(2)}';
