import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'sos_notifier.dart';
import 'widgets/secure_sos_button.dart';
import 'package:voz_segura_app/src/core/theme/app_theme.dart';
import 'package:voz_segura_app/src/features/shared/camouflage/camouflage_notifier.dart';
import 'package:voz_segura_app/src/features/shared/camouflage/camouflage_dialog.dart';
import 'package:voz_segura_app/src/features/sos/data/evolution_api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  // Override local para quando não há internet e Firestore não sincroniza
  bool _localWhatsappConnected = false;

  // Stream do documento do usuário mantido em cache para não re-assinar o Firestore
  // a cada rebuild (ex.: quando o SOSNotifier notifica durante o envio).
  Stream<DocumentSnapshot>? _userDocStream;
  String? _streamUid;

  Stream<DocumentSnapshot> _userDocStreamFor(String uid) {
    if (_streamUid != uid || _userDocStream == null) {
      _streamUid = uid;
      _userDocStream =
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
    }
    return _userDocStream!;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Abre modal premium contendo o código de 8 caracteres para vincular o WhatsApp sem precisar escanear QR Code
  void _showPairingCodeDialog(BuildContext context, String uid, String phoneNumber) {
    final evolutionService = EvolutionApiService();
    Timer? pollingTimer;

    // Formata o número visualmente para exibição no modal
    String formatDisplayNumber(String numStr) {
      String clean = numStr.replaceAll(RegExp(r'\D'), '');
      if (!clean.startsWith('55') || clean.length < 4) return numStr;

      String ddd = clean.substring(2, 4);
      String rest = clean.substring(4);

      if (rest.length == 9) {
        return '+55 ($ddd) ${rest.substring(0, 5)}-${rest.substring(5)}';
      } else if (rest.length == 8) {
        return '+55 ($ddd) ${rest.substring(0, 4)}-${rest.substring(4)}';
      }
      return numStr;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        // StatefulBuilder permite o botão "Tentar Novamente" refazer o Future
        return StatefulBuilder(
          builder: (context, setModalState) {
            final String currentDisplayNum = formatDisplayNumber(phoneNumber);
            
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              shadowColor: AppColors.ruby.withValues(alpha: 0.15),
              elevation: 8,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.sakura.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phonelink_setup_rounded, color: AppColors.ruby, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Parear WhatsApp',
                    style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ruby, fontSize: 18),
                  ),
                ],
              ),
              content: FutureBuilder<String?>(
                future: evolutionService.fetchPairingCode(uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox(
                      height: 240,
                      width: 300,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: AppColors.ruby, strokeWidth: 3),
                            const SizedBox(height: 24),
                            const Text(
                              'Gerando código...',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain, fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Solicitando ao WhatsApp para:\n$currentDisplayNum',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError || snapshot.data == null) {
                    return SizedBox(
                      height: 240,
                      width: 300,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.ruby, size: 48),
                            const SizedBox(height: 16),
                            const Text(
                              'Falha ao obter código',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain, fontSize: 15),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Verifique sua conexão com a rede e tente novamente.',
                              style: TextStyle(color: AppColors.textLight, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                setModalState(() {});
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Tentar Novamente', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.ruby,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  }

                  final pairingCode = snapshot.data!;

                  // Inicia polling automático assim que o código é exibido
                  if (pollingTimer == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!dialogCtx.mounted) return;
                      pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
                        try {
                          final connected = await evolutionService.checkConnectionStatus();
                          if (connected) {
                            timer.cancel();
                            pollingTimer = null;
                            if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                            if (context.mounted) {
                              setState(() => _localWhatsappConnected = true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('WhatsApp conectado com sucesso!'),
                                  backgroundColor: AppColors.primary,
                                  duration: Duration(seconds: 4),
                                ),
                              );
                            }
                          }
                        } catch (_) {
                          // falha silenciosa: app em background, Android cancelou a conexão TCP
                        }
                      });
                    });
                  }

                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          '1. Verifique o número de pareamento:',
                          style: TextStyle(fontSize: 12, color: AppColors.textMain, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.phone_iphone_rounded, color: AppColors.textLight, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  currentDisplayNum,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textMain,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        const Text(
                          '2. Copie o código de 8 dígitos abaixo:',
                          style: TextStyle(fontSize: 12, color: AppColors.textMain, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.sakura.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.sakura.withValues(alpha: 0.6), width: 2),
                          ),
                          child: Text(
                            pairingCode,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: AppColors.ruby,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '3. Abra o WhatsApp > Aparelhos Conectados > Conectar com número de telefone > digite o código acima.',
                          style: TextStyle(fontSize: 11, color: AppColors.textLight, height: 1.4),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: pairingCode));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Código copiado!'),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                label: const Text('Copiar'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.ruby,
                                  side: const BorderSide(color: AppColors.ruby),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  Clipboard.setData(ClipboardData(text: pairingCode));
                                  final Uri whatsappUri = Uri.parse("whatsapp://");
                                  try {
                                    if (await canLaunchUrl(whatsappUri)) {
                                      await launchUrl(whatsappUri);
                                    } else {
                                      await launchUrl(Uri.parse("https://wa.me"));
                                    }
                                  } catch (e) {
                                    await launchUrl(Uri.parse("https://wa.me"));
                                  }
                                },
                                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                                label: const Text('Vincular'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.ruby,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              actions: [
                // A conexão é detectada automaticamente pelo polling — sem confirmação manual
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Fechar', style: TextStyle(color: AppColors.rose, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      pollingTimer?.cancel();
      pollingTimer = null;
    });
  }

  // Constrói o banner de aviso no topo do dashboard caso o WhatsApp esteja desconectado
  Widget _buildWarningBanner(BuildContext context, String uid, String phoneNumber) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.ruby.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ruby.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.ruby, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'WhatsApp Não Vinculado!',
                  style: TextStyle(
                    color: AppColors.textMain.withValues(alpha: 0.9),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Para que o botão de pânico envie alertas automáticos e silenciosos à sua rede de apoio, vincule seu WhatsApp agora.',
            style: TextStyle(color: AppColors.rose, fontSize: 12, height: 1.3),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showPairingCodeDialog(context, uid, phoneNumber),
              icon: const Icon(Icons.link_rounded, size: 18),
              label: const Text('Vincular Agora', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ruby,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sosNotifier = context.watch<SOSNotifier>();
    final user = sosNotifier.authRepository.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Usuária não logada")));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _userDocStreamFor(user.uid),
      builder: (context, snapshot) {
        bool isConnected = _localWhatsappConnected;
        String phoneNumber = '';
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          isConnected = _localWhatsappConnected || (data?['whatsappConnected'] ?? false);
          phoneNumber = data?['phoneNumber'] ?? '';
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('VOZ SEGURA'),
            actions: [
              IconButton(
                icon: const Icon(Icons.visibility_off_outlined),
                tooltip: 'Modo Camuflagem',
                onPressed: () {
                  final camNotifier = context.read<CamouflageNotifier>();
                  if (camNotifier.showExplanation) {
                    showDialog(
                      context: context,
                      builder: (context) => const CamouflageDialog(),
                    );
                  } else {
                    camNotifier.setCamouflaged(true);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Sair',
                onPressed: () => sosNotifier.logout(),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Stack(
            children: [
              // Elementos de fundo decorativos com blur
              Positioned(
                top: -50,
                right: -50,
                child: _buildBlurCircle(AppColors.rose.withValues(alpha: 0.4), 200),
              ),
              Positioned(
                bottom: 100,
                left: -100,
                child: _buildBlurCircle(AppColors.lilac.withValues(alpha: 0.5), 300),
              ),
              
              // Conteúdo Dinâmico
              Column(
                children: [
                  if (!isConnected)
                    _buildWarningBanner(context, user.uid, phoneNumber),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        // Padding inferior maior para o conteúdo (ex.: botão "Estou
                        // Segura") não ficar sob o menu flutuante de navegação.
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 130),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Cabeçalho Animado
                            TweenAnimationBuilder(
                              duration: const Duration(seconds: 1),
                              tween: Tween<double>(begin: 0, end: 1),
                              builder: (context, double val, child) {
                                return Opacity(
                                  opacity: val,
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - val)),
                                    child: child,
                                  ),
                                );
                              },
                              child: const Column(
                                children: [
                                  Text(
                                    'SENTE-SE SEGURA?',
                                    style: AppStyles.h1,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Em caso de perigo, mantenha o botão\npressionado para alertar sua rede.',
                                    textAlign: TextAlign.center,
                                    style: AppStyles.subtitle,
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 40),
                            
                            // Botão Central de SOS
                            const SecureSOSButton(),
                            
                            const SizedBox(height: 40),
                            
                            // Badge de feedback de SOS ativo
                            if (sosNotifier.isSOSActive)
                              _buildActiveSOSBadge(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBlurCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildActiveSOSBadge() {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.05).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.ruby,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.ruby.withValues(alpha: 0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_active_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'ALERTAS ATIVOS',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}
