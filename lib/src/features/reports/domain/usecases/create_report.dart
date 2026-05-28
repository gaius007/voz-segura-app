import '../entities/report.dart';
import '../repositories/report_repository.dart';

// Caso de uso pra criar relato no Firebase
// To usando as interfaces pra nao ficar baguncado
class CreateReport {
  final ReportRepository repository;

  CreateReport(this.repository);

  Future<void> execute(Report report) async {
    // Nao deixa salvar se nao escreveu nada no relato
    if (report.description.isEmpty) {
      throw Exception('Escreve alguma coisa ai antes de salvar!');
    }
    
    // Manda pro repositorio salvar na nuvem
    return await repository.createReport(report);
  }
}
