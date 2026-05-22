import 'package:flutter/material.dart';
import '../../domain/entities/report.dart';
import '../../domain/usecases/create_report.dart';
import '../../domain/usecases/get_reports.dart';
import '../../domain/usecases/update_report.dart';
import '../../domain/usecases/delete_report.dart';

// Esse Notifier cuida da lista de relatos
class ReportNotifier extends ChangeNotifier {
  final CreateReport createReportUseCase;
  final GetReports getReportsUseCase;
  final UpdateReport updateReportUseCase;
  final DeleteReport deleteReportUseCase;

  List<Report> _reports = [];
  List<Report> get reports => _reports;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  static const int _pageSize = 8;

  ReportNotifier({
    required this.createReportUseCase,
    required this.getReportsUseCase,
    required this.updateReportUseCase,
    required this.deleteReportUseCase,
  });

  // Busca inicial do Firestore (ou refresh)
  Future<void> carregarRelatos() async {
    _isLoading = true;
    _hasMore = true;
    notifyListeners(); 

    try {
      final fetched = await getReportsUseCase.execute(limit: _pageSize);
      _reports = fetched;
      if (fetched.length < _pageSize) {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint('Erro ao carregar do Firestore: $e');
    } finally {
      // O finally eh importante pro loading sumir msm se der erro!
      _isLoading = false;
      notifyListeners(); 
    }
  }

  // Carrega mais relatos (pagina seguinte) para infinite scroll
  Future<void> carregarMaisRelatos() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final lastReport = _reports.isNotEmpty ? _reports.last : null;
      final startAfter = lastReport?.createdAt;

      final fetched = await getReportsUseCase.execute(
        limit: _pageSize,
        startAfter: startAfter,
      );

      if (fetched.length < _pageSize) {
        _hasMore = false;
      }

      // Evita duplicatas de id
      final existingIds = _reports.map((r) => r.id).toSet();
      final newReports = fetched.where((r) => !existingIds.contains(r.id)).toList();

      _reports.addAll(newReports);
    } catch (e) {
      debugPrint('Erro ao carregar mais relatos no Notifier: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Cria um relato novo
  Future<void> adicionarRelato(
    String descricao, 
    List<String> fotos, 
    ReportVisibility visibility, {
    String? authorName,
    String? authorUid,
  }) async {
    final novoRelato = Report(
      id: '',
      description: descricao,
      createdAt: DateTime.now(),
      photoUrls: fotos,
      contentHash: '',
      visibility: visibility,
      authorName: authorName,
      authorUid: authorUid,
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

  // Edita um relato existente
  Future<void> editarRelato(String id, String novaDescricao, ReportVisibility novaVisibilidade) async {
    final relatoEditado = Report(
      id: id,
      description: novaDescricao,
      createdAt: DateTime.now(), // Nao altera createdAt no Firebase
      photoUrls: [],
      contentHash: '',
      visibility: novaVisibilidade,
    );

    _isLoading = true;
    notifyListeners();

    try {
      await updateReportUseCase.execute(relatoEditado);
      await carregarRelatos();
    } catch (e) {
      debugPrint('Erro no Notifier ao editar: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Exclui um relato
  Future<void> excluirRelato(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await deleteReportUseCase.execute(id);
      await carregarRelatos();
    } catch (e) {
      debugPrint('Erro no Notifier ao excluir: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
