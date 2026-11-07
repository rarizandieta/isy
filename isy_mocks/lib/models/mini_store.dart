import 'package:flutter/material.dart';

/// Opciones de entrega que una Mini Tienda puede ofrecer.
enum DeliveryOption { pickup, delivery, shipping }

extension DeliveryOptionX on DeliveryOption {
  String get label => switch (this) {
        DeliveryOption.pickup => 'Recoger en tienda',
        DeliveryOption.delivery => 'Entrega a domicilio',
        DeliveryOption.shipping => 'Envío',
      };

  IconData get icon => switch (this) {
        DeliveryOption.pickup => Icons.storefront_outlined,
        DeliveryOption.delivery => Icons.delivery_dining_outlined,
        DeliveryOption.shipping => Icons.local_shipping_outlined,
      };
}

/// Métodos de pago aceptados.
enum PaymentMethod { cash, transfer, card }

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.cash => 'Efectivo',
        PaymentMethod.transfer => 'Transferencia',
        PaymentMethod.card => 'Tarjeta',
      };

  IconData get icon => switch (this) {
        PaymentMethod.cash => Icons.payments_outlined,
        PaymentMethod.transfer => Icons.account_balance_outlined,
        PaymentMethod.card => Icons.credit_card_outlined,
      };
}

/// Sección/categoría personalizable dentro de una Mini Tienda
/// (ej. "Del día", "Café", "Abarrotes").
class StoreSection {
  final String id;
  final String name;

  const StoreSection({required this.id, required this.name});
}

/// Giros comunes (presets). Incluye "Otro" para libertad total.
const List<String> kStoreCategories = [
  'Abarrotes',
  'Comida preparada',
  'Verduras y frutas',
  'Carnicería',
  'Panadería',
  'Repostería',
  'Moda',
  'Hogar',
  'Tecnología',
  'Belleza',
  'Otro',
];

/// Paleta de acentos para personalizar la "esencia" de cada tienda.
const List<int> kAccentPalette = [
  0xFFEF6C00, // naranja
  0xFFD84315, // terracota
  0xFF2E7D32, // verde
  0xFF00897B, // teal
  0xFF1565C0, // azul
  0xFF6A1B9A, // morado
  0xFFAD1457, // rosa
  0xFF5D4037, // café
];

/// Vitrina de un perfil vendedor: su "Mini Tienda".
class MiniStore {
  final String id;
  final String sellerProfileId;
  final String name;
  final String tagline; // frase corta de esencia
  final String description;
  final String category;
  final int coverSeed; // placeholder de portada
  final int accentColor; // ARGB (personalización)
  final bool isOpen;
  final String schedule; // "Lun–Sáb 8:00–18:00"
  final String zone; // "Zona 1 · entregas a 3 km"
  final Set<DeliveryOption> delivery;
  final Set<PaymentMethod> payments;
  final List<StoreSection> sections;

  const MiniStore({
    required this.id,
    required this.sellerProfileId,
    required this.name,
    this.tagline = '',
    this.description = '',
    this.category = 'Otro',
    this.coverSeed = 1,
    this.accentColor = 0xFFEF6C00,
    this.isOpen = true,
    this.schedule = '',
    this.zone = '',
    this.delivery = const {DeliveryOption.pickup},
    this.payments = const {PaymentMethod.cash},
    this.sections = const [],
  });

  Color get accent => Color(accentColor);

  MiniStore copyWith({
    String? name,
    String? tagline,
    String? description,
    String? category,
    int? coverSeed,
    int? accentColor,
    bool? isOpen,
    String? schedule,
    String? zone,
    Set<DeliveryOption>? delivery,
    Set<PaymentMethod>? payments,
    List<StoreSection>? sections,
  }) {
    return MiniStore(
      id: id,
      sellerProfileId: sellerProfileId,
      name: name ?? this.name,
      tagline: tagline ?? this.tagline,
      description: description ?? this.description,
      category: category ?? this.category,
      coverSeed: coverSeed ?? this.coverSeed,
      accentColor: accentColor ?? this.accentColor,
      isOpen: isOpen ?? this.isOpen,
      schedule: schedule ?? this.schedule,
      zone: zone ?? this.zone,
      delivery: delivery ?? this.delivery,
      payments: payments ?? this.payments,
      sections: sections ?? this.sections,
    );
  }
}
