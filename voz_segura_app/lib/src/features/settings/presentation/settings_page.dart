import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voz_segura_app/src/core/theme/app_theme.dart';
import 'package:voz_segura_app/src/features/auth/data/auth_repository.dart';
import 'package:voz_segura_app/src/features/shared/camouflage/camouflage_notifier.dart';
import 'package:voz_segura_app/src/features/shared/camouflage/camouflage_dialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _wordController;

  @override
  void initState() {
    super.initState();
    final notifier = context.read<CamouflageNotifier>();
    _wordController = TextEditingController(text: notifier.secretWord);
  }

  @override
  void dispose() {
    _wordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = context.read<AuthRepository>();
    final user = authRepo.currentUser;
    final camouNotifier = context.watch<CamouflageNotifier>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seção de Conta
            _buildSectionHeader('Minha Conta', Icons.person_outline),
            const SizedBox(height: 16),
            _buildInfoCard([
              _buildInfoRow('Email', user?.email ?? 'Não informado'),
              const Divider(height: 24, color: AppColors.sakura),
              _buildInfoRow('ID do Usuário', user?.uid ?? '---'),
            ]),

            const SizedBox(height: 32),

            // Seção de Segurança / Camuflagem
            _buildSectionHeader('Segurança e Camuflagem', Icons.security_outlined),
            const SizedBox(height: 16),
            _buildInfoCard([
              _buildSwitchRow(
                'Modo Camuflagem',
                'Disfarça o app como um portal de notícias',
                camouNotifier.isCamouflaged,
                (val) {
                  if (val && camouNotifier.showExplanation) {
                    showDialog(
                      context: context,
                      builder: (_) => const CamouflageDialog(),
                    );
                  } else {
                    camouNotifier.setCamouflaged(val);
                  }
                },
              ),
              const Divider(height: 24, color: AppColors.sakura),
              _buildEditRow(
                'Palavra de Desativação',
                camouNotifier.secretWord,
                () => _showEditWordDialog(context, camouNotifier),
              ),
            ]),

            const SizedBox(height: 48),

            // Botão de Sair
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => authRepo.signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Sair da Conta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.ruby,
                  side: const BorderSide(color: AppColors.sakura),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.ruby, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppStyles.h1.copyWith(fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppStyles.softShadow,
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.rose)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain)),
      ],
    );
  }

  Widget _buildSwitchRow(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.rose)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.ruby,
          activeTrackColor: AppColors.sakura,
        ),
      ],
    );
  }

  Widget _buildEditRow(String label, String value, VoidCallback onEdit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.rose)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.ruby)),
          ],
        ),
        IconButton(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, color: AppColors.rose),
        ),
      ],
    );
  }

  void _showEditWordDialog(BuildContext context, CamouflageNotifier notifier) {
    _wordController.text = notifier.secretWord;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar Palavra'),
        content: TextField(
          controller: _wordController,
          decoration: const InputDecoration(
            hintText: 'Digite a nova palavra',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.rose)),
          ),
          ElevatedButton(
            onPressed: () {
              notifier.setSecretWord(_wordController.text.trim());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.ruby),
            child: const Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
