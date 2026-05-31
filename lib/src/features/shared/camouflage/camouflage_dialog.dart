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
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: BoxDecoration(
          color: context.appCardColor,
          borderRadius: BorderRadius.circular(AppStyles.borderRadius),
          boxShadow: context.appSoftShadow,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.security, color: context.appRuby, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Modo Camuflagem',
                      style: AppStyles.h1.copyWith(color: context.appRuby),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Ao ativar, o app inteiro vira um portal de notícias ("Diário de Notícias"). Quem pegar seu celular verá apenas notícias — seus relatos e contatos ficam ocultos.',
                style: AppStyles.subtitle.copyWith(color: context.appTextLight),
              ),
              const SizedBox(height: 20),
              _buildStep(
                icon: Icons.vpn_key_rounded,
                title: 'Sua palavra-chave',
                text: 'Ela aparece disfarçada como uma notícia em destaque ("ESPECIAL") no portal. É o seu ponto secreto de saída — só você sabe qual é.',
              ),
              const SizedBox(height: 12),
              _buildStep(
                icon: Icons.newspaper_rounded,
                title: 'Como acessar',
                text: 'Basta ativar este modo. O disfarce começa na hora e continua ativo mesmo se você fechar e abrir o app.',
              ),
              const SizedBox(height: 12),
              _buildStep(
                icon: Icons.touch_app_rounded,
                title: 'Como sair com segurança',
                text: 'No portal, segure (toque longo de ~5 segundos) a notícia "ESPECIAL" com o título da sua palavra-chave até a barra encher. Um toque rápido apenas abre uma notícia falsa, mantendo o disfarce.',
              ),
              const SizedBox(height: 20),
              Text(
                'Defina sua palavra-chave de saída:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: context.appRuby,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                style: TextStyle(color: context.appTextMain),
                decoration: InputDecoration(
                  hintText: 'Ex: flores, receitas, viagem',
                  prefixIcon: Icon(Icons.key, color: context.appRose),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _dontShowAgain,
                    activeColor: context.appRuby,
                    onChanged: (val) =>
                        setState(() => _dontShowAgain = val ?? false),
                  ),
                  Expanded(
                    child: Text(
                      'Não mostrar esta explicação novamente',
                      style: TextStyle(fontSize: 12, color: context.appTextMain),
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
                        foregroundColor: context.appRose,
                        side: BorderSide(color: context.appGlassBorder),
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
                        backgroundColor: context.appRuby,
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
      ),
    );
  }

  Widget _buildStep({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.appSakura,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: context.appRuby, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: context.appTextMain,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: TextStyle(color: context.appTextLight, fontSize: 12.5, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
