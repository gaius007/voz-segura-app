import '../entities/support_point.dart';
import '../repositories/support_point_repository.dart';

class GetSupportPoints {
  final SupportPointRepository repository;

  GetSupportPoints(this.repository);

  Future<List<SupportPoint>> execute(double latitude, double longitude) {
    return repository.getNearbySupportPoints(latitude, longitude);
  }
}
