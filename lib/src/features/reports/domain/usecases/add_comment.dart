import '../entities/comment.dart';
import '../repositories/comment_repository.dart';

// Caso de uso para publicar um comentário (ou resposta) em um relato.
class AddComment {
  final CommentRepository repository;

  AddComment(this.repository);

  Future<void> execute(String reportId, Comment comment) async {
    final text = comment.text.trim();
    if (text.isEmpty) {
      throw Exception('Escreva algo antes de comentar.');
    }
    if (text.length > 1000) {
      throw Exception('O comentário pode ter no máximo 1000 caracteres.');
    }
    return repository.addComment(reportId, comment);
  }
}
