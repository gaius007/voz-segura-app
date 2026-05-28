import '../entities/report.dart';
import '../repositories/report_repository.dart';

// Caso de uso pra buscar as coisas do Firestore
class GetReports {
  final ReportRepository repository;

  GetReports(this.repository);

  Future<List<Report>> execute({int? limit, DateTime? startAfter}) async {
    // So chama o repositorio msm, bem de boa
    return await repository.getReports(limit: limit, startAfter: startAfter);
  }
}
