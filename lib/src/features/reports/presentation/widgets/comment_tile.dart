import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:voz_segura_app/src/core/theme/app_theme.dart';

import '../../domain/entities/comment.dart';

/// Conteúdo de um comentário (usado tanto para a raiz quanto para respostas).
class CommentTile extends StatelessWidget {
  const CommentTile({
    super.key,
    required this.comment,
    required this.author,
    required this.isOwn,
    this.isReply = false,
    this.onReply,
    this.onDelete,
  });

  final Comment comment;
  final CommentAuthor author;
  final bool isOwn;
  final bool isReply;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;

  String _relativeDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inHours < 1) return 'há ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'há ${diff.inHours} h';
    if (diff.inDays < 7) return 'há ${diff.inDays} d';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (comment.deleted) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(Icons.block_rounded, size: 14, color: context.appTextLight),
            const SizedBox(width: 8),
            Text(
              'Comentário removido',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: context.appTextLight,
              ),
            ),
          ],
        ),
      );
    }

    final avatarSize = isReply ? 12.0 : 15.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho: avatar + nome + selo "você" + tempo + excluir
        Row(
          children: [
            CircleAvatar(
              radius: avatarSize,
              backgroundColor: isOwn
                  ? context.appPrimary.withValues(alpha: 0.9)
                  : context.appPrimary.withValues(alpha: 0.15),
              child: Icon(
                Icons.person_rounded,
                size: avatarSize + 2,
                color: isOwn ? Colors.white : context.appPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      author.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isReply ? 12.5 : 13.5,
                        fontWeight: FontWeight.bold,
                        color: context.appTextMain,
                      ),
                    ),
                  ),
                  if (isOwn) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: context.appPrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'você',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: context.appPrimary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _relativeDate(comment.createdAt),
              style: TextStyle(fontSize: 11, color: context.appTextLight),
            ),
            if (isOwn && onDelete != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDelete,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline_rounded,
                      size: 16, color: context.appTextLight),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),

        // Texto do comentário
        Padding(
          padding: EdgeInsets.only(left: (avatarSize * 2) + 8),
          child: Text(
            comment.text,
            style: TextStyle(
              fontSize: isReply ? 13.5 : 14,
              height: 1.45,
              color: context.appTextMain,
            ),
          ),
        ),

        // Ação de responder
        if (onReply != null)
          Padding(
            padding: EdgeInsets.only(left: (avatarSize * 2) + 8, top: 2),
            child: GestureDetector(
              onTap: onReply,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.reply_rounded,
                        size: 14, color: context.appPrimary),
                    const SizedBox(width: 4),
                    Text(
                      'Responder',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: context.appPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
