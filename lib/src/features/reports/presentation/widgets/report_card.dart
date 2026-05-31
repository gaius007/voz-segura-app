import 'dart:ui';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/report.dart';
import '../pages/report_detail_page.dart';
import 'package:voz_segura_app/src/core/theme/app_theme.dart';

class ReportCard extends StatelessWidget {
  final Report report;

  const ReportCard({super.key, required this.report});

  // Formatter imutável criado uma única vez (evita realocar a cada build de card).
  static final DateFormat _dateFormat = DateFormat('dd MMM, yyyy • HH:mm');

  // Cache dos bytes já decodificados de base64, evitando decodificar a cada rebuild
  // durante a rolagem da lista.
  static final Map<String, Uint8List> _decodedCache = {};

  Widget _mostrarImagem(BuildContext context, String path, {required double size}) {
    if (path.startsWith('data:image')) {
      try {
        final bytes = _decodedCache[path] ??= base64Url.decode(path.split(',').last);
        return Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: (size * 2).round(),
          cacheHeight: (size * 2).round(),
          errorBuilder: (ctx, error, stackTrace) => _buildPlaceholder(context, size),
        );
      } catch (e) {
        return _buildPlaceholder(context, size);
      }
    } else {
      return Image.network(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * 2).round(),
        cacheHeight: (size * 2).round(),
        errorBuilder: (ctx, error, stackTrace) => _buildPlaceholder(context, size),
      );
    }
  }

  Widget _buildPlaceholder(BuildContext context, double size) {
    return Container(
      width: size,
      height: size,
      color: context.appBlush.withOpacity(0.3),
      child: Icon(Icons.image_rounded, color: context.appRose),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataFormatada = _dateFormat.format(report.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.appGlassColor,
        borderRadius: BorderRadius.circular(AppStyles.borderRadius),
        boxShadow: context.appSoftShadow,
        border: Border.all(color: context.appGlassBorder),
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
                          ? _mostrarImagem(context, report.photoUrls.first, size: 80)
                          : _buildPlaceholder(context, 80),
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
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.appTextMain),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 12, color: context.appTextLight),
                            const SizedBox(width: 4),
                            Text(
                              dataFormatada.toUpperCase(),
                              style: TextStyle(color: context.appTextLight, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                        if (report.visibility == ReportVisibility.public) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.person_outline_rounded, size: 12, color: context.appRose),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Autora: ${report.authorName ?? "Usuária Voz Segura"}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: context.appRuby,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: context.appSakura,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "PROTOCOLO SEGURO",
                                style: TextStyle(color: context.appRuby, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: report.visibility == ReportVisibility.public
                                    ? const Color(0xFFE3F2FD)
                                    : const Color(0xFFECEFF1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    report.visibility == ReportVisibility.public
                                        ? Icons.public_rounded
                                        : Icons.lock_rounded,
                                    size: 10,
                                    color: report.visibility == ReportVisibility.public
                                        ? Colors.blue.shade700
                                        : Colors.blueGrey.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    report.visibility == ReportVisibility.public
                                        ? "PÚBLICO"
                                        : "PRIVADO",
                                    style: TextStyle(
                                      color: report.visibility == ReportVisibility.public
                                          ? Colors.blue.shade700
                                          : Colors.blueGrey.shade700,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: context.appRose),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
