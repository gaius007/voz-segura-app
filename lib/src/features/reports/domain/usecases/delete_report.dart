import '../repositories/report_repository.dart';

class DeleteReport {
  final ReportRepository repository;

  DeleteReport(this.repository);

  Future<void> execute(String id) async {
    if (id.isEmpty) {
      throw Exception('ID do relato inválido!');
    }
    return await repository.deleteReport(id);
  }
}
