import '../repositories/panic_alert_repository.dart';

class ResolvePanicAlert {
  final PanicAlertRepository repository;

  ResolvePanicAlert(this.repository);

  Future<void> execute(String ownerUid) {
    return repository.resolveActiveAlertsFor(ownerUid);
  }
}
