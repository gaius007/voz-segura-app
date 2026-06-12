import '../entities/comment.dart';

// Contrato de comentários dos relatos.
abstract class CommentRepository {
  /// Stream em tempo real de todos os comentários de um relato (ordem cronológica).
  Stream<List<Comment>> watchComments(String reportId);

  /// Publica um comentário (ou resposta, se parentId != null).
  Future<void> addComment(String reportId, Comment comment);

  /// Soft delete: marca como removido preservando o lugar no thread.
  Future<void> deleteComment(String reportId, String commentId);

  /// Resolve os nomes de exibição dos uids conforme a preferência de anonimato
  /// ATUAL de cada autora (public_profiles). Uid ausente/anônima → "Anônima".
  Future<Map<String, CommentAuthor>> resolveAuthors(Set<String> uids);
}
