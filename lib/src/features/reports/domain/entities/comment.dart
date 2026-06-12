import 'package:cloud_firestore/cloud_firestore.dart';

/// Comentário de um relato (subcoleção reports/{id}/comments).
/// O nome da autora NÃO é gravado aqui: a exibição resolve dinamicamente via
/// public_profiles/{authorUid}, respeitando a preferência de anonimato VIGENTE
/// (mudar a preferência reflete em todos os comentários, antigos e novos).
class Comment {
  final String id;
  final String text;
  final DateTime createdAt;
  final String authorUid;

  /// null = comentário raiz; senão, id do comentário-pai (1 nível de respostas)
  final String? parentId;

  /// Soft delete: mantém o lugar no thread, exibido como "Comentário removido"
  final bool deleted;

  Comment({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.authorUid,
    this.parentId,
    this.deleted = false,
  });

  factory Comment.fromMap(Map<String, dynamic> map, String docId) {
    final rawDate = map['createdAt'];
    return Comment(
      id: docId,
      text: map['text'] as String? ?? '',
      createdAt: rawDate is Timestamp ? rawDate.toDate() : DateTime.now(),
      authorUid: map['authorUid'] as String? ?? '',
      parentId: map['parentId'] as String?,
      deleted: map['deleted'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'authorUid': authorUid,
        'parentId': parentId,
        'deleted': deleted,
      };
}

/// Identidade pública resolvida para exibição de um comentário.
class CommentAuthor {
  final String displayName;

  const CommentAuthor({required this.displayName});

  static const anonymous = CommentAuthor(displayName: 'Anônima');
}
