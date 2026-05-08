import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class SecurityService {
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  static const _dbKeyName = 'secure_report_db_key';

  /// Obtém ou gera a chave de criptografia do banco de dados de forma segura.
  /// Se houver suporte a biometria, pode ser exigida antes de liberar a chave.
  Future<String> getDatabaseKey({bool requireBiometrics = false}) async {
    if (requireBiometrics) {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Autentique-se para acessar os relatos seguros',
      );
      if (!didAuthenticate) throw Exception('Falha na autenticação biométrica');
    }

    String? key = await _storage.read(key: _dbKeyName);
    
    if (key == null) {
      // Gera uma chave randômica forte de 32 bytes (256 bits)
      final random = Random.secure();
      final values = List<int>.generate(32, (i) => random.nextInt(256));
      key = base64Url.encode(values);
      await _storage.write(key: _dbKeyName, value: key);
    }

    return key;
  }
}
