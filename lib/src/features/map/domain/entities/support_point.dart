/// Tipo de ponto de apoio exibido no Mapa de Segurança.
/// Delegacias da Mulher (DDM/DEAM) são identificadas pelo nome do ponto no
/// OpenStreetMap, já que ambas chegam como `amenity=police`.
enum SupportPointType {
  delegacia,
  delegaciaMulher,
  hospital,
  postoPM,
  centroApoio,
  casaAcolhimento,
  outro;

  String get label {
    switch (this) {
      case SupportPointType.delegacia:
        return 'Delegacia / Polícia';
      case SupportPointType.delegaciaMulher:
        return 'Delegacia da Mulher';
      case SupportPointType.hospital:
        return 'Hospital';
      case SupportPointType.postoPM:
        return 'Posto da PM';
      case SupportPointType.centroApoio:
        return 'Centro de Apoio';
      case SupportPointType.casaAcolhimento:
        return 'Casa de Acolhimento';
      case SupportPointType.outro:
        return 'Ponto de Apoio';
    }
  }
}

/// Ponto de apoio (delegacia, hospital, centro de apoio) próximo à usuária.
class SupportPoint {
  final String id;
  final String name;
  final SupportPointType type;
  final double latitude;
  final double longitude;

  SupportPoint({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
  });

  // Serialização usada pelo cache local de POIs (SharedPreferences)
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'lat': latitude,
        'lon': longitude,
      };

  factory SupportPoint.fromJson(Map<String, dynamic> json) => SupportPoint(
        id: json['id'] as String,
        name: json['name'] as String,
        type: SupportPointType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => SupportPointType.outro,
        ),
        latitude: (json['lat'] as num).toDouble(),
        longitude: (json['lon'] as num).toDouble(),
      );
}
