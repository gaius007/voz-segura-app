import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voz_segura_app/src/features/auth/data/auth_repository.dart';
import '../manager/report_notifier.dart';
import 'dart:io' as io;
import 'package:voz_segura_app/src/core/theme/app_theme.dart';
import '../../domain/entities/report.dart';

class ReportCreatePage extends StatefulWidget {
  const ReportCreatePage({super.key});

  @override
  State<ReportCreatePage> createState() => _ReportCreatePageState();
}

class _ReportCreatePageState extends State<ReportCreatePage> {
  final TextEditingController _descController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<String> _fotosLocais = [];
  final ImagePicker _picker = ImagePicker();
  bool _enviando = false;
  ReportVisibility? _selectedVisibility;

  @override
  void dispose() {
    _descController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _abrirCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() {
        _fotosLocais.add(image.path);
      });
    }
  }

  Future<void> _mostrarAviso10Minutos() async {
    final prefs = await SharedPreferences.getInstance();
    final mostrarAviso = prefs.getBool('show_report_creation_warning') ?? true;

    if (!mostrarAviso) {
      if (mounted) Navigator.pop(context);
      return;
    }

    bool naoMostrarNovamente = false;

    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                backgroundColor: Colors.white,
                title: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.ruby),
                    SizedBox(width: 8),
                    Text(
                      'Informação Importante',
                      style: TextStyle(
                        color: AppColors.ruby, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 18
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Você poderá editar ou excluir este relato nos próximos 10 minutos. Após esse período, essas ações serão bloqueadas para preservar a integridade das informações e possíveis provas relacionadas ao relato.',
                      style: TextStyle(color: AppColors.textMain, fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    InkWell(
                      onTap: () {
                        setDialogState(() {
                          naoMostrarNovamente = !naoMostrarNovamente;
                        });
                      },
                      child: Row(
                        children: [
                          Checkbox(
                            value: naoMostrarNovamente,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              setDialogState(() {
                                naoMostrarNovamente = val ?? false;
                              });
                            },
                          ),
                          const Expanded(
                            child: Text(
                              'Não mostrar este aviso novamente',
                              style: TextStyle(color: AppColors.textMain, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () async {
                      if (naoMostrarNovamente) {
                        await prefs.setBool('show_report_creation_warning', false);
                      }
                      if (context.mounted) {
                        Navigator.pop(context); // fecha o diálogo
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Entendido', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          );
        },
      );
      if (mounted) {
        Navigator.pop(context); // fecha a tela
      }
    }
  }

  Future<void> _salvarNoFirebase() async {
    final texto = _descController.text;
    if (texto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, descreva o acontecimento.')),
      );
      return;
    }

    if (_selectedVisibility == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione a visibilidade antes de salvar.'),
          backgroundColor: AppColors.ruby,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedVisibility == ReportVisibility.public) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.ruby),
              SizedBox(width: 8),
              Text('Publicar Relato', style: TextStyle(color: AppColors.ruby, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: const Text(
            'Seu relato será publicado na comunidade e poderá ser visualizado por outras pessoas. Deseja prosseguir?',
            style: TextStyle(color: AppColors.textMain, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.textLight)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('Publicar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
    }

    setState(() => _enviando = true);
    try {
      final authRepo = context.read<AuthRepository>();
      // Recarrega os dados do usuario para atualizar o cache local do Firebase Auth (displayName)
      await authRepo.reload();
      final currentUser = authRepo.currentUser;

      await context.read<ReportNotifier>().adicionarRelato(
        texto, 
        _fotosLocais, 
        _selectedVisibility!,
        authorName: currentUser?.displayName,
        authorUid: currentUser?.uid,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Relato seguro enviado com sucesso!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _mostrarAviso10Minutos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: AppColors.ruby),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Novo Relato'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.sakura, Colors.white],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'DETALHES DO RELATO',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.ruby, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descController,
                    maxLines: 8,
                    enabled: !_enviando,
                    decoration: const InputDecoration(
                      hintText: 'Descreva aqui o que aconteceu com o máximo de detalhes possível para sua segurança...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'EVIDÊNCIAS VISUAIS',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.ruby, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _enviando ? null : _abrirCamera,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.rose.withOpacity(0.5), width: 1.5),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_enhance_rounded, size: 36, color: AppColors.primary),
                          SizedBox(height: 8),
                          Text(
                            'CAPTURAR EVIDÊNCIA',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_fotosLocais.isNotEmpty)
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _fotosLocais.length,
                        itemBuilder: (context, index) {
                          final path = _fotosLocais[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Hero(
                              tag: 'new-photo-$index',
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: AppStyles.softShadow,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: kIsWeb 
                                    ? Image.network(path, width: 120, height: 120, fit: BoxFit.cover)
                                    : Image.file(io.File(path), width: 120, height: 120, fit: BoxFit.cover),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 40),
                  const Text(
                    'VISIBILIDADE DO RELATO',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.ruby, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildVisibilityCard(
                          visibility: ReportVisibility.public,
                          title: 'PÚBLICO',
                          description: 'Comunidade',
                          icon: Icons.public_rounded,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildVisibilityCard(
                          visibility: ReportVisibility.private,
                          title: 'PRIVADO',
                          description: 'Apenas você',
                          icon: Icons.lock_rounded,
                        ),
                      ),
                    ],
                  ),
                  if (_selectedVisibility != null) ...[
                    const SizedBox(height: 16),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _selectedVisibility == ReportVisibility.public 
                            ? AppColors.sakura.withOpacity(0.5) 
                            : AppColors.lilac.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _selectedVisibility == ReportVisibility.public 
                              ? AppColors.primary.withOpacity(0.3) 
                              : AppColors.rose.withOpacity(0.3)
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _selectedVisibility == ReportVisibility.public 
                                    ? Icons.info_outline_rounded 
                                    : Icons.security_rounded,
                                color: AppColors.ruby,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedVisibility == ReportVisibility.public 
                                    ? 'Atenção ao Compartilhar' 
                                    : 'Registro Pessoal Seguro',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.ruby,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedVisibility == ReportVisibility.public
                                ? 'Seu relato será publicado na comunidade e poderá ser visualizado por outras pessoas. Caso tenha habilitado compartilhamento de localização, ela poderá ser exibida.'
                                : 'Seu relato ficará salvo apenas para você, como um registro pessoal. Ele não aparecerá em feeds, comunidades ou buscas públicas.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMain,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                  if (_selectedVisibility != null) ...[
                    const SizedBox(height: 40),
                    _enviando 
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _salvarNoFirebase,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 65),
                            backgroundColor: AppColors.primary,
                            elevation: 10,
                            shadowColor: AppColors.primary.withOpacity(0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text(
                            'ENVIAR RELATO SEGURO',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white),
                          ),
                        ),
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    'Suas informações são criptografadas e protegidas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.textLight, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisibilityCard({
    required ReportVisibility visibility,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedVisibility == visibility;
    return InkWell(
      onTap: _enviando
          ? null
          : () {
              setState(() {
                _selectedVisibility = visibility;
              });

              // Scroll automático dinâmico suave após a seleção de visibilidade
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOutCubic,
                  );
                }
              });
            },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.sakura.withOpacity(0.8) 
              : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? AppColors.primary 
                : AppColors.rose.withOpacity(0.3),
            width: isSelected ? 2.0 : 1.5,
          ),
          boxShadow: isSelected ? AppStyles.softShadow : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppColors.primary : AppColors.rose,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected ? AppColors.ruby : AppColors.textMain,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
