import '../entities/support_point.dart';

abstract class SupportPointRepository {
  /// Busca pontos de apoio (delegacias, hospitais, centros de apoio) próximos
  /// à coordenada informada, dentro do raio (em metros).
  Future<List<SupportPoint>> getNearbySupportPoints(
    double latitude,
    double longitude, {
    double radiusMeters,
  });
}
