import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:voz_segura_app/src/core/theme/app_theme.dart';
import 'package:voz_segura_app/src/features/auth/data/auth_repository.dart';
import 'package:voz_segura_app/src/features/shared/camouflage/camouflage_notifier.dart';
import 'package:voz_segura_app/src/features/shared/camouflage/camouflage_dialog.dart';
import 'package:voz_segura_app/src/features/sos/data/evolution_api_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _wordController;
  late TextEditingController _nameController;
  final EvolutionApiService _evolutionService = EvolutionApiService();

  @override
  void initState() {
    super.initState();
    final notifier = context.read<CamouflageNotifier>();
    _wordController = TextEditingController(text: notifier.secretWord);
    _nameController = TextEditingController();

    // Recarrega o usuario em segundo plano para obter o displayName mais recente
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await context.read<AuthRepository>().reload();
        if (mounted) setState(() {});
      } catch (e) {
        debugPrint('VS: Erro ao recarregar usuario nas configuracoes: $e');
      }
    });
  }

  @override
  void dispose() {
    _wordController.dispose();
    _nameController.dispose();
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
              _buildEditRow(
                'Nome Completo',
                user?.displayName ?? 'Usuária Voz Segura',
                () => _showEditNameDialog(context, authRepo),
              ),
              const Divider(height: 24, color: AppColors.sakura),
              _buildInfoRow('Email', user?.email ?? 'Não informado'),
              const Divider(height: 24, color: AppColors.sakura),
              _buildInfoRow('ID do Usuário', user?.uid ?? '---'),
            ]),

            const SizedBox(height: 32),

            // Seção de Dispositivo de Emergência (WhatsApp vinculado)
            _buildSectionHeader('Dispositivo de Emergência', Icons.phonelink_ring_outlined),
            const SizedBox(height: 16),
            _buildWhatsAppSection(user?.uid),

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

  // Seção de vinculação do WhatsApp com status em tempo real do Firestore
  Widget _buildWhatsAppSection(String? uid) {
    if (uid == null) {
      return _buildInfoCard([
        const Text(
          'Faça login para ver o status do seu dispositivo.',
          style: TextStyle(color: AppColors.textLight),
        ),
      ]);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        // Estado de carregamento
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildInfoCard([
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
              ),
            ),
          ]);
        }

        // Se o documento do usuario nao existir ainda no Firestore
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildInfoCard([
            const Text(
              'Perfil ainda não configurado. Complete o cadastro com seu número de WhatsApp.',
              style: TextStyle(color: AppColors.textLight, fontSize: 13),
            ),
          ]);
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final bool isConnected = userData?['whatsappConnected'] ?? false;
        final String phoneNumber = userData?['phoneNumber'] ?? 'Não cadastrado';

        return _buildInfoCard([
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('WhatsApp Vinculado', style: TextStyle(color: AppColors.rose)),
                    const SizedBox(height: 4),
                    Text(
                      phoneNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isConnected
                      ? Colors.green.withValues(alpha: 0.1)
                      : AppColors.ruby.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isConnected ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      size: 14,
                      color: isConnected ? Colors.green : AppColors.ruby,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isConnected ? 'CONECTADO' : 'DESCONECTADO',
                      style: TextStyle(
                        color: isConnected ? Colors.green : AppColors.ruby,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.sakura),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handleWhatsAppConnection(context, uid, isConnected),
              icon: Icon(
                isConnected ? Icons.phonelink_erase_rounded : Icons.qr_code_2_rounded,
                size: 20,
              ),
              label: Text(
                isConnected ? 'Desconectar Dispositivo' : 'Vincular por QR Code',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isConnected ? AppColors.rose : AppColors.ruby,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isConnected
                ? 'Seu WhatsApp está pronto para disparos automáticos de emergência.'
                : 'Vincule seu WhatsApp para habilitar envio automático silencioso no SOS.',
            style: const TextStyle(fontSize: 11, color: AppColors.textLight),
            textAlign: TextAlign.center,
          ),
        ]);
      },
    );
  }

  // Gerencia a conexao/desconexao do WhatsApp
  void _handleWhatsAppConnection(BuildContext context, String uid, bool isConnected) async {
    if (isConnected) {
      // Confirma desconexao
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Desconectar WhatsApp?',
            style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'O envio automático silencioso de WhatsApp será desativado. '
            'O app usará o fallback manual (abrindo o WhatsApp) nos próximos alertas de SOS.',
            style: TextStyle(color: AppColors.textMain, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.rose)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.ruby),
              child: const Text('Desconectar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await _evolutionService.disconnectWhatsApp(uid);
        // Atualiza status no Firestore localmente
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'whatsappConnected': false,
        });
      }
      return;
    }

    // Mostra modal de QR Code para vincular
    _showQRCodeDialog(context, uid);
  }

  // Modal de QR Code para vinculacao do WhatsApp
  void _showQRCodeDialog(BuildContext context, String uid) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.qr_code_2_rounded, color: AppColors.ruby, size: 24),
            SizedBox(width: 8),
            Text(
              'Vincular WhatsApp',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ruby),
            ),
          ],
        ),
        content: FutureBuilder<String?>(
          future: _evolutionService.fetchQRCode(uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 220,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.ruby),
                      SizedBox(height: 16),
                      Text(
                        'Gerando QR Code...',
                        style: TextStyle(color: AppColors.textLight, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (snapshot.hasError || snapshot.data == null) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: AppColors.ruby, size: 48),
                      SizedBox(height: 16),
                      Text(
                        'Erro ao gerar QR Code.',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Verifique se o backend está configurado e tente novamente.',
                        style: TextStyle(color: AppColors.textLight, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            // Decodifica o QR Code Base64
            try {
              final qrData = snapshot.data!;
              final base64String = qrData.contains(',') ? qrData.split(',').last : qrData;
              final bytes = base64Decode(base64String);

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Abra o WhatsApp no celular:\nAparelhos conectados → Conectar aparelho',
                    style: TextStyle(fontSize: 13, color: AppColors.textMain, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.sakura, width: 2),
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                    ),
                    child: Image.memory(
                      bytes,
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Escaneie este código com seu WhatsApp',
                    style: TextStyle(fontSize: 11, color: AppColors.textLight),
                  ),
                ],
              );
            } catch (e) {
              return const Text(
                'Formato de QR Code inválido.',
                style: TextStyle(color: AppColors.ruby),
              );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Fechar', style: TextStyle(color: AppColors.rose)),
          ),
        ],
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
          activeThumbColor: AppColors.ruby,
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

  void _showEditNameDialog(BuildContext context, AuthRepository authRepo) {
    _nameController.text = authRepo.currentUser?.displayName ?? '';
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Alterar Nome Completo',
              style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Este nome será exibido nos seus relatos públicos para a comunidade.',
                  style: TextStyle(fontSize: 13, color: AppColors.rose),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  cursorColor: AppColors.ruby,
                  style: const TextStyle(color: AppColors.textMain),
                  decoration: const InputDecoration(
                    labelText: 'Nome Completo',
                    labelStyle: TextStyle(color: AppColors.rose),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.ruby),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.sakura),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text('Cancelar', style: TextStyle(color: AppColors.rose)),
              ),
              isLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.ruby),
                        ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () async {
                        final newName = _nameController.text.trim();
                        if (newName.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('O nome não pode ser vazio.'),
                              backgroundColor: AppColors.ruby,
                            ),
                          );
                          return;
                        }
                        
                        setDialogState(() {
                          isLoading = true;
                        });

                        try {
                          await authRepo.updateDisplayName(newName);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Nome atualizado com sucesso!'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                            setState(() {}); // Recarrega tela de configurações com novo nome
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erro ao atualizar nome: $e'),
                                backgroundColor: AppColors.ruby,
                              ),
                            );
                          }
                        } finally {
                          if (context.mounted) {
                            setDialogState(() {
                              isLoading = false;
                            });
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ruby,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Salvar', style: TextStyle(color: Colors.white)),
                    ),
            ],
          );
        },
      ),
    );
  }
}
