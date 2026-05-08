import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../manager/report_notifier.dart';
import '../widgets/report_card.dart';
import 'report_create_page.dart';

// Essa tela mostra todos os relatos que estao no Firestore
// Tentei deixar bem moderno com gradiente e animacoes
class ReportListPage extends StatefulWidget {
  const ReportListPage({super.key});

  @override
  State<ReportListPage> createState() => _ReportListPageState();
}

class _ReportListPageState extends State<ReportListPage> {
  
  @override
  void initState() {
    super.initState();
    // Assim que a tela carrega, a gente busca os dados da nuvem
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportNotifier>().carregarRelatos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ReportNotifier>();

    return Scaffold(
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
        child: Center( // Centralizei pra ficar bom em qualquer tamanho de tela
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700), // Nao deixa passar de 700px
            child: notifier.isLoading
                ? const Center(child: CircularProgressIndicator()) 
                : RefreshIndicator(
                    // Se puxar pra baixo, atualiza a lista do Firebase
                    onRefresh: () => notifier.carregarRelatos(),
                    child: notifier.reports.isEmpty
                        ? _buildVazio()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: notifier.reports.length,
                            itemBuilder: (context, index) {
                              final report = notifier.reports[index];
                              
                              // Animacaozinha de entrada pros cards subirem
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80), 
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReportCreatePage()),
            );
          },
          backgroundColor: const Color(0xFFFF4081),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_photo_alternate_rounded),
          label: const Text('Novo Relato'),
        ),
      ),
    );
  }

  // Widget pra quando nao tem nada no banco
  Widget _buildVazio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 80, color: Colors.pink.shade100),
          const SizedBox(height: 16),
          const Text(
            'Nenhum relato na nuvem ainda.',
            style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
