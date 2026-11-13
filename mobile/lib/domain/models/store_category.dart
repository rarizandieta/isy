/// Categoría (giro) del catálogo de ministores (`/catalogs/categories`).
/// Los ids llegan como STRING desde el backend; aquí se normalizan a int.
class StoreCategory {
  final int id;
  final String code;
  final String name;

  const StoreCategory({required this.id, required this.code, required this.name});

  factory StoreCategory.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    return StoreCategory(
      id: rawId is num ? rawId.toInt() : int.tryParse(rawId?.toString() ?? '') ?? 0,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}
