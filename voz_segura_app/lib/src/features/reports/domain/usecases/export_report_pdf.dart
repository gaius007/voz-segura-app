import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/report.dart';

class ExportReportToPdf {
  Future<void> call(Report report) async {
    final pdf = pw.Document();
    final dateFormatted = DateFormat('dd/MM/yyyy HH:mm:ss').format(report.createdAt);

    // Carrega as imagens para o PDF
    final List<pw.MemoryImage> pdfImages = [];
    for (var path in report.photoPaths) {
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        pdfImages.add(pw.MemoryImage(bytes));
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Relato Seguro - Evidencia Juridica', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('ID: ${report.id.substring(0, 8)}...', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Data e Hora do Registro: $dateFormatted'),
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Text('Descricao do Relato:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Paragraph(text: report.description),
          pw.SizedBox(height: 20),
          pw.Text('Evidencias Anexadas:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Wrap(
            spacing: 15,
            runSpacing: 15,
            children: pdfImages.map((img) => pw.Container(
              width: 250,
              height: 250,
              child: pw.Image(img, fit: pw.BoxFit.contain),
            )).toList(),
          ),
          pw.SizedBox(height: 40),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey),
              color: PdfColors.grey100,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Assinatura Digital de Integridade (SHA-256):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.SizedBox(height: 4),
                pw.Text(report.contentHash, style: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey800)),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Este documento e uma prova juridica gerada pelo sistema Voz Segura. '
                  'Qualquer alteracao nos bytes deste PDF ou no banco de dados original invalidara o hash acima.',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Compartilha ou imprime o PDF
    final bytes = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/Relato_${report.id.substring(0, 8)}.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path)], text: 'Relato Seguro - Evidencia');
  }
}
