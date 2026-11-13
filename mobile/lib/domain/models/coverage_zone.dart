/// Zona de cobertura (catálogo fijo). El vendedor marca en cuáles entrega. Las
/// coordenadas sirven para pintarla como pin en el mapa. Ids como STRING desde
/// el backend; se normalizan a int.
class CoverageZone {
  final int id;
  final String code;
  final String name;
  final double latitude;
  final double longitude;

  const CoverageZone({
    required this.id,
    required this.code,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory CoverageZone.fromJson(Map<String, dynamic> json) {
    return CoverageZone(
      id: _toInt(json['id']),
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
    );
  }

  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}
