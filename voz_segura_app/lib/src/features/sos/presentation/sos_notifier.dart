import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/data/auth_repository.dart';
import '../../contacts/data/contact_repository.dart';
import 'package:voz_segura_app/src/core/theme/app_theme.dart';

// Esse Notifier agora eh o "cerebro" do SOS
// Ele pega a localizacao e manda as mensagens pros contatos
class SOSNotifier extends ChangeNotifier {
  final AuthRepository authRepository;
  final ContactRepository contactRepository;
  
  bool _isSOSActive = false;
  bool get isSOSActive => _isSOSActive;

  bool _isSending = false;
  bool get isSending => _isSending;

  String _statusMessage = "";
  String get statusMessage => _statusMessage;

  SOSNotifier({
    required this.authRepository,
    required this.contactRepository,
  });

  void toggleSOS() {
    _isSOSActive = !_isSOSActive;
    notifyListeners();
  }

  // Funcao principal que dispara o alerta
  Future<void> sendSOSAlert(BuildContext context) async {
    _isSending = true;
    _statusMessage = "Pegando sua localização...";
    notifyListeners();

    try {
      // 1. Pega a localizacao (GPS)
      Position position = await _determinePosition();
      String mapLink = "https://www.google.com/maps?q=${position.latitude},${position.longitude}";
      
      // 2. Pega os contatos do Firebase
      final user = authRepository.currentUser;
      if (user == null) throw "Usuário não logado";
      
      // O professor disse que Stream eh melhor, mas aqui vamos pegar uma lista rapida
      // Vou usar o watchContacts e pegar o primeiro valor
      final contacts = await contactRepository.watchContacts(user.uid).first;
      
      if (contacts.isEmpty) {
        _statusMessage = "Nenhum contato cadastrado!";
        _isSending = false;
        notifyListeners();
        return;
      }

      _statusMessage = "Enviando mensagens...";
      notifyListeners();

      // 3. Dispara SMS, WhatsApp e E-mails
      for (var contact in contacts) {
        for (var method in contact.methods) {
          if (method.type == 'WhatsApp') {
            await _sendWhatsApp(method.value, mapLink);
          } else if (method.type == 'Telefone') {
            await _sendSMS(method.value, mapLink);
          } else if (method.type == 'E-mail') {
            await _sendEmail(method.value, mapLink);
          }
        }
      }

      _statusMessage = "SOS enviado com sucesso! 🎉";
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

  // Lógica do GPS atualizada para permissões robustas e detalhadas
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('GPS desativado.');

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Permissão de localização negada.');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Permissão negada permanentemente.');
    }
    
    return await Geolocator.getCurrentPosition();
  }

  // Abre o app de WhatsApp do celular
  Future<void> _sendWhatsApp(String phone, String link) async {
    // 1. Limpeza de caracteres especiais
    String cleanPhone = phone.replaceAll(RegExp(r'[\s\(\)\-\+]'), '');
    
    // 2. Padronização automática de DDI para o Brasil (55)
    if ((cleanPhone.length == 10 || cleanPhone.length == 11) && !cleanPhone.startsWith('55')) {
      cleanPhone = '55$cleanPhone';
    }

    final message = Uri.encodeComponent("ESTOU EM PERIGO! Minha localização atual: $link");
    final Uri whatsappUri = Uri.parse("https://wa.me/$cleanPhone?text=$message");
    
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        throw "WhatsApp não instalado";
      }
    } catch (e) {
      debugPrint("WhatsApp falhou: $e. Chamando contingência SMS...");
      await _sendSMS(phone, link); // Contingência automática
    }
  }

  // Abre o app de SMS do celular
  Future<void> _sendSMS(String phone, String link) async {
    final Uri smsUri = Uri.parse("sms:$phone?body=ESTOU EM PERIGO! Minha localização: $link");
    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        throw "Sem app de SMS";
      }
    } catch (e) {
      debugPrint("Nao deu pra abrir SMS: $e");
      _statusMessage = "Erro: Seu sistema não tem App de SMS instalado.";
      notifyListeners();
    }
  }

  // Abre o app de E-mail
  Future<void> _sendEmail(String email, String link) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'ALERTA DE EMERGÊNCIA - VOZ SEGURA',
        'body': 'ESTOU EM PERIGO!\n\nMinha localização atual: $link',
      },
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw "Sem app de E-mail";
      }
    } catch (e) {
      debugPrint("Nao deu pra abrir Email: $e");
      _statusMessage = "Erro: Seu sistema não tem App de E-mail instalado.";
      notifyListeners();
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
              await Geolocator.openAppSettings();
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
