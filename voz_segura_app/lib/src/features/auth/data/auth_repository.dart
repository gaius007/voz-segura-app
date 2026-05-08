import 'package:firebase_auth/firebase_auth.dart';
import '../domain/app_user.dart';

// Essa classe cuida do login e logout no Firebase
// O professor disse que eh bom separar pra nao ficar tudo na tela
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream pra saber se o usuario ta logado ou nao
  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().map((user) {
      if (user == null) return null;
      return AppUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
      );
    });
  }

  // Pega o usuario que ta logado agora
  AppUser? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
    );
  }

  // Funcao pra entrar no app
  Future<AppUser?> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email, 
      password: password,
    );
    final user = credential.user;
    if (user == null) return null;
    return AppUser(uid: user.uid, email: user.email ?? '');
  }

  // Funcao pra criar conta
  Future<AppUser?> signUp(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email, 
      password: password,
    );
    final user = credential.user;
    if (user == null) return null;
    return AppUser(uid: user.uid, email: user.email ?? '');
  }

  // Sair do app
  Future<void> signOut() {
    return _auth.signOut();
  }
}
