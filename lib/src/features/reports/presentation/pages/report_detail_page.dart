import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/report.dart';
import 'package:voz_segura_app/src/core/theme/app_theme.dart';
import 'package:voz_segura_app/src/features/auth/domain/auth_repository.dart';
import '../manager/report_notifier.dart';

class ReportDetailPage extends StatefulWidget {
  final Report report;

  const ReportDetailPage({super.key, required this.report});

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  Timer? _countdownTimer;
  // Cache de instâncias de imagens para evitar que as fotos pisquem a cada segundo durante os ticks do timer
  final Map<String, Widget> _imageWidgetCache = {};

  @override
  void initState() {
    super.initState();
    // Ticker a cada 1 segundo para atualizar o contador regressivo de 10 minutos na interface
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _imageWidgetCache.clear();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '00:00';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _mostrarImagem(String path) {
    if (_imageWidgetCache.containsKey(path)) {
      return _imageWidgetCache[path]!;
    }

    Widget imageWidget;
    if (path.startsWith('data:image')) {
      try {
        final base64String = path.split(',').last;
        final decodedBytes = base64Url.decode(base64String);
        imageWidget = Image.memory(
          decodedBytes,
          fit: BoxFit.cover,
        );
      } catch (e) {
        imageWidget = Center(child: Icon(Icons.broken_image_rounded, color: context.appRose));
      }
    } else {
      imageWidget = Image.network(
        path,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: context.appSakura,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: context.appPrimary)),
          );
        },
      );
    }

    _imageWidgetCache[path] = imageWidget;
    return imageWidget;
  }

  void _mostrarDialogoEdicao(BuildContext context, Report currentReport) {
    final formKey = GlobalKey<FormState>();
    final descController = TextEditingController(text: currentReport.description);
    ReportVisibility tempVisibility = currentReport.visibility;
    bool salvando = false;

    showDialog(
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
                  Icon(Icons.edit_note_rounded, color: context.appRuby),
                  const SizedBox(width: 8),
                  Text(
                    'Editar Relato Seguro',
                    style: TextStyle(
                      color: context.appRuby,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DESCRIÇÃO DO RELATO',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.appRuby, letterSpacing: 1),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: descController,
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'A descrição não pode ser vazia.';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          hintText: 'Descreva os detalhes do acontecimento...',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'VISIBILIDADE',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.appRuby, letterSpacing: 1),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setDialogState(() {
                                  tempVisibility = ReportVisibility.public;
                                });
                              },
                              borderRadius: BorderRadius.circular(15),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: tempVisibility == ReportVisibility.public
                                      ? context.appSakura
                                      : context.appCardColor,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: tempVisibility == ReportVisibility.public
                                        ? context.appPrimary
                                        : context.appDivider,
                                    width: tempVisibility == ReportVisibility.public ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.public_rounded,
                                      color: tempVisibility == ReportVisibility.public
                                          ? context.appPrimary
                                          : Colors.grey,
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'PÚBLICO',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setDialogState(() {
                                  tempVisibility = ReportVisibility.private;
                                });
                              },
                              borderRadius: BorderRadius.circular(15),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: tempVisibility == ReportVisibility.private
                                      ? context.appSakura
                                      : context.appCardColor,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: tempVisibility == ReportVisibility.private
                                        ? context.appPrimary
                                        : context.appDivider,
                                    width: tempVisibility == ReportVisibility.private ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.lock_rounded,
                                      color: tempVisibility == ReportVisibility.private
                                          ? context.appPrimary
                                          : Colors.grey,
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'PRIVADO',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: salvando ? null : () => Navigator.pop(context),
                  child: Text('Cancelar', style: TextStyle(color: context.appTextLight)),
                ),
                salvando
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: context.appPrimary),
                      )
                    : ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() {
                            salvando = true;
                          });

                          try {
                            await context.read<ReportNotifier>().editarRelato(
                                  currentReport.id,
                                  descController.text,
                                  tempVisibility,
                                );
                            if (context.mounted) {
                              Navigator.pop(context); // fecha diálogo
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Relato atualizado com sucesso!'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erro ao atualizar: $e'),
                                  backgroundColor: context.appRuby,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } finally {
                            setDialogState(() {
                              salvando = false;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.appPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text('Salvar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
              ],
            );
          },
        );
      },
    );
  }

  void _mostrarConfirmacaoExclusao(BuildContext context, Report currentReport) {
    bool excluindo = false;

    showDialog(
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
                  Icon(Icons.warning_amber_rounded, color: context.appRuby),
                  const SizedBox(width: 8),
                  Text(
                    'Excluir Relato Seguro',
                    style: TextStyle(
                      color: context.appRuby,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: Text(
                'Você tem certeza de que deseja excluir permanentemente este relato? Essa ação preserva a integridade dos registros e não poderá ser desfeita.',
                style: TextStyle(color: context.appTextMain, fontSize: 14, height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: excluindo ? null : () => Navigator.pop(context),
                  child: Text('Cancelar', style: TextStyle(color: context.appTextLight)),
                ),
                excluindo
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: context.appPrimary),
                      )
                    : ElevatedButton(
                        onPressed: () async {
                          setDialogState(() {
                            excluindo = true;
                          });

                          try {
                            await context.read<ReportNotifier>().excluirRelato(currentReport.id);
                            if (context.mounted) {
                              Navigator.pop(context); // fecha diálogo
                              Navigator.pop(context); // volta para a listagem
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Relato excluído com sucesso!'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erro ao excluir: $e'),
                                  backgroundColor: context.appRuby,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } finally {
                            setDialogState(() {
                              excluindo = false;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.appRuby,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text('Excluir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Escuta de forma reativa a lista de relatos do Notifier para atualizar caso sofra edições externas
    final currentReport = context.watch<ReportNotifier>().reports.firstWhere(
          (r) => r.id == widget.report.id,
          orElse: () => widget.report,
        );

    // Limpa chaves obsoletas do cache de imagens se elas mudarem após edições
    _imageWidgetCache.removeWhere((key, _) => !currentReport.photoUrls.contains(key));

    final authRepo = context.read<AuthRepository>();
    final currentUser = authRepo.currentUser;

    final dataLegal = DateFormat('dd MMMM yyyy • HH:mm').format(currentReport.createdAt);
    
    // Cálculo do tempo decorrido e elegibilidade de edição/deleção
    final timePassed = DateTime.now().difference(currentReport.createdAt);
    final remainingSeconds = 600 - timePassed.inSeconds;
    final isAuthor = currentReport.authorUid == currentUser?.uid;
    final canEditOrDelete = isAuthor && remainingSeconds > 0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: context.appScaffoldBg,
      appBar: AppBar(
        title: const Text('Detalhes do Relato'),
        actions: canEditOrDelete
            ? [
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: context.appRuby),
                  onPressed: () => _mostrarDialogoEdicao(context, currentReport),
                  tooltip: 'Editar relato',
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: context.appRuby),
                  onPressed: () => _mostrarConfirmacaoExclusao(context, currentReport),
                  tooltip: 'Excluir relato',
                ),
                const SizedBox(width: 8),
              ]
            : null,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: context.appBackgroundGradient,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 120, 24, 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Alerta Temporal de Integridade (Apenas visível se for a autora do relato)
                  if (isAuthor) ...[
                    if (remainingSeconds > 0)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.appBlush.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: context.appRose.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.timer_outlined, color: context.appRuby),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Edição e Exclusão Disponíveis',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: context.appRuby,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Você pode alterar ou remover este relato nos próximos ${_formatDuration(remainingSeconds)}.',
                                    style: TextStyle(
                                      color: context.appTextMain,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.appCardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: context.appDivider),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock_outline_rounded, color: context.appTextLight),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Registro Imutável Ativado',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: context.appTextMain,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'O prazo de 10 minutos expirou. Este relato foi permanentemente selado no sistema para garantir a integridade de evidências.',
                                    style: TextStyle(
                                      color: context.appTextLight,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],

                  // Description Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: context.appGlassColor,
                      borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                      boxShadow: context.appSoftShadow,
                      border: Border.all(color: context.appGlassBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_month_rounded, size: 16, color: context.appTextLight),
                                const SizedBox(width: 8),
                                Text(dataLegal.toUpperCase(), style: TextStyle(color: context.appTextLight, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: currentReport.visibility == ReportVisibility.public
                                    ? const Color(0xFFE3F2FD)
                                    : const Color(0xFFECEFF1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    currentReport.visibility == ReportVisibility.public
                                        ? Icons.public_rounded
                                        : Icons.lock_rounded,
                                    size: 14,
                                    color: currentReport.visibility == ReportVisibility.public
                                        ? Colors.blue.shade700
                                        : Colors.blueGrey.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    currentReport.visibility == ReportVisibility.public
                                        ? "PÚBLICO"
                                        : "PRIVADO",
                                    style: TextStyle(
                                      color: currentReport.visibility == ReportVisibility.public
                                          ? Colors.blue.shade700
                                          : Colors.blueGrey.shade700,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (currentReport.visibility == ReportVisibility.public) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.person_outline_rounded, size: 16, color: context.appRuby),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Autora: ${currentReport.authorName ?? "Usuária Voz Segura"}',
                                  style: TextStyle(
                                    color: context.appRuby,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),
                        Text(
                          'ACONTECIMENTO RELATADO',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: context.appRuby, letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          currentReport.description,
                          style: TextStyle(fontSize: 17, height: 1.6, color: context.appTextMain, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  
                  // Botões Funcionais de Edição e Exclusão (Apenas visíveis para a autora do relato)
                  if (isAuthor) ...[
                    const SizedBox(height: 24),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 500),
                      opacity: remainingSeconds > 0 ? 1.0 : 0.6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.edit_rounded, color: Colors.white),
                                  label: const Text('Editar Relato'),
                                  onPressed: remainingSeconds > 0
                                      ? () => _mostrarDialogoEdicao(context, currentReport)
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: context.appPrimary,
                                    disabledBackgroundColor: context.appPrimary.withOpacity(0.3),
                                    disabledForegroundColor: Colors.white70,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: remainingSeconds > 0 ? 2 : 0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    color: remainingSeconds > 0 ? context.appRuby : context.appRuby.withOpacity(0.4),
                                  ),
                                  label: Text(
                                    'Excluir Relato',
                                    style: TextStyle(
                                      color: remainingSeconds > 0 ? context.appRuby : context.appRuby.withOpacity(0.4),
                                    ),
                                  ),
                                  onPressed: remainingSeconds > 0
                                      ? () => _mostrarConfirmacaoExclusao(context, currentReport)
                                      : null,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: remainingSeconds > 0 ? context.appRuby : context.appRuby.withOpacity(0.3),
                                      width: 2,
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (remainingSeconds <= 0) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: context.appCardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.appDivider),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, size: 16, color: context.appTextLight),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'O prazo para edição ou exclusão deste relato expirou para preservar a integridade das informações.',
                                      style: TextStyle(
                                        color: context.appTextLight,
                                        fontSize: 12,
                                        height: 1.4,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                  
                  Text(
                    'EVIDÊNCIAS COLETADAS',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: context.appRuby, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 16),
                  
                  if (currentReport.photoUrls.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: context.appSakura.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.appRose.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: context.appRose),
                          const SizedBox(width: 12),
                          Text('Nenhuma imagem anexada a este relato.', style: TextStyle(color: context.appTextLight)),
                        ],
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1,
                      ),
                      itemCount: currentReport.photoUrls.length,
                      itemBuilder: (context, index) {
                        return Hero(
                          tag: index == 0 ? 'report-${currentReport.id}' : 'photo-$index',
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: context.appSoftShadow,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: _mostrarImagem(currentReport.photoUrls[index]),
                            ),
                          ),
                        );
                      },
                    ),
                  
                  const SizedBox(height: 48),
                  
                  // Integrity Hash Footer
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.verified_user_rounded, color: Colors.greenAccent, size: 16),
                            SizedBox(width: 8),
                            Text('INTEGRIDADE GARANTIDA', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Este relato possui um hash de segurança imutável para fins legais:',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          currentReport.contentHash,
                          style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
