import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/report.dart';

// Tela que mostra todos os detalhes de um relato especifico
class ReportDetailPage extends StatelessWidget {
  final Report report;

  const ReportDetailPage({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    // Formatei a data pra ficar facil de ler
    final dataLegal = DateFormat('dd/MM/yyyy HH:mm').format(report.createdAt);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Detalhes do Relato'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.pink.shade50, Colors.white],
          ),
        ),
        child: Center( // Responsivo: centraliza no meio se a tela for grande
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 120, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card principal com efeito de desfoque (Glass)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 18, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(dataLegal, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'O que foi relatado:',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFF4081)),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              report.description,
                              style: const TextStyle(fontSize: 17, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Fotos enviadas como prova:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Se tiver fotos, a gente mostra em grade
                  if (report.photoUrls.isEmpty)
                    const Text('Esse relato nao tem fotos.')
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: report.photoUrls.length,
                      itemBuilder: (context, index) {
                        return Hero(
                          tag: index == 0 ? 'report-${report.id}' : 'photo-$index',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            // Carregando do Firebase Storage com Image.network
                            child: Image.network(
                              report.photoUrls[index],
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  color: Colors.pink.shade50,
                                  child: const Center(child: CircularProgressIndicator()),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 40),
                  
                  // Container pro Hash de seguranca
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade900,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('HASH DE INTEGRIDADE:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          report.contentHash,
                          style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 13),
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
