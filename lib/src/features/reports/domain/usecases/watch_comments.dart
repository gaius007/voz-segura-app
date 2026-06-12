import '../entities/comment.dart';
import '../repositories/comment_repository.dart';

// Caso de uso para observar os comentários de um relato em tempo real.
class WatchComments {
  final CommentRepository repository;

  WatchComments(this.repository);

  Stream<List<Comment>> execute(String reportId) {
    return repository.watchComments(reportId);
  }

  Future<Map<String, CommentAuthor>> resolveAuthors(Set<String> uids) {
    return repository.resolveAuthors(uids);
  }
}
