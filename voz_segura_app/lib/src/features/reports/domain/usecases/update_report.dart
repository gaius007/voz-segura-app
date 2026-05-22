import '../entities/report.dart';
import '../repositories/report_repository.dart';

class UpdateReport {
  final ReportRepository repository;

  UpdateReport(this.repository);

  Future<void> execute(Report report) async {
    if (report.description.isEmpty) {
      throw Exception('Escreve alguma coisa ai antes de salvar!');
    }
    return await repository.updateReport(report);
  }
}
