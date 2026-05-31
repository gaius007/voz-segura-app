import 'package:flutter/material.dart';
import 'package:voz_segura_app/src/core/theme/app_theme.dart';

/// Diálogo de confirmação reutilizável, seguindo o padrão visual já usado
/// nos relatos (ícone de aviso + botão destrutivo em [AppColors.ruby]).
///
/// Retorna `true` se a usuária confirmar, `false` caso contrário.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Excluir',
  String cancelLabel = 'Cancelar',
  bool danger = true,
}) async {
  final color = danger ? context.appRuby : context.appPrimary;

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: context.appCardColor,
      title: Row(
        children: [
          Icon(
            danger ? Icons.warning_amber_rounded : Icons.help_outline_rounded,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: TextStyle(color: context.appTextMain, fontSize: 14, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            cancelLabel,
            style: TextStyle(color: context.appTextLight),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: Text(
            confirmLabel,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );

  return result ?? false;
}
