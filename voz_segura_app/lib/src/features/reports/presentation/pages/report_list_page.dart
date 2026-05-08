import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../manager/report_notifier.dart';
import '../widgets/report_card.dart';

// Tela de Relatos simplificada (tirei o FAB daqui pq ele foi pra Main)
class ReportListPage extends StatefulWidget {
  const ReportListPage({super.key});

  @override
  State<ReportListPage> createState() => _ReportListPageState();
}

class _ReportListPageState extends State<ReportListPage> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportNotifier>().carregarRelatos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ReportNotifier>();

    return Scaffold(
      // Removi o AppBar daqui tb pq agora a Main cuida melhor disso ou a gente deixa limpo
      appBar: AppBar(
        title: const Text('Relatos Seguros'),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.pink.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: notifier.isLoading
                ? const Center(child: CircularProgressIndicator()) 
                : RefreshIndicator(
                    onRefresh: () => notifier.carregarRelatos(),
                    child: notifier.reports.isEmpty
                        ? _buildVazio()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // padding no fundo pro botao nao tampar o ultimo
                            itemCount: notifier.reports.length,
                            itemBuilder: (context, index) {
                              final report = notifier.reports[index];
                              return TweenAnimationBuilder(
                                duration: Duration(milliseconds: 400 + (index * 100)),
                                tween: Tween<double>(begin: 0, end: 1),
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, 20 * (1 - value)),
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
      ),
      // O FAB saiu daqui e foi pra MainNavigationPage!
    );
  }

  Widget _buildVazio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 80, color: Colors.pink.shade100),
          const SizedBox(height: 16),
          const Text(
            'Nenhum relato na nuvem.',
            style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
