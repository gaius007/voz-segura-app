import '../entities/panic_alert.dart';

abstract class PanicAlertRepository {
  /// Cria um alerta de pânico ativo na localização informada.
  Future<void> createAlert(String ownerUid, double latitude, double longitude);

  /// Remove (resolve) todos os alertas ativos pertencentes à usuária.
  Future<void> resolveActiveAlertsFor(String ownerUid);

  /// Stream com os alertas ativos (criados nas últimas 24h) para exibir no mapa.
  Stream<List<PanicAlert>> watchActiveAlerts();
}
