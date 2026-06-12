import 'package:flutter/material.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/services/location_service.dart';
import '../domain/usecases/send_sos_alert.dart';
import 'package:voz_segura_app/src/core/widgets/location_permission_dialog.dart';

// Notifier enxuto: só estado de UI.
// Toda a lógica de GPS, rede e canais nativos vive nas camadas domain/data,
// acessadas exclusivamente via abstrações injetadas.
class SOSNotifier extends ChangeNotifier {
  final SendSOSAlert sendSOSAlertUseCase;
  final LocationService locationService;
  final AuthRepository authRepository;

  SOSNotifier({
    required this.sendSOSAlertUseCase,
    required this.locationService,
    required this.authRepository,
  });

  bool _isSOSActive = false;
  bool get isSOSActive => _isSOSActive;

  bool _isSending = false;
  bool get isSending => _isSending;

  String _statusMessage = "";
  String get statusMessage => _statusMessage;

  void toggleSOS() {
    _isSOSActive = !_isSOSActive;
    notifyListeners();
  }

  // Dispara o alerta delegando a regra de negócio ao Usecase
  Future<void> sendSOSAlert(BuildContext context) async {
    _isSending = true;
    _statusMessage = "Pegando sua localização...";
    notifyListeners();

    try {
      final user = authRepository.currentUser;
      if (user == null) throw "Usuário não logado";

      final hadContacts = await sendSOSAlertUseCase.execute(user.uid);
      _statusMessage =
          hadContacts ? "SOS enviado com sucesso! 🎉" : "Nenhum contato cadastrado!";
    } catch (e) {
      if (e.toString().contains('Permissão negada permanentemente.')) {
        _statusMessage = "Permissão de GPS negada.";
        if (context.mounted) {
          showLocationPermissionDeniedDialog(context, locationService);
        }
      } else {
        _statusMessage = "Erro no envio: $e";
      }
      debugPrint("Erro SOS: $e");
    } finally {
      _isSending = false;
      notifyListeners();

      // Limpa a mensagem depois de 5 segundos
      Future.delayed(const Duration(seconds: 5), () {
        _statusMessage = "";
        notifyListeners();
      });
    }
  }

  Future<void> logout() async {
    await authRepository.signOut();
  }
}
