import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../auth/data/firebase_auth_repository.dart';

part 'sos_controller.g.dart';

@riverpod
class SOSController extends _$SOSController {
  @override
  bool build() => false;

  void toggleSOS() {
    state = !state;
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).signOut();
  }
}
