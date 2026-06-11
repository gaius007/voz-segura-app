import '../entities/panic_alert.dart';
import '../repositories/panic_alert_repository.dart';

class WatchActiveAlerts {
  final PanicAlertRepository repository;

  WatchActiveAlerts(this.repository);

  Stream<List<PanicAlert>> execute() {
    return repository.watchActiveAlerts();
  }
}
