import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/report.dart';
import 'package:voz_segura_app/src/core/theme/app_theme.dart';

class ReportDetailPage extends StatelessWidget {
  final Report report;

  const ReportDetailPage({super.key, required this.report});

  Widget _mostrarImagem(String path) {
    if (path.startsWith('data:image')) {
      try {
        final base64String = path.split(',').last;
        return Image.memory(
          base64Url.decode(base64String),
          fit: BoxFit.cover,
        );
      } catch (e) {
        return const Center(child: Icon(Icons.broken_image_rounded, color: AppColors.rose));
      }
    } else {
      return Image.network(
        path,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: AppColors.sakura,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataLegal = DateFormat('dd MMMM yyyy • HH:mm').format(report.createdAt);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detalhes do Relato'),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.sakura, Colors.white],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 120, 24, 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                      boxShadow: AppStyles.softShadow,
                      border: Border.all(color: Colors.white.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.textLight),
                            const SizedBox(width: 8),
                            Text(dataLegal.toUpperCase(), style: const TextStyle(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'ACONTECIMENTO RELATADO',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.ruby, letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          report.description,
                          style: const TextStyle(fontSize: 17, height: 1.6, color: AppColors.textMain, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  const Text(
                    'EVIDÊNCIAS COLETADAS',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.ruby, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 16),
                  
                  if (report.photoUrls.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.sakura.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.rose.withOpacity(0.2)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: AppColors.rose),
                          SizedBox(width: 12),
                          Text('Nenhuma imagem anexada a este relato.', style: TextStyle(color: AppColors.textLight)),
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
                      itemCount: report.photoUrls.length,
                      itemBuilder: (context, index) {
                        return Hero(
                          tag: index == 0 ? 'report-${report.id}' : 'photo-$index',
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: AppStyles.softShadow,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: _mostrarImagem(report.photoUrls[index]),
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
                          report.contentHash,
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
