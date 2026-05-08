// Classe que representa o usuario do app
// O professor disse que eh bom ter os campos final pra nao dar bug de estado
class AppUser {
  final String uid;
  final String email;
  final String? displayName;

  AppUser({
    required this.uid,
    required this.email,
    this.displayName,
  });

  // Transforma o JSON do Firebase no nosso objeto de usuario
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
    );
  }

  // Transforma o usuario em Map pra salvar no banco se precisar
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
    };
  }
}
