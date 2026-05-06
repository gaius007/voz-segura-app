import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/firebase_auth_repository.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<void> build() {
    // Initial state: nothing happening
  }

  Future<bool> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => 
      ref.read(authRepositoryProvider).signInWithEmailAndPassword(email, password)
    );
    return !state.hasError;
  }

  Future<bool> register(String email, String password, String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => 
      ref.read(authRepositoryProvider).createUserWithEmailAndPassword(email, password, displayName: name)
    );
    return !state.hasError;
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).signOut());
  }
}
