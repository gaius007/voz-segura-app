import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../manager/report_notifier.dart';
import '../widgets/report_card.dart';
import 'package:voz_segura_app/src/core/security/local_auth_service.dart';
import 'package:voz_segura_app/src/core/theme/app_theme.dart';
import 'package:voz_segura_app/src/core/widgets/confirm_dialog.dart';

class ReportListPage extends StatefulWidget {
  const ReportListPage({super.key});

  @override
  State<ReportListPage> createState() => _ReportListPageState();
}

class _ReportListPageState extends State<ReportListPage> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportNotifier>().carregarRelatos();
    });
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final notifier = context.read<ReportNotifier>();
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      notifier.carregarMaisRelatos();
    }
  }

  /// Confirma e executa a exclusão. Retorna `true` somente se o relato foi
  /// realmente excluído (para o Dismissible removê-lo da lista). Caso a regra
  /// de 10 minutos/autoria barre a exclusão no repositório, exibe um SnackBar
  /// e mantém o item na lista.
  Future<bool> _confirmarExclusaoRelato(BuildContext context, String reportId) async {
    final confirmado = await showConfirmDialog(
      context,
      title: 'Excluir Relato Seguro',
      message:
          'Você tem certeza de que deseja excluir permanentemente este relato? Essa ação não poderá ser desfeita.',
    );
    if (!confirmado) return false;
    if (!context.mounted) return false;

    // Autenticação local (biometria/PIN) antes de ação sensível
    final authenticated = await context
        .read<LocalAuthService>()
        .authenticate('Confirme sua identidade para excluir o relato');
    if (!authenticated || !context.mounted) return false;

    try {
      await context.read<ReportNotifier>().excluirRelato(reportId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Relato excluído com sucesso!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      // A lista já é recarregada pelo notifier; não deixamos o Dismissible
      // animar a remoção para evitar conflito de índices.
      return false;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.ruby,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Relatos Seguros'),
      ),
      // Consumer restrito ao corpo: o AppBar/Scaffold não reconstroem quando o
      // ReportNotifier notifica (somente a lista é reconstruída).
      body: Consumer<ReportNotifier>(
        builder: (context, notifier, _) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: notifier.isLoading
              ? const Center(child: CircularProgressIndicator()) 
              : RefreshIndicator(
                  onRefresh: () => notifier.carregarRelatos(),
                  color: context.appPrimary,
                  child: notifier.reports.isEmpty
                      ? _buildVazio()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                          itemCount: notifier.reports.length + (notifier.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == notifier.reports.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(context.appPrimary),
                                  ),
                                ),
                              );
                            }

                            final report = notifier.reports[index];
                            final card = TweenAnimationBuilder(
                              duration: Duration(milliseconds: 300 + (index < 5 ? index * 100 : 0)),
                              curve: Curves.easeOutCubic,
                              tween: Tween<double>(begin: 0, end: 1),
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 30 * (1 - value)),
                                    child: ReportCard(report: report),
                                  ),
                                );
                              },
                            );

                            // Swipe-to-delete apenas nos relatos da própria usuária.
                            final currentUid = FirebaseAuth.instance.currentUser?.uid;
                            if (report.authorUid == null || report.authorUid != currentUid) {
                              return card;
                            }

                            return Dismissible(
                              key: ValueKey(report.id),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) => _confirmarExclusaoRelato(context, report.id),
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 20),
                                padding: const EdgeInsets.only(right: 28),
                                alignment: Alignment.centerRight,
                                decoration: BoxDecoration(
                                  color: context.appRuby,
                                  borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                                ),
                                child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
                              ),
                              child: card,
                            );
                          },
                        ),
                ),
        ),
        ),
      ),
    );
  }

  Widget _buildVazio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories_rounded, size: 80, color: context.appRose.withOpacity(0.4)),
          const SizedBox(height: 20),
          const Text(
            'Seu histórico está limpo.',
            style: AppStyles.subtitle,
          ),
        ],
      ),
    );
  }
}
