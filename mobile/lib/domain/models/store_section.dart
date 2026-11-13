/// Sección de vitrina de una Mini Tienda (`/stores/:id/sections`). Agrupa los
/// productos en la tienda. Ids como STRING desde el backend; se normalizan.
class StoreSection {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;

  /// Orden de la sección en la vitrina (1..N).
  final int position;
  final bool isActive;

  const StoreSection({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.position,
    required this.isActive,
  });

  factory StoreSection.fromJson(Map<String, dynamic> json) {
    return StoreSection(
      id: _asInt(json['id']),
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      position: _asInt(json['position']),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  static int _asInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
