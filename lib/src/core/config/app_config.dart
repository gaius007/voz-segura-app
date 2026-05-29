// Configuração centralizada do app Voz Segura
// URLs e constantes de integração com serviços externos

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class AppConfig {
  // URL base de fallback — IP direto do backend na rede local
  static const String _localFallbackUrl = 'http://192.168.57.180:3000/api';

  static String _evolutionBackendUrl = _localFallbackUrl;

  static String get evolutionBackendUrl => _evolutionBackendUrl;

  // Testa se uma URL base está acessível (GET / com timeout curto)
  static Future<bool> _isReachable(String baseUrl) async {
    try {
      final healthUrl = baseUrl.replaceFirst(RegExp(r'/api$'), '/');
      final response = await http
          .get(Uri.parse(healthUrl))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Carrega URL do backend: tenta o IP local PRIMEIRO (sem depender de internet),
  // e usa o túnel do Firestore apenas se o IP local não responder.
  static Future<void> loadDynamicBackendUrl() async {
    // Prioridade 1: IP local na rede — não exige internet, mais confiável
    if (await _isReachable(_localFallbackUrl)) {
      _evolutionBackendUrl = _localFallbackUrl;
      print('VozSeguraConfig: ✅ Backend local acessível, usando: $_evolutionBackendUrl');
      return;
    }

    // Prioridade 2: URL dinâmica do Firestore (túnel, produção, etc.)
    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('backend')
          .get()
          .timeout(const Duration(seconds: 4));

      if (doc.exists && doc.data() != null) {
        final raw = doc.data()!['url'] as String?;
        if (raw != null && raw.isNotEmpty) {
          final candidate = raw.endsWith('/api') ? raw : '$raw/api';
          if (await _isReachable(candidate)) {
            _evolutionBackendUrl = candidate;
            print('VozSeguraConfig: ✅ Usando URL dinâmica do Firestore: $_evolutionBackendUrl');
            return;
          }
          print('VozSeguraConfig: ⚠️ URL dinâmica ($candidate) também inacessível.');
        }
      }
    } catch (e) {
      print('VozSeguraConfig: ⚠️ Firestore indisponível: $e');
    }

    print('VozSeguraConfig: ❌ Backend inacessível em ambas as opções. Verifique se o servidor está rodando.');
  }

  // Timeout para tentativa de envio silencioso via backend
  static const Duration silentSendTimeout = Duration(seconds: 8);

  // Timeout para obter QR Code de vinculação
  static const Duration qrCodeTimeout = Duration(seconds: 15);
}
