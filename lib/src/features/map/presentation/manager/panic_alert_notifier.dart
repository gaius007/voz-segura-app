import 'dart:async';
import 'package:flutter/material.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../sos/domain/services/location_service.dart';
import '../../domain/entities/panic_alert.dart';
import '../../domain/usecases/create_panic_alert.dart';
import '../../domain/usecases/resolve_panic_alert.dart';
import '../../domain/usecases/watch_active_alerts.dart';

/// Gerencia o estado dos alertas de pânico.
///
/// É a fonte única de verdade tanto para o mapa (lista de alertas ativos) quanto
/// para o botão SOS (se a usuária atual tem um alerta ativo). Como observa o
/// stream do Firestore, o estado é restaurado automaticamente ao reabrir o app
/// e expira sozinho após 24h (filtro no repositório).
class PanicAlertNotifier extends ChangeNotifier {
  final CreatePanicAlert createPanicAlert;
  final ResolvePanicAlert resolvePanicAlert;
  final WatchActiveAlerts watchActiveAlerts;
  final LocationService locationService;
  final AuthRepository authRepository;

  StreamSubscription<List<PanicAlert>>? _subscription;

  List<PanicAlert> _activeAlerts = [];
  bool _hasActiveAlert = false;
  bool _isProcessing = false;
  String? _statusMessage;

  List<PanicAlert> get activeAlerts => _activeAlerts;
  bool get hasActiveAlert => _hasActiveAlert;
  bool get isProcessing => _isProcessing;
  String? get statusMessage => _statusMessage;

  PanicAlertNotifier({
    required this.createPanicAlert,
    required this.resolvePanicAlert,
    required this.watchActiveAlerts,
    required this.locationService,
    required this.authRepository,
  }) {
    _listen();
  }

  void _listen() {
    _subscription = watchActiveAlerts.execute().listen(
      (alerts) {
        _activeAlerts = alerts;
        final uid = authRepository.currentUser?.uid;
        _hasActiveAlert = uid != null && alerts.any((a) => a.ownerUid == uid);
        notifyListeners();
      },
      onError: (e) => debugPrint('Erro ao observar alertas de pânico: $e'),
    );
  }

  /// Registra a localização atual da usuária como um alerta ativo no mapa.
  Future<void> createAlert() async {
    final uid = authRepository.currentUser?.uid;
    if (uid == null) return;

    _isProcessing = true;
    _statusMessage = 'Registrando alerta no mapa...';
    notifyListeners();

    try {
      final position = await locationService.getCurrentPosition();
      await createPanicAlert.execute(uid, position.latitude, position.longitude);
      _hasActiveAlert = true; // feedback otimista; o stream confirma em seguida
      _statusMessage = 'Alerta ativo no mapa.';
    } catch (e) {
      _statusMessage = 'Não foi possível registrar o alerta no mapa.';
      debugPrint('Erro ao criar alerta de pânico: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Marca a situação como resolvida, removendo o alerta da usuária do mapa.
  Future<void> resolveAlert() async {
    final uid = authRepository.currentUser?.uid;
    if (uid == null) return;

    _isProcessing = true;
    notifyListeners();

    try {
      await resolvePanicAlert.execute(uid);
      _hasActiveAlert = false;
      _statusMessage = 'Situação marcada como resolvida.';
    } catch (e) {
      _statusMessage = 'Não foi possível resolver o alerta.';
      debugPrint('Erro ao resolver alerta de pânico: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
