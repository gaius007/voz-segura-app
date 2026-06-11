import '../repositories/panic_alert_repository.dart';

class CreatePanicAlert {
  final PanicAlertRepository repository;

  CreatePanicAlert(this.repository);

  Future<void> execute(String ownerUid, double latitude, double longitude) {
    return repository.createAlert(ownerUid, latitude, longitude);
  }
}
