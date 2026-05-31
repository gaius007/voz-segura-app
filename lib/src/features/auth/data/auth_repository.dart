import 'package:firebase_auth/firebase_auth.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

// Essa classe cuida do login e logout no Firebase
// O professor disse que eh bom separar pra nao ficar tudo na tela
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream pra saber se o usuario ta logado ou nao
  @override
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
  @override
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
  @override
  Future<AppUser?> signInWithEmailAndPassword(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) return null;
    return AppUser(uid: user.uid, email: user.email ?? '');
  }

  // Funcao pra criar conta
  @override
  Future<AppUser?> createUserWithEmailAndPassword(String email, String password, {String? displayName}) async {
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
  @override
  Future<void> signOut() {
    return _auth.signOut();
  }

  // Recarrega os dados do usuario do servidor para atualizar o cache local (ex: displayName)
  @override
  Future<void> reload() async {
    await _auth.currentUser?.reload();
  }

  // Atualiza o nome do usuario logado no Firebase Auth e recarrega
  @override
  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(name);
      await user.reload();
    }
  }

  // Envia e-mail de recuperacao de senha via Firebase Auth
  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
