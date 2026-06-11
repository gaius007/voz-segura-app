/// Tipo de ponto de apoio exibido no Mapa de Segurança.
/// Observação: o OpenStreetMap não distingue de forma confiável "Delegacia da
/// Mulher" de uma delegacia geral — ambas chegam como `amenity=police`.
enum SupportPointType {
  delegacia,
  hospital,
  postoPM,
  centroApoio,
  outro;

  String get label {
    switch (this) {
      case SupportPointType.delegacia:
        return 'Delegacia / Polícia';
      case SupportPointType.hospital:
        return 'Hospital';
      case SupportPointType.postoPM:
        return 'Posto da PM';
      case SupportPointType.centroApoio:
        return 'Centro de Apoio';
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
}
