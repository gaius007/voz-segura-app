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
  Future<AppUser?> signUp(String email, String password, {String? displayName}) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email, 
      password: password,
    );
    final user = credential.user;
    if (user == null) return null;
    if (displayName != null && displayName.isNotEmpty) {
      await user.updateDisplayName(displayName);
      await user.reload(); // Força o reload do cache local do Firebase Auth
    }
    final refreshedUser = _auth.currentUser ?? user;
    return AppUser(
      uid: refreshedUser.uid, 
      email: refreshedUser.email ?? '',
      displayName: displayName ?? refreshedUser.displayName,
    );
  }

  // Sair do app
  Future<void> signOut() {
    return _auth.signOut();
  }

  // Recarrega os dados do usuario do servidor para atualizar o cache local (ex: displayName)
  Future<void> reload() async {
    await _auth.currentUser?.reload();
  }

  // Atualiza o nome do usuario logado no Firebase Auth e recarrega
  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(name);
      await user.reload();
    }
  }
}


