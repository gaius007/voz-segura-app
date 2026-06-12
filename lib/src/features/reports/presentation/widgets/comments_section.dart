import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voz_segura_app/src/core/theme/app_theme.dart';
import 'package:voz_segura_app/src/features/auth/domain/auth_repository.dart';

import '../../domain/entities/comment.dart';
import '../../domain/usecases/add_comment.dart';
import '../../domain/usecases/delete_comment.dart';
import '../../domain/usecases/watch_comments.dart';
import '../manager/comment_notifier.dart';
import 'comment_tile.dart';

/// Seção de comentários embutida na página de detalhe do relato.
/// Cada conversa (comentário + respostas) é um cartão próprio, com as
/// respostas aninhadas sob uma linha-guia — divisão clara entre threads.
class CommentsSection extends StatelessWidget {
  const CommentsSection({super.key, required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => CommentNotifier(
        reportId: reportId,
        watchComments: ctx.read<WatchComments>(),
        addComment: ctx.read<AddComment>(),
        deleteComment: ctx.read<DeleteComment>(),
      ),
      child: const _CommentsBody(),
    );
  }
}

class _CommentsBody extends StatefulWidget {
  const _CommentsBody();

  @override
  State<_CommentsBody> createState() => _CommentsBodyState();
}

class _CommentsBodyState extends State<_CommentsBody> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  /// Comentário sendo respondido (null = comentário raiz)
  Comment? _replyingTo;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _send(CommentNotifier notifier) async {
    final uid = context.read<AuthRepository>().currentUser?.uid;
    if (uid == null) return;

    // Respostas de respostas viram resposta do mesmo pai (1 nível de indentação)
    final parentId = _replyingTo == null
        ? null
        : (_replyingTo!.parentId ?? _replyingTo!.id);

    final ok = await notifier.send(
      text: _textController.text,
      authorUid: uid,
      parentId: parentId,
    );
    if (ok && mounted) {
      _textController.clear();
      _focusNode.unfocus();
      setState(() => _replyingTo = null);
    }
  }

  void _startReply(Comment comment) {
    setState(() => _replyingTo = comment);
    _focusNode.requestFocus();
  }

  Future<void> _confirmDelete(CommentNotifier notifier, Comment comment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Excluir comentário?',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: const Text(
            'O comentário será marcado como removido. Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.rose)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.ruby),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) await notifier.delete(comment.id);
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<CommentNotifier>();
    final currentUid = context.read<AuthRepository>().currentUser?.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Cabeçalho da seção ─────────────────────────────
        Row(
          children: [
            Text(
              'CONVERSA ENTRE USUÁRIAS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: context.appRuby,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: context.appPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${notifier.total}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: context.appPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.visibility_off_outlined,
                size: 13, color: context.appTextLight),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Comentários são anônimos por padrão. Você pode exibir seu nome em Ajustes → Privacidade.',
                style: TextStyle(fontSize: 11.5, color: context.appTextLight, height: 1.3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ─── Lista de conversas (um cartão por thread) ──────
        if (notifier.loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (notifier.roots.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: context.appSakura.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.appRose.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                Icon(Icons.forum_outlined, size: 36, color: context.appRose),
                const SizedBox(height: 10),
                Text(
                  'Nenhum comentário ainda.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.appTextMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Seja a primeira a deixar uma palavra de apoio. 💜',
                  style: TextStyle(fontSize: 12.5, color: context.appTextLight),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: notifier.roots.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final root = notifier.roots[index];
              final replies = notifier.repliesOf(root.id);
              return _ThreadCard(
                root: root,
                replies: replies,
                notifier: notifier,
                currentUid: currentUid,
                onReply: _startReply,
                onDelete: (c) => _confirmDelete(notifier, c),
              );
            },
          ),

        if (notifier.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              notifier.error!,
              style: const TextStyle(fontSize: 12, color: AppColors.ruby),
            ),
          ),

        const SizedBox(height: 16),

        // ─── Caixa de envio ─────────────────────────────────
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.appCardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.appDivider),
            boxShadow: context.appSoftShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Faixa "Respondendo a..." quando aplicável
              if (_replyingTo != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.appPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: context.appPrimary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.reply_rounded,
                          size: 15, color: context.appPrimary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Respondendo a ${context.read<CommentNotifier>().authorOf(_replyingTo!).displayName}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: context.appPrimary,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _replyingTo = null),
                        child: Icon(Icons.close_rounded,
                            size: 16, color: context.appTextLight),
                      ),
                    ],
                  ),
                ),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLength: 1000,
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: _replyingTo == null
                            ? 'Deixe uma palavra de apoio...'
                            : 'Escreva sua resposta...',
                        hintStyle: TextStyle(
                            fontSize: 13, color: context.appTextLight),
                        counterText: '',
                        isDense: true,
                        filled: false,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: context.appPrimary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: notifier.sending ? null : () => _send(notifier),
                      child: Padding(
                        padding: const EdgeInsets.all(11),
                        child: notifier.sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send_rounded,
                                size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Cartão de uma conversa: comentário raiz + respostas aninhadas sob uma
/// linha-guia vertical, claramente separadas do comentário principal.
class _ThreadCard extends StatelessWidget {
  const _ThreadCard({
    required this.root,
    required this.replies,
    required this.notifier,
    required this.currentUid,
    required this.onReply,
    required this.onDelete,
  });

  final Comment root;
  final List<Comment> replies;
  final CommentNotifier notifier;
  final String? currentUid;
  final void Function(Comment) onReply;
  final void Function(Comment) onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: context.appCardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appDivider),
        boxShadow: context.appSoftShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommentTile(
            comment: root,
            author: notifier.authorOf(root),
            isOwn: root.authorUid == currentUid,
            onReply: root.deleted ? null : () => onReply(root),
            onDelete: root.authorUid == currentUid && !root.deleted
                ? () => onDelete(root)
                : null,
          ),

          // Respostas: bloco aninhado com linha-guia à esquerda
          if (replies.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: context.appPrimary.withValues(alpha: 0.25),
                      width: 2.5,
                    ),
                  ),
                ),
                padding: const EdgeInsets.only(left: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < replies.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 16,
                          thickness: 0.6,
                          color: context.appDivider,
                        ),
                      CommentTile(
                        comment: replies[i],
                        author: notifier.authorOf(replies[i]),
                        isOwn: replies[i].authorUid == currentUid,
                        isReply: true,
                        onReply: replies[i].deleted
                            ? null
                            : () => onReply(replies[i]),
                        onDelete: replies[i].authorUid == currentUid &&
                                !replies[i].deleted
                            ? () => onDelete(replies[i])
                            : null,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
