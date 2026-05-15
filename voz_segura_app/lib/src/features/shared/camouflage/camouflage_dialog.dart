import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'camouflage_notifier.dart';
import 'package:voz_segura_app/src/core/theme/app_theme.dart';

class CamouflageDialog extends StatefulWidget {
  const CamouflageDialog({super.key});

  @override
  State<CamouflageDialog> createState() => _CamouflageDialogState();
}

class _CamouflageDialogState extends State<CamouflageDialog> {
  late TextEditingController _controller;
  bool _dontShowAgain = false;

  @override
  void initState() {
    super.initState();
    final notifier = context.read<CamouflageNotifier>();
    _controller = TextEditingController(text: notifier.secretWord);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppStyles.borderRadius),
          boxShadow: AppStyles.softShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.security, color: AppColors.ruby, size: 28),
                const SizedBox(width: 12),
                Text('Modo Camuflagem', style: AppStyles.h1),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Este modo altera completamente o visual do app para disfarçá-lo como um aplicativo de notícias genérico. Isso protege sua privacidade caso alguém acesse seu celular.',
              style: AppStyles.subtitle,
            ),
            const SizedBox(height: 16),
            const Text(
              'Defina sua palavra secreta:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.ruby,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Ex: flores, noticias, etc',
                prefixIcon: const Icon(Icons.key, color: AppColors.rose),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _dontShowAgain,
                  activeColor: AppColors.ruby,
                  onChanged: (val) =>
                      setState(() => _dontShowAgain = val ?? false),
                ),
                const Expanded(
                  child: Text(
                    'Não mostrar esta explicação novamente',
                    style: TextStyle(fontSize: 12, color: AppColors.textMain),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.rose,
                      side: const BorderSide(color: AppColors.sakura),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final notifier = context.read<CamouflageNotifier>();
                      notifier.setSecretWord(_controller.text.trim());
                      notifier.setShowExplanation(!_dontShowAgain);
                      notifier.setCamouflaged(true);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ruby,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Ativar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
