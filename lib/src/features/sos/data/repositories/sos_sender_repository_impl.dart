import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:voz_segura_app/src/core/config/app_config.dart';
import '../../domain/repositories/sos_sender_repository.dart';
import '../evolution_api_service.dart';

// Implementação concreta dos canais de envio de emergência.
// Concentra todas as conexões externas (Evolution API, Brevo, MethodChannel nativo)
// retiradas da camada de apresentação.
class SosSenderRepositoryImpl implements SosSenderRepository {
  final EvolutionApiService _evolutionService;

  SosSenderRepositoryImpl({EvolutionApiService? evolutionService})
      : _evolutionService = evolutionService ?? EvolutionApiService();

  static const smsChannel = MethodChannel('com.example.voz_segura_app/sms');

  // Limpa e padroniza o numero de telefone para formato internacional brasileiro
  String _cleanPhoneNumber(String phone) {
    String clean = phone.replaceAll(RegExp(r'[\s\(\)\-\+]'), '');
    // Padronização automática de DDI para o Brasil (55)
    if ((clean.length == 10 || clean.length == 11) && !clean.startsWith('55')) {
      clean = '55$clean';
    }
    return clean;
  }

  // Envia WhatsApp com disparo SILENCIOSO via Evolution API + fallback local
  // Estrategia de resiliencia em 3 camadas:
  //   1. Tenta envio silencioso via backend (Evolution API) - sem interacao da usuaria
  //   2. Fallback: abre WhatsApp nativo via wa.me (exige interacao)
  //   3. Fallback definitivo: envia SMS
  @override
  Future<void> sendWhatsApp(String phone, String link) async {
    String cleanPhone = _cleanPhoneNumber(phone);

    final String emergencyMessage =
        '🚨 *ALERTA DE EMERGÊNCIA - VOZ SEGURA* 🚨\n\n'
        'Estou em perigo! Minha localização em tempo real no mapa:\n$link';

    // === CAMADA 1: Envio silencioso via Evolution API (backend proxy) ===
    bool silentSuccess = false;
    try {
      silentSuccess = await _evolutionService.sendWhatsAppMessage(
        recipientPhone: cleanPhone,
        message: emergencyMessage,
      );
    } catch (e) {
      debugPrint("WhatsApp silencioso falhou: $e");
    }

    if (silentSuccess) {
      debugPrint("✅ WhatsApp silencioso enviado com sucesso via Evolution API!");
      return; // Sucesso total, nao precisa de fallback
    }

    // === CAMADA 2: Fallback - Abre WhatsApp nativo via wa.me ===
    debugPrint("⚠️ Ativando fallback: WhatsApp nativo (wa.me)...");
    final message = Uri.encodeComponent("ESTOU EM PERIGO! Minha localização atual: $link");
    final Uri whatsappUri = Uri.parse("https://wa.me/$cleanPhone?text=$message");

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        return; // Abriu o WhatsApp nativo com sucesso
      } else {
        throw "WhatsApp não instalado";
      }
    } catch (e) {
      debugPrint("WhatsApp nativo falhou: $e. Chamando contingência SMS...");
    }

    // === CAMADA 3: Fallback definitivo - SMS ===
    await sendSMS(phone, link);
  }

  // Envia SMS de forma silenciosa via MethodChannel ou fallback manual via url_launcher
  @override
  Future<void> sendSMS(String phone, String link) async {
    String cleanPhone = _cleanPhoneNumber(phone);

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
        }
      }
    }
  }

  // Envia e-mail de forma automática via Brevo REST API ou fallback manual via url_launcher
  @override
  Future<void> sendEmail(String email, String link) async {
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
        }
      }
    }
  }

  // Envia E-mail silencioso em segundo plano usando a API v3 da Brevo
  Future<bool> _sendBrevoEmail(String email, String link) async {
    if (AppConfig.brevoApiKey.isEmpty || AppConfig.brevoApiKey.startsWith('SUA_')) {
      debugPrint("Brevo API Key não configurada ou inválida.");
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse(AppConfig.brevoEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'api-key': AppConfig.brevoApiKey,
        },
        body: jsonEncode({
          "sender": {"email": AppConfig.brevoSenderEmail, "name": AppConfig.brevoSenderName},
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
}
