import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/comment.dart';
import '../../domain/repositories/comment_repository.dart';

class CommentRepositoryImpl implements CommentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _comments(String reportId) =>
      _firestore.collection('reports').doc(reportId).collection('comments');

  @override
  Stream<List<Comment>> watchComments(String reportId) {
    return _comments(reportId)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Comment.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<void> addComment(String reportId, Comment comment) {
    return _comments(reportId)
        .add(comment.toMap())
        .timeout(const Duration(seconds: 15));
  }

  @override
  Future<void> deleteComment(String reportId, String commentId) {
    // Soft delete: respostas continuam com o pai visível como "removido"
    return _comments(reportId)
        .doc(commentId)
        .update({'deleted': true, 'text': ''})
        .timeout(const Duration(seconds: 15));
  }

  @override
  Future<Map<String, CommentAuthor>> resolveAuthors(Set<String> uids) async {
    if (uids.isEmpty) return const {};

    // whereIn aceita no máximo 10 ids por consulta — busca em lotes
    final result = <String, CommentAuthor>{};
    final list = uids.toList();
    for (var i = 0; i < list.length; i += 10) {
      final batch = list.sublist(i, (i + 10).clamp(0, list.length));
      final snap = await _firestore
          .collection('public_profiles')
          .where(FieldPath.documentId, whereIn: batch)
          .get()
          .timeout(const Duration(seconds: 10));

      for (final doc in snap.docs) {
        final data = doc.data();
        final showName = data['showNameInComments'] == true;
        final name = (data['name'] as String?)?.trim();
        result[doc.id] = (showName && name != null && name.isNotEmpty)
            ? CommentAuthor(displayName: name)
            : CommentAuthor.anonymous;
      }
    }

    // Perfis inexistentes (usuárias antigas sem public_profile) → anônimas
    for (final uid in uids) {
      result.putIfAbsent(uid, () => CommentAuthor.anonymous);
    }
    return result;
  }
}
