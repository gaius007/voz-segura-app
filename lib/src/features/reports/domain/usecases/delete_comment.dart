import '../repositories/comment_repository.dart';

// Caso de uso para remover (soft delete) um comentário próprio.
class DeleteComment {
  final CommentRepository repository;

  DeleteComment(this.repository);

  Future<void> execute(String reportId, String commentId) {
    if (commentId.isEmpty) {
      throw Exception('Comentário inválido.');
    }
    return repository.deleteComment(reportId, commentId);
  }
}
