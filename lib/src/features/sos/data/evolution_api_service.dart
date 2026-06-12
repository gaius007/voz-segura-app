import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:voz_segura_app/src/core/config/app_config.dart';

// Servico que encapsula as chamadas HTTP ao backend proxy da Evolution API
// IMPORTANTE: Nunca chame a Evolution API diretamente do app por seguranca.
// Todas as requisicoes passam pelo backend proxy autenticado com Firebase Auth JWT.
class EvolutionApiService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtem o token JWT do usuario logado para autenticar no backend
  Future<String?> _getAuthToken() async {
    try {
      return await _auth.currentUser?.getIdToken();
    } catch (e) {
      debugPrint('EvolutionAPI: ⚠️ Token refresh falhou (sem internet?): $e');
      return null;
    }
  }

  // Executa a requisicao e, se falhar por conexao (backend mudou de IP apos
  // troca de rede, por exemplo), redescobre o backend e tenta UMA vez mais.
  Future<http.Response> _requestWithRediscovery(
    Future<http.Response> Function() request,
  ) async {
    if (AppConfig.evolutionBackendUrl.isEmpty) {
      // Descoberta inicial ainda não concluiu (ou falhou no boot)
      await AppConfig.rediscover();
    }
    try {
      return await request();
    } catch (e) {
      debugPrint('EvolutionAPI: 🔄 Falha de conexão ($e), redescobrindo backend...');
      final found = await AppConfig.rediscover();
      if (!found) rethrow;
      return await request();
    }
  }

  // Envia mensagem de WhatsApp silenciosa via backend proxy (Evolution API)
  // Retorna true se o envio foi bem-sucedido, false caso contrario
  Future<bool> sendWhatsAppMessage({
    required String recipientPhone,
    required String message,
  }) async {
    final token = await _getAuthToken();
    if (token == null) {
      debugPrint('EvolutionAPI: Usuário não autenticado, impossível enviar.');
      return false;
    }

    try {
      debugPrint('EvolutionAPI: Tentando disparo silencioso de WhatsApp...');
      final response = await _requestWithRediscovery(() => http.post(
        Uri.parse('${AppConfig.evolutionBackendUrl}/whatsapp/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'recipient': recipientPhone,
          'message': message,
        }),
      ).timeout(AppConfig.silentSendTimeout));

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('EvolutionAPI: ✅ WhatsApp silencioso enviado com sucesso!');
        return true;
      } else {
        debugPrint('EvolutionAPI: ⚠️ Erro HTTP ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('EvolutionAPI: ❌ Falha na conexão com backend: $e');
      return false;
    }
  }

  // Solicita QR Code de vinculacao ao backend proxy
  // Retorna a string Base64 da imagem do QR Code, ou null em caso de erro
  Future<String?> fetchQRCode(String userId) async {
    final token = await _getAuthToken();
    if (token == null) return null;

    try {
      debugPrint('EvolutionAPI: Solicitando QR Code para vinculação...');
      final response = await _requestWithRediscovery(() => http.get(
        Uri.parse('${AppConfig.evolutionBackendUrl}/whatsapp/connect?uid=$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(AppConfig.qrCodeTimeout));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        debugPrint('EvolutionAPI: ✅ QR Code obtido com sucesso!');
        return body['qrcode'] as String?;
      } else {
        debugPrint('EvolutionAPI: ⚠️ Erro ao obter QR: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('EvolutionAPI: ❌ Falha ao buscar QR Code: $e');
      return null;
    }
  }

  // Solicita o Código de Pareamento de 8 caracteres ao backend proxy
  // Retorna a string do código de pareamento (ex: "ABCD-EFGH"), ou null em caso de erro
  Future<String?> fetchPairingCode(String userId) async {
    final token = await _getAuthToken();
    if (token == null) return null;

    try {
      debugPrint('EvolutionAPI: Solicitando Código de Pareamento...');
      final response = await _requestWithRediscovery(() => http.get(
        Uri.parse('${AppConfig.evolutionBackendUrl}/whatsapp/pairing-code?uid=$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(AppConfig.qrCodeTimeout));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        debugPrint('EvolutionAPI: ✅ Código de pareamento obtido com sucesso!');
        return body['code'] as String?;
      } else {
        debugPrint('EvolutionAPI: ⚠️ Erro ao obter Pairing Code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('EvolutionAPI: ❌ Falha ao buscar Pairing Code: $e');
      return null;
    }
  }

  // Verifica e sincroniza o status de conexao com o backend (fallback para quando o webhook falha)
  // Retorna true se o WhatsApp esta conectado
  Future<bool> checkConnectionStatus() async {
    final token = await _getAuthToken();
    if (token == null) return false;

    try {
      debugPrint('EvolutionAPI: Verificando status de conexão manualmente...');
      final response = await _requestWithRediscovery(() => http.get(
        Uri.parse('${AppConfig.evolutionBackendUrl}/whatsapp/status'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(AppConfig.silentSendTimeout));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final connected = body['connected'] == true;
        debugPrint('EvolutionAPI: Status manual → conectado: $connected (state: ${body['state']})');
        return connected;
      }
      return false;
    } catch (e) {
      debugPrint('EvolutionAPI: ❌ Falha ao verificar status: $e');
      return false;
    }
  }

  // Desconecta a instancia do WhatsApp do usuario via backend proxy
  Future<bool> disconnectWhatsApp(String userId) async {
    final token = await _getAuthToken();
    if (token == null) return false;

    try {
      final response = await _requestWithRediscovery(() => http.post(
        Uri.parse('${AppConfig.evolutionBackendUrl}/whatsapp/disconnect'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'uid': userId}),
      ).timeout(AppConfig.silentSendTimeout));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('EvolutionAPI: ❌ Falha ao desconectar: $e');
      return false;
    }
  }
}
