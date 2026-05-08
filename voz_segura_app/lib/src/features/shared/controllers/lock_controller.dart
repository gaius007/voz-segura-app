import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:local_auth/local_auth.dart';

part 'lock_controller.g.dart';

@riverpod
class LockController extends _$LockController {
  final _auth = LocalAuthentication();
  bool _isMandatory = true; // Pode ser alterado via settings futuramente

  @override
  bool build() => false; // false = bloqueado

  void setMandatory(bool value) => _isMandatory = value;

  Future<bool> authenticate() async {
    if (!_isMandatory) {
      state = true;
      return true;
    }

    try {
      final isAvailable = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      if (!isAvailable) {
        state = true; 
        return true;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: 'Autentique-se para ver seus relatos seguros',
      );

      state = authenticated;
      return authenticated;
    } catch (e) {
      state = false;
      return false;
    }
  }

  void lock() => state = false;
}
