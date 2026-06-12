import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/repositories/sos_sender_repository.dart';
import '../evolution_api_service.dart';

// Implementação concreta do canal de emergência via WhatsApp.
// Concentra as conexões externas (Evolution API / wa.me) retiradas da
// camada de apresentação.
class SosSenderRepositoryImpl implements SosSenderRepository {
  final EvolutionApiService _evolutionService;

  SosSenderRepositoryImpl({EvolutionApiService? evolutionService})
      : _evolutionService = evolutionService ?? EvolutionApiService();

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
  // Estrategia de resiliencia em 2 camadas:
  //   1. Tenta envio silencioso via backend (Evolution API) - sem interacao da usuaria
  //   2. Fallback: abre WhatsApp nativo via wa.me (exige interacao)
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
      } else {
        throw "WhatsApp não instalado";
      }
    } catch (e) {
      debugPrint("❌ WhatsApp nativo também falhou: $e");
    }
  }
}
