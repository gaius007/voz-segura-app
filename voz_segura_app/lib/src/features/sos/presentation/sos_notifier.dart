import 'package:flutter/material.dart';
import '../../auth/data/auth_repository.dart';

// Esse Notifier controla o botao de panico (SOS)
// Fiz com ChangeNotifier pq o professor ensinou assim
class SOSNotifier extends ChangeNotifier {
  final AuthRepository authRepository;
  
  // Diz se o SOS ta ligado ou nao
  bool _isSOSActive = false;
  bool get isSOSActive => _isSOSActive;

  SOSNotifier({required this.authRepository});

  // Liga e desliga o SOS
  void toggleSOS() {
    _isSOSActive = !_isSOSActive;
    notifyListeners(); // avisa a tela pra mudar a cor do botao
  }

  // Funcao pra deslogar o usuario
  Future<void> logout() async {
    await authRepository.signOut();
  }
}
