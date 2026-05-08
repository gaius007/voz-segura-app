import 'dart:ui';
import 'dart:convert'; // Pra decodificar o Base64
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/report.dart';
import '../pages/report_detail_page.dart';

// Card de relato atualizado pra mostrar imagens em Base64 ou URL
class ReportCard extends StatelessWidget {
  final Report report;

  const ReportCard({super.key, required this.report});

  // Funcao ajudante pra decidir se mostra Image.network ou Image.memory
  Widget _mostrarImagem(String path, {required double size}) {
    if (path.startsWith('data:image')) {
      // Se comeca com data:image, eh o nosso Plano B (Base64)
      try {
        final base64String = path.split(',').last;
        return Image.memory(
          base64Url.decode(base64String),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
        );
      } catch (e) {
        return const Icon(Icons.error);
      }
    } else {
      // Senao, tenta carregar como link normal (legado)
      return Image.network(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataFormatada = DateFormat('dd/MM/yyyy HH:mm').format(report.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Hero(
              tag: 'report-${report.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: report.photoUrls.isNotEmpty
                    ? _mostrarImagem(report.photoUrls.first, size: 70)
                    : Container(
                        width: 70,
                        height: 70,
                        color: Colors.pink.shade50,
                        child: const Icon(Icons.image, color: Colors.pink),
                      ),
              ),
            ),
            title: Text(
              report.description.isEmpty ? 'Sem descrição' : report.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '📅 $dataFormatada',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFFFF4081)),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportDetailPage(report: report),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
