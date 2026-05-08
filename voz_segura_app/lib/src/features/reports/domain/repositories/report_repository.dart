import '../entities/report.dart';

// Essa aqui eh a interface do nosso repositorio
// Fizemos assim pra ficar organizado e seguir o Clean Architecture
// Ai se um dia quiser mudar o banco pra Firebase eh so criar outra implementacao
abstract class ReportRepository {
  Future<void> createReport(Report report);
  Future<List<Report>> getReports();
}
