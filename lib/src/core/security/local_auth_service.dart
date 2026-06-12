import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';

/// Autenticação local (biometria ou PIN/padrão do aparelho) exigida antes de
/// ações sensíveis: editar/excluir relatos e contatos de emergência.
///
/// Política fail-open: se o aparelho não tem bloqueio de tela configurado,
/// a ação é liberada — a autoria real continua garantida pelas regras do
/// Firestore (server-side). A biometria aqui protege contra terceiros com o
/// celular desbloqueado em mãos.
class LocalAuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> authenticate(String reason) async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return true; // sem lock screen configurado

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // cai para PIN/padrão se não houver biometria
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e) {
      // Sem hardware/sem cadastro → fail-open; bloqueado por tentativas → nega
      if (e.code == auth_error.notAvailable ||
          e.code == auth_error.notEnrolled) {
        return true;
      }
      return false;
    }
  }
}
