import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/report.dart';
import '../pages/report_detail_page.dart';
import 'package:voz_segura_app/src/core/theme/app_theme.dart';

class ReportCard extends StatelessWidget {
  final Report report;

  const ReportCard({super.key, required this.report});

  Widget _mostrarImagem(String path, {required double size}) {
    if (path.startsWith('data:image')) {
      try {
        final base64String = path.split(',').last;
        return Image.memory(
          base64Url.decode(base64String),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(size),
        );
      } catch (e) {
        return _buildPlaceholder(size);
      }
    } else {
      return Image.network(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(size),
      );
    }
  }

  Widget _buildPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      color: AppColors.blush.withOpacity(0.3),
      child: const Icon(Icons.image_rounded, color: AppColors.rose),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataFormatada = DateFormat('dd MMM, yyyy • HH:mm').format(report.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(AppStyles.borderRadius),
        boxShadow: AppStyles.softShadow,
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppStyles.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportDetailPage(report: report),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Hero(
                    tag: 'report-${report.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: report.photoUrls.isNotEmpty
                          ? _mostrarImagem(report.photoUrls.first, size: 80)
                          : _buildPlaceholder(80),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.description.isEmpty ? 'Relato sem descrição' : report.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textMain),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textLight),
                            const SizedBox(width: 4),
                            Text(
                              dataFormatada.toUpperCase(),
                              style: const TextStyle(color: AppColors.textLight, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.sakura,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "PROTOCOLO SEGURO",
                            style: TextStyle(color: AppColors.ruby, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.rose),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
