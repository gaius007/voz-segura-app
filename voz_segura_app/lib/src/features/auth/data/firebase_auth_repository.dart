import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/firebase_providers.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

part 'firebase_auth_repository.g.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;

  FirebaseAuthRepository(this._auth);

  @override
  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().map(_convertUser);
  }

  @override
  AppUser? get currentUser => _convertUser(_auth.currentUser);

  @override
  Future<AppUser?> signInWithEmailAndPassword(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return _convertUser(credential.user);
  }

  @override
  Future<AppUser?> createUserWithEmailAndPassword(String email, String password, {String? displayName}) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    if (displayName != null) {
      await credential.user?.updateDisplayName(displayName);
    }
    return _convertUser(credential.user);
  }

  @override
  Future<void> signOut() {
    return _auth.signOut();
  }

  AppUser? _convertUser(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
    );
  }
}

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return FirebaseAuthRepository(ref.watch(firebaseAuthProvider));
}
