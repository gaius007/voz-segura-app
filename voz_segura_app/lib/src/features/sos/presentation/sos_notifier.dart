import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/data/auth_repository.dart';
import '../../contacts/data/contact_repository.dart';
import '../../contacts/domain/contact.dart';

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
  Future<void> sendSOSAlert() async {
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

      // 3. Dispara SMS e E-mails
      for (var contact in contacts) {
        for (var method in contact.methods) {
          if (method.type == 'WhatsApp' || method.type == 'Telefone') {
            await _sendSMS(method.value, mapLink);
          } else if (method.type == 'E-mail') {
            await _sendEmail(method.value, mapLink);
          }
        }
      }

      _statusMessage = "SOS enviado com sucesso! 🎉";
    } catch (e) {
      _statusMessage = "Erro no envio: $e";
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

  // Lógica do GPS que o professor pegou da documentacao oficial
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('GPS desativado.');

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('Permissão negada.');
    }
    
    return await Geolocator.getCurrentPosition();
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
      // Se falhar (como no seu Linux), a gente avisa
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

  Future<void> logout() async {
    await authRepository.signOut();
  }
}
