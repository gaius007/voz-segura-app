import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/comment.dart';
import '../../domain/usecases/add_comment.dart';
import '../../domain/usecases/delete_comment.dart';
import '../../domain/usecases/watch_comments.dart';

/// Notifier de comentários de UM relato. Assina o stream do Firestore,
/// agrupa raízes/respostas e resolve os nomes das autoras conforme a
/// preferência de anonimato vigente em public_profiles.
class CommentNotifier extends ChangeNotifier {
  CommentNotifier({
    required this.reportId,
    required WatchComments watchComments,
    required AddComment addComment,
    required DeleteComment deleteComment,
  })  : _watchComments = watchComments,
        _addComment = addComment,
        _deleteComment = deleteComment {
    _subscription = _watchComments.execute(reportId).listen(
      _onComments,
      onError: (e) {
        _error = 'Falha ao carregar comentários.';
        _loading = false;
        notifyListeners();
      },
    );
  }

  final String reportId;
  final WatchComments _watchComments;
  final AddComment _addComment;
  final DeleteComment _deleteComment;

  StreamSubscription<List<Comment>>? _subscription;

  List<Comment> _roots = [];
  Map<String, List<Comment>> _repliesByParent = {};
  Map<String, CommentAuthor> _authors = {};
  bool _loading = true;
  bool _sending = false;
  String? _error;
  int _total = 0;

  List<Comment> get roots => _roots;
  bool get loading => _loading;
  bool get sending => _sending;
  String? get error => _error;
  int get total => _total;

  List<Comment> repliesOf(String commentId) =>
      _repliesByParent[commentId] ?? const [];

  CommentAuthor authorOf(Comment comment) =>
      _authors[comment.authorUid] ?? CommentAuthor.anonymous;

  Future<void> _onComments(List<Comment> comments) async {
    _total = comments.where((c) => !c.deleted).length;
    _roots = comments.where((c) => c.parentId == null).toList();
    _repliesByParent = {};
    for (final c in comments) {
      final parent = c.parentId;
      if (parent != null) {
        _repliesByParent.putIfAbsent(parent, () => []).add(c);
      }
    }

    // Resolve TODOS os uids a cada atualização: a preferência de anonimato é
    // dinâmica e pode ter mudado desde a última leitura.
    try {
      final uids = comments.map((c) => c.authorUid).where((u) => u.isNotEmpty).toSet();
      _authors = await _watchComments.resolveAuthors(uids);
    } catch (e) {
      debugPrint('CommentNotifier: falha ao resolver autoras: $e');
    }

    _loading = false;
    _error = null;
    notifyListeners();
  }

  Future<bool> send({
    required String text,
    required String authorUid,
    String? parentId,
  }) async {
    _sending = true;
    _error = null;
    notifyListeners();
    try {
      await _addComment.execute(
        reportId,
        Comment(
          id: '',
          text: text.trim(),
          createdAt: DateTime.now(),
          authorUid: authorUid,
          parentId: parentId,
        ),
      );
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  Future<bool> delete(String commentId) async {
    try {
      await _deleteComment.execute(reportId, commentId);
      return true;
    } catch (e) {
      _error = 'Falha ao remover o comentário.';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
