import 'package:flutter/material.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/services/location_service.dart';
import '../domain/usecases/send_sos_alert.dart';
import 'package:voz_segura_app/src/core/theme/app_theme.dart';

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
          _showPermissionDeniedDialog(context);
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

  // Diálogo explicativo e amigável para permissão negada permanentemente
  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.location_off_outlined, color: AppColors.ruby, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Acesso à Localização',
                style: TextStyle(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'A permissão de localização foi desativada para este aplicativo. Para utilizar recursos que dependem da sua localização, ative a permissão manualmente nas configurações do seu celular.',
          style: TextStyle(
            color: AppColors.textMain,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.rose)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await locationService.openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ruby,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Abrir Configurações',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> logout() async {
    await authRepository.signOut();
  }
}
