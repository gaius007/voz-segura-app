import 'package:flutter/material.dart';
import '../../domain/entities/report.dart';
import '../../domain/usecases/create_report.dart';
import '../../domain/usecases/get_reports.dart';

// Esse Notifier agora gerencia o estado usando o Firebase
// O legal eh que os dados ficam salvos msm se desinstalar o app
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

  // Puxa os relatos do Firestore
  Future<void> carregarRelatos() async {
    _isLoading = true;
    notifyListeners(); 

    try {
      _reports = await getReportsUseCase.execute();
    } catch (e) {
      debugPrint('Erro ao carregar do Firestore: $e');
    } finally {
      _isLoading = false;
      notifyListeners(); 
    }
  }

  // Manda criar o relato e fazer upload das fotos
  Future<void> adicionarRelato(String descricao, List<String> fotos) async {
    // Aqui a gente cria o objeto com os caminhos locais
    // O Repositorio vai cuidar de subir pro Storage
    final novoRelato = Report(
      id: '',
      description: descricao,
      createdAt: DateTime.now(),
      photoUrls: fotos, // passa os caminhos locais por enquanto
      contentHash: '',
    );

    try {
      await createReportUseCase.execute(novoRelato);
      // Depois que terminou de subir tudo, atualiza a lista
      await carregarRelatos();
    } catch (e) {
      debugPrint('Erro ao salvar no Firebase: $e');
      rethrow; 
    }
  }
}
