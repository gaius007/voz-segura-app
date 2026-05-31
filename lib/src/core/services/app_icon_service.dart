import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Alterna o ícone do launcher entre o ícone padrão (imagem do login) e o
/// ícone genérico de notícias usado no modo camuflagem.
///
/// Implementado apenas no Android (via activity-alias + MethodChannel nativo).
/// Em outras plataformas as chamadas são ignoradas silenciosamente.
class AppIconService {
  static const MethodChannel _channel = MethodChannel('voz_segura/app_icon');

  static Future<void> _setIcon(String alias) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('setIcon', {'alias': alias});
    } catch (e) {
      debugPrint('VS: Falha ao alternar ícone do app: $e');
    }
  }

  /// Ativa o ícone disfarçado de notícias (modo camuflagem).
  static Future<void> setNewsIcon() => _setIcon('news');

  /// Restaura o ícone padrão do app (imagem da tela de login).
  static Future<void> setDefaultIcon() => _setIcon('default');
}
