import 'package:flutter/material.dart';
import '../../domain/entities/report.dart';
import '../../domain/usecases/create_report.dart';
import '../../domain/usecases/get_reports.dart';

// Esse Notifier cuida da lista de relatos
class ReportNotifier extends ChangeNotifier {
  final CreateReport createReportUseCase;
  final GetReports getReportsUseCase;

  List<Report> _reports = [];
  List<Report> get reports => _reports;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ReportNotifier({
    required this.createReportUseCase,
    required this.getReportsUseCase,
  });

  // Busca do Firestore
  Future<void> carregarRelatos() async {
    _isLoading = true;
    notifyListeners(); 

    try {
      _reports = await getReportsUseCase.execute();
    } catch (e) {
      debugPrint('Erro ao carregar do Firestore: $e');
    } finally {
      // O finally eh importante pro loading sumir msm se der erro!
      _isLoading = false;
      notifyListeners(); 
    }
  }

  // Cria um relato novo
  Future<void> adicionarRelato(String descricao, List<String> fotos) async {
    final novoRelato = Report(
      id: '',
      description: descricao,
      createdAt: DateTime.now(),
      photoUrls: fotos,
      contentHash: '',
    );

    try {
      // Manda pro Repository subir tudo
      await createReportUseCase.execute(novoRelato);
      
      // Depois que salvou, a gente tenta atualizar a lista na tela
      await carregarRelatos();
    } catch (e) {
      // Se der erro aqui, a gente avisa a tela
      debugPrint('Erro no Notifier ao salvar: $e');
      rethrow; 
    }
  }
}
