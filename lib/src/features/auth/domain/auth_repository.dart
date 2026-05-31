import 'app_user.dart';

abstract class AuthRepository {
  Future<AppUser?> signInWithEmailAndPassword(String email, String password);
  Future<AppUser?> createUserWithEmailAndPassword(String email, String password, {String? displayName});
  Future<void> signOut();
  Stream<AppUser?> authStateChanges();
  AppUser? get currentUser;
  Future<void> reload();
  Future<void> updateDisplayName(String name);
  Future<void> sendPasswordResetEmail(String email);
}
