import 'coverage_zone.dart';

/// Mini Tienda de un perfil vendedor, tal como la devuelve ministores
/// (`/stores`, `/stores/mine`).
///
/// Nota de contrato: ministores devuelve los ids como STRING ("1") y las
/// opciones en snake_case (`delivery_options`, `payment_methods`). Este modelo
/// normaliza ambos.
class MiniStore {
  final int id;
  final String name;
  final String slug;
  final int categoryId;

  /// Color de acento en formato `#RRGGBB`.
  final String accentColor;

  /// Nombre del giro (categoría), p. ej. "Abarrotes". Null si no vino.
  final String? categoryName;
  final String? tagline;
  final String? description;
  final String? scheduleText;
  final String? zoneText;
  final bool isOpen;

  /// Estado del backend: 'draft' | 'active' | 'inactive' | 'suspended'.
  final String status;

  /// Opciones de entrega: 'pickup' | 'delivery' | 'shipping'.
  final List<String> deliveryOptions;

  /// Métodos de pago: 'cash' | 'transfer' | 'card'.
  final List<String> paymentMethods;

  /// URL (relativa, `/media/files/...`) del logo/perfil, o null si no tiene.
  /// Para mostrarla usa [MediaImage] o `mediaAbsoluteUrl`, que le anteponen la
  /// base del gateway.
  final String? logoUrl;

  /// URL (relativa) de la portada, o null si no tiene.
  final String? coverUrl;

  /// Zonas de cobertura marcadas por la tienda (vacío si ninguna).
  final List<CoverageZone> coverageZones;

  const MiniStore({
    required this.id,
    required this.name,
    required this.slug,
    required this.categoryId,
    required this.accentColor,
    required this.categoryName,
    required this.tagline,
    required this.description,
    required this.scheduleText,
    required this.zoneText,
    required this.isOpen,
    required this.status,
    required this.deliveryOptions,
    required this.paymentMethods,
    required this.logoUrl,
    required this.coverUrl,
    required this.coverageZones,
  });

  factory MiniStore.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    return MiniStore(
      id: _asInt(json['id']),
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      categoryId: _asInt(json['categoryId']),
      accentColor: json['accentColor'] as String? ?? '#EF6C00',
      categoryName: category is Map<String, dynamic> ? category['name'] as String? : null,
      tagline: json['tagline'] as String?,
      description: json['description'] as String?,
      scheduleText: json['scheduleText'] as String?,
      zoneText: json['zoneText'] as String?,
      isOpen: json['isOpen'] as bool? ?? false,
      status: json['status'] as String? ?? 'draft',
      deliveryOptions: _asStringList(json['delivery_options'] ?? json['deliveryOptions']),
      paymentMethods: _asStringList(json['payment_methods'] ?? json['paymentMethods']),
      logoUrl: json['logoUrl'] as String?,
      coverUrl: json['coverUrl'] as String?,
      coverageZones: (json['coverageZones'] is List)
          ? (json['coverageZones'] as List)
              .whereType<Map<String, dynamic>>()
              .map(CoverageZone.fromJson)
              .toList()
          : const [],
    );
  }

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static List<String> _asStringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return const [];
  }
}

/// Datos del formulario de Mini Tienda para crear/actualizar. `sellerProfileId`
/// NO se incluye: lo inyecta el gateway a partir del perfil activo
/// (x-profile-id).
class StoreDraft {
  final String name;
  final String slug;
  final int categoryId;
  final String accentColor; // #RRGGBB
  final String? tagline;
  final String? description;
  final String? scheduleText;
  final String? zoneText;
  final bool isOpen;
  final String status; // 'active' | 'draft' | ...
  final List<String> deliveryOptions;
  final List<String> paymentMethods;

  // Imágenes de identidad. El `set*` indica si incluir el campo en el payload:
  //  - setX=false      -> se omite (el backend deja la imagen como está).
  //  - setX=true, valor -> establece la imagen (data URI base64).
  //  - setX=true, null  -> limpia la imagen.
  final String? logoImageBase64;
  final bool setLogoImage;
  final String? coverImageBase64;
  final bool setCoverImage;

  // Zonas de cobertura: setCoverageZones=false -> se omite (deja igual);
  // true -> reemplaza por `coverageZoneIds` (lista, puede ir vacía = ninguna).
  final List<int>? coverageZoneIds;
  final bool setCoverageZones;

  const StoreDraft({
    required this.name,
    required this.slug,
    required this.categoryId,
    required this.accentColor,
    this.tagline,
    this.description,
    this.scheduleText,
    this.zoneText,
    this.isOpen = true,
    this.status = 'active',
    this.deliveryOptions = const ['pickup'],
    this.paymentMethods = const ['cash'],
    this.logoImageBase64,
    this.setLogoImage = false,
    this.coverImageBase64,
    this.setCoverImage = false,
    this.coverageZoneIds,
    this.setCoverageZones = false,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'slug': slug,
      'categoryId': categoryId,
      'accentColor': accentColor,
      'isOpen': isOpen,
      'status': status,
      'deliveryOptions': deliveryOptions,
      'paymentMethods': paymentMethods,
    };
    if (tagline != null && tagline!.trim().isNotEmpty) map['tagline'] = tagline!.trim();
    if (description != null && description!.trim().isNotEmpty) {
      map['description'] = description!.trim();
    }
    if (scheduleText != null && scheduleText!.trim().isNotEmpty) {
      map['scheduleText'] = scheduleText!.trim();
    }
    if (zoneText != null && zoneText!.trim().isNotEmpty) map['zoneText'] = zoneText!.trim();
    // Imágenes: solo se envían si cambiaron (null incluido = limpiar).
    if (setLogoImage) map['logoImageBase64'] = logoImageBase64;
    if (setCoverImage) map['coverImageBase64'] = coverImageBase64;
    if (setCoverageZones) map['coverageZoneIds'] = coverageZoneIds ?? const <int>[];
    return map;
  }
}
