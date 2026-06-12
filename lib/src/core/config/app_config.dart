// Configuração centralizada do app Voz Segura
// URLs e constantes de integração com serviços externos

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String _cachedUrlKey = 'voz_segura_backend_url';
  static const int _backendPort = 3000;

  static String _evolutionBackendUrl = '';

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

  static String _withApiSuffix(String raw) =>
      raw.endsWith('/api') ? raw : '$raw/api';

  // Testa todas as candidatas em paralelo e retorna a primeira que responder
  static Future<String?> _firstReachable(List<String> candidates) async {
    if (candidates.isEmpty) return null;
    final results = await Future.wait(candidates.map((raw) async {
      final url = _withApiSuffix(raw);
      return await _isReachable(url) ? url : null;
    }));
    for (final url in results) {
      if (url != null) return url;
    }
    return null;
  }

  static Future<void> _saveCachedUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedUrlKey, url);
    } catch (_) {}
  }

  // Varre a subnet /24 do próprio celular procurando a porta do backend.
  // Funciona em qualquer rede (Wi-Fi nova, hotspot) sem internet nem Firestore.
  static Future<String?> _scanLocalSubnet() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );

      for (final ni in interfaces) {
        for (final addr in ni.addresses) {
          final ip = addr.address;
          final base = ip.substring(0, ip.lastIndexOf('.'));
          print('VozSeguraConfig: 🔍 Varrendo $base.0/24 pela porta $_backendPort...');

          final candidates = [
            for (int i = 1; i <= 254; i++)
              if ('$base.$i' != ip) '$base.$i',
          ];

          // Sondagem TCP em lotes paralelos; confirma com health check HTTP
          const batchSize = 64;
          for (var start = 0; start < candidates.length; start += batchSize) {
            final end = (start + batchSize).clamp(0, candidates.length);
            final batch = candidates.sublist(start, end);
            final hits = await Future.wait(batch.map((host) async {
              try {
                final socket = await Socket.connect(host, _backendPort,
                    timeout: const Duration(milliseconds: 400));
                socket.destroy();
                return host;
              } catch (_) {
                return null;
              }
            }));

            for (final host in hits) {
              if (host == null) continue;
              final url = 'http://$host:$_backendPort/api';
              if (await _isVozSeguraBackend(url)) return url;
            }
          }
        }
      }
    } catch (e) {
      print('VozSeguraConfig: ⚠️ Varredura de rede falhou: $e');
    }
    return null;
  }

  // Confirma que o serviço na porta é realmente o backend do Voz Segura
  static Future<bool> _isVozSeguraBackend(String baseUrl) async {
    try {
      final healthUrl = baseUrl.replaceFirst(RegExp(r'/api$'), '/');
      final response = await http
          .get(Uri.parse(healthUrl))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200 &&
          response.body.contains('Voz Segura');
    } catch (_) {
      return false;
    }
  }

  // Descobre o backend dinamicamente, independente da rede atual:
  // 1. Última URL que funcionou (cache local) — rápido e sem internet
  // 2. Endereços registrados pelo backend no Firestore (config/backend), túnel por último
  // 3. Varredura da subnet local — acha o backend em redes novas, mesmo sem internet
  static Future<void> loadDynamicBackendUrl() async {
    // Prioridade 1: cache da última URL boa
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cachedUrlKey);
      if (cached != null && cached.isNotEmpty && await _isReachable(cached)) {
        _evolutionBackendUrl = cached;
        print('VozSeguraConfig: ✅ Backend acessível via cache: $cached');
        return;
      }
    } catch (_) {}

    // Prioridade 2 e 3: endereços publicados pelo backend no Firestore
    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('backend')
          .get()
          .timeout(const Duration(seconds: 5));

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final lanUrls = (data['urls'] as List?)?.cast<String>() ?? const [];
        final tunnelUrl = data['tunnelUrl'] as String?;
        // Campo legado de versões antigas do backend
        final legacyUrl = data['url'] as String?;

        // IPs locais primeiro (mais rápidos e estáveis), túnel por último
        final lanWinner = await _firstReachable(lanUrls);
        final winner = lanWinner ??
            await _firstReachable([
              if (tunnelUrl != null && tunnelUrl.isNotEmpty) tunnelUrl,
              if (legacyUrl != null && legacyUrl.isNotEmpty) legacyUrl,
            ]);

        if (winner != null) {
          _evolutionBackendUrl = winner;
          await _saveCachedUrl(winner);
          print('VozSeguraConfig: ✅ Backend descoberto via Firestore: $winner');
          return;
        }
        print('VozSeguraConfig: ⚠️ Nenhum endereço do Firestore respondeu.');
      }
    } catch (e) {
      print('VozSeguraConfig: ⚠️ Firestore indisponível: $e');
    }

    // Prioridade 4: varredura da subnet local (rede nova / sem internet)
    final scanned = await _scanLocalSubnet();
    if (scanned != null) {
      _evolutionBackendUrl = scanned;
      await _saveCachedUrl(scanned);
      print('VozSeguraConfig: ✅ Backend encontrado na varredura local: $scanned');
      return;
    }

    print('VozSeguraConfig: ❌ Backend inacessível. Verifique se o servidor está rodando (docker compose up -d).');
  }

  // Redescobre o backend após uma falha de conexão (ex: troca de Wi-Fi no meio
  // da sessão). Retorna true se encontrou uma URL acessível.
  static Future<bool> rediscover() async {
    print('VozSeguraConfig: 🔄 Redescobrindo backend...');
    await loadDynamicBackendUrl();
    return _evolutionBackendUrl.isNotEmpty &&
        await _isReachable(_evolutionBackendUrl);
  }

  // Timeout para tentativa de envio silencioso via backend
  static const Duration silentSendTimeout = Duration(seconds: 8);

  // Timeout para obter QR Code / pairing code de vinculação
  // (o backend pode levar ~12s gerando o pairing code com retries internos)
  static const Duration qrCodeTimeout = Duration(seconds: 30);
}
