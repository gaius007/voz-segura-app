import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voz_segura_app/src/features/auth/domain/auth_repository.dart';
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

  Future<void> _abrirGaleria() async {
    final List<XFile> images = await _picker.pickMultiImage(
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );
    if (images.isNotEmpty) {
      setState(() {
        _fotosLocais.addAll(images.map((x) => x.path));
      });
    }
  }

  void _removerFoto(int index) {
    setState(() {
      _fotosLocais.removeAt(index);
    });
  }

  Future<void> _escolherFonteDaImagem() async {
    if (_enviando) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: context.appCardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(Icons.camera_enhance_rounded, color: context.appPrimary),
                title: const Text('Tirar foto agora'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _abrirCamera();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library_rounded, color: context.appPrimary),
                title: const Text('Escolher da galeria'),
                subtitle: const Text('Você pode selecionar várias fotos'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _abrirGaleria();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
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
                backgroundColor: context.appCardColor,
                title: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: context.appRuby),
                    const SizedBox(width: 8),
                    Text(
                      'Informação Importante',
                      style: TextStyle(
                        color: context.appRuby, 
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
                    Text(
                      'Você poderá editar ou excluir este relato nos próximos 10 minutos. Após esse período, essas ações serão bloqueadas para preservar a integridade das informações e possíveis provas relacionadas ao relato.',
                      style: TextStyle(color: context.appTextMain, fontSize: 14, height: 1.4),
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
                            activeColor: context.appPrimary,
                            onChanged: (val) {
                              setDialogState(() {
                                naoMostrarNovamente = val ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: Text(
                              'Não mostrar este aviso novamente',
                              style: TextStyle(color: context.appTextMain, fontSize: 13),
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
                      backgroundColor: context.appPrimary,
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
      backgroundColor: context.appScaffoldBg,
      appBar: AppBar(
        title: const Text('Novo Relato'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: context.appBackgroundGradient,
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
                  Text(
                    'DETALHES DO RELATO',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.appRuby, letterSpacing: 1.5),
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
                  Text(
                    'EVIDÊNCIAS VISUAIS',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.appRuby, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _enviando ? null : _escolherFonteDaImagem,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: context.appGlassColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.appGlassBorder, width: 1.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_rounded, size: 36, color: context.appPrimary),
                          const SizedBox(height: 8),
                          Text(
                            'ADICIONAR EVIDÊNCIAS',
                            style: TextStyle(color: context.appPrimary, fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Câmera ou galeria',
                            style: TextStyle(color: context.appTextLight, fontSize: 11),
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
                            child: Stack(
                              children: [
                                Hero(
                                  tag: 'new-photo-$index',
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: context.appSoftShadow,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: kIsWeb
                                          ? Image.network(path, width: 120, height: 120, fit: BoxFit.cover, cacheWidth: 240, cacheHeight: 240)
                                          : Image.file(io.File(path), width: 120, height: 120, fit: BoxFit.cover, cacheWidth: 240, cacheHeight: 240),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: GestureDetector(
                                    onTap: _enviando ? null : () => _removerFoto(index),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 40),
                  Text(
                    'VISIBILIDADE DO RELATO',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.appRuby, letterSpacing: 1.5),
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
                            ? context.appSakura.withOpacity(0.5) 
                            : context.appLilac.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _selectedVisibility == ReportVisibility.public 
                              ? context.appPrimary.withOpacity(0.3) 
                              : context.appRose.withOpacity(0.3)
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
                                color: context.appRuby,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedVisibility == ReportVisibility.public 
                                    ? 'Atenção ao Compartilhar' 
                                    : 'Registro Pessoal Seguro',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: context.appRuby,
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
                            style: TextStyle(
                              fontSize: 12,
                              color: context.appTextMain,
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
                      ? CircularProgressIndicator(color: context.appPrimary)
                      : ElevatedButton(
                          onPressed: _salvarNoFirebase,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 65),
                            backgroundColor: context.appPrimary,
                            elevation: 10,
                            shadowColor: context.appPrimary.withOpacity(0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text(
                            'ENVIAR RELATO SEGURO',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white),
                          ),
                        ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    'Suas informações são criptografadas e protegidas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: context.appTextLight, fontStyle: FontStyle.italic),
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
              ? context.appSakura.withOpacity(0.8) 
              : context.appGlassColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? context.appPrimary 
                : context.appRose.withOpacity(0.3),
            width: isSelected ? 2.0 : 1.5,
          ),
          boxShadow: isSelected ? context.appSoftShadow : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? context.appPrimary : context.appRose,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected ? context.appRuby : context.appTextMain,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: context.appTextLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
