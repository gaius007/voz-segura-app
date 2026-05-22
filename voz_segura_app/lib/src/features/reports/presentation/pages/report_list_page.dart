import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../manager/report_notifier.dart';
import '../widgets/report_card.dart';
import 'package:voz_segura_app/src/core/theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ReportNotifier>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Relatos Seguros'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: notifier.isLoading
              ? const Center(child: CircularProgressIndicator()) 
              : RefreshIndicator(
                  onRefresh: () => notifier.carregarRelatos(),
                  color: AppColors.primary,
                  child: notifier.reports.isEmpty
                      ? _buildVazio()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                          itemCount: notifier.reports.length + (notifier.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == notifier.reports.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                  ),
                                ),
                              );
                            }

                            final report = notifier.reports[index];
                            return TweenAnimationBuilder(
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
                          },
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
          Icon(Icons.auto_stories_rounded, size: 80, color: AppColors.rose.withOpacity(0.4)),
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
