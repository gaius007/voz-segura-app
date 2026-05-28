import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/data/auth_repository.dart';
import '../../contacts/data/contact_repository.dart';
import 'package:voz_segura_app/src/core/theme/app_theme.dart';

// Esse Notifier agora eh o "cerebro" do SOS
// Ele pega a localizacao e manda as mensagens pros contatos
class SOSNotifier extends ChangeNotifier {
  final AuthRepository authRepository;
  final ContactRepository contactRepository;

  static const smsChannel = MethodChannel('com.example.voz_segura_app/sms');

  // Configuração da API Brevo para envio automático de e-mail em background
  static const String _brevoApiKey = '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';
  static const String _brevoSenderEmail = 'c.oliveirap2005@gmail.com';
  static const String _brevoSenderName = 'Voz Segura SOS';
  
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

      // 3. Dispara SMS, WhatsApp e E-mails de forma assíncrona concorrente (paralela)
      final List<Future<void>> sendFutures = [];
      for (var contact in contacts) {
        for (var method in contact.methods) {
          if (method.type == 'WhatsApp') {
            sendFutures.add(_sendWhatsApp(method.value, mapLink));
          } else if (method.type == 'Telefone') {
            sendFutures.add(_sendSMS(method.value, mapLink));
          } else if (method.type == 'E-mail') {
            sendFutures.add(_sendEmail(method.value, mapLink));
          }
        }
      }

      // Aguarda a execução em paralelo de todos os canais de disparo assíncronos
      await Future.wait(sendFutures);

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

  // Envia SMS de forma silenciosa via MethodChannel ou fallback manual via url_launcher
  Future<void> _sendSMS(String phone, String link) async {
    String cleanPhone = phone.replaceAll(RegExp(r'[\s\(\)\-\+]'), '');

    // Garantir DDI do Brasil se o número tiver apenas DDD + telefone
    if ((cleanPhone.length == 10 || cleanPhone.length == 11) && !cleanPhone.startsWith('55')) {
      cleanPhone = '55$cleanPhone';
    }

    bool sentSilently = false;

    try {
      // Solicita a permissão de SMS em tempo de execução
      final status = await Permission.sms.status;
      if (!status.isGranted) {
        final requestStatus = await Permission.sms.request();
        if (!requestStatus.isGranted) {
          throw "Permissão de SMS negada pela usuária.";
        }
      }

      // Dispara o SMS silencioso usando a MethodChannel nativa
      debugPrint("Enviando SMS silencioso via MethodChannel para $cleanPhone...");
      final result = await smsChannel.invokeMethod('sendSMS', {
        'phone': cleanPhone,
        'message': 'ESTOU EM PERIGO! Minha localização atual: $link',
      });
      debugPrint("SMS Nativo enviado com sucesso: $result");
      sentSilently = true;
    } catch (e) {
      debugPrint("Falha no SMS silencioso nativo: $e. Ativando fallback manual...");
    }

    if (!sentSilently) {
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: cleanPhone,
        queryParameters: {
          'body': 'ESTOU EM PERIGO! Minha localização atual: $link',
        },
      );
      try {
        // Tentamos abrir em modo externalApplication primeiro para máxima compatibilidade no Android/iOS
        await launchUrl(smsUri, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint("Não foi possível abrir SMS no modo external: $e. Tentando modo padrão...");
        try {
          await launchUrl(smsUri);
        } catch (err) {
          debugPrint("Falha total ao abrir app de SMS: $err");
          _statusMessage = "Erro: Seu sistema não conseguiu abrir o App de SMS.";
          notifyListeners();
        }
      }
    }
  }

  // Envia E-mail silencioso em segundo plano usando a API v3 da Brevo
  Future<bool> _sendBrevoEmail(String email, String link) async {
    if (_brevoApiKey.isEmpty || _brevoApiKey.startsWith('SUA_')) {
      debugPrint("Brevo API Key não configurada ou inválida.");
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.brevo.com/v3/smtp/email'),
        headers: {
          'Content-Type': 'application/json',
          'api-key': _brevoApiKey,
        },
        body: jsonEncode({
          "sender": {"email": _brevoSenderEmail, "name": _brevoSenderName},
          "to": [{"email": email}],
          "subject": "ALERTA DE EMERGÊNCIA - VOZ SEGURA",
          "htmlContent": """
            <div style="font-family: sans-serif; padding: 20px; border: 2px solid #E01A4F; border-radius: 10px; max-width: 600px;">
              <h1 style="color: #E01A4F; font-size: 24px; margin-top: 0;">ALERTA DE EMERGÊNCIA - VOZ SEGURA</h1>
              <p style="font-size: 16px; color: #1F1F21; line-height: 1.5;">
                A usuária enviou um sinal de socorro emergencial através do aplicativo <strong>Voz Segura</strong>.
              </p>
              <div style="background-color: #F8F9FA; border-left: 4px solid #E01A4F; padding: 15px; margin: 20px 0;">
                <p style="margin: 0; font-weight: bold; color: #E01A4F;">ESTOU EM PERIGO!</p>
                <p style="margin: 10px 0 0 0; font-size: 15px;">
                  Minha localização geográfica atual e tempo real no mapa:
                </p>
                <p style="margin: 10px 0 0 0;">
                  <a href="$link" style="color: #007bff; text-decoration: underline; font-weight: bold;">Ver Localização no Google Maps</a>
                </p>
              </div>
              <p style="font-size: 12px; color: #6C757D; margin-bottom: 0;">
                Este e-mail foi gerado e enviado de forma automática e silenciosa pelo aplicativo Voz Segura para contatos de confiança cadastrados.
              </p>
            </div>
          """,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 202) {
        debugPrint("E-mail enviado com sucesso via Brevo REST API!");
        return true;
      } else {
        debugPrint("Erro Brevo API: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Exceção ao disparar e-mail via Brevo: $e");
      return false;
    }
  }

  // Envia e-mail de forma automática via Brevo REST API ou fallback manual via url_launcher
  Future<void> _sendEmail(String email, String link) async {
    bool sentAutomatically = false;

    // Tenta o envio automático via Brevo primeiro
    sentAutomatically = await _sendBrevoEmail(email, link);

    if (!sentAutomatically) {
      debugPrint("Falha no e-mail automático Brevo. Ativando fallback manual (mailto:)...");
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: email,
        queryParameters: {
          'subject': 'ALERTA DE EMERGÊNCIA - VOZ SEGURA',
          'body': 'ESTOU EM PERIGO!\n\nMinha localização atual: $link',
        },
      );
      try {
        // Tentamos abrir em modo externalApplication para garantir o disparo
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint("Não foi possível abrir E-mail no modo external: $e. Tentando modo padrão...");
        try {
          await launchUrl(emailUri);
        } catch (err) {
          debugPrint("Falha total ao abrir app de E-mail: $err");
          _statusMessage = "Erro: Seu sistema não conseguiu abrir o App de E-mail.";
          notifyListeners();
        }
      }
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
