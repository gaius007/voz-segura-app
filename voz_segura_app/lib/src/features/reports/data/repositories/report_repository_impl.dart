import 'dart:convert'; // Pra converter pra Base64
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/report.dart';
import '../../domain/repositories/report_repository.dart';

// REPOSITORIO PLANO B: Usando Base64 porque o Storage pediu Upgrade de conta
class ReportRepositoryImpl implements ReportRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  @override
  Future<void> createReport(Report report) async {
    final reportId = _uuid.v4();
    List<String> fotosEmBase64 = [];

    try {
      debugPrint('VS: Iniciando criacao do relato via Base64');

      // Em vez de subir pro Storage, a gente transforma em texto
      for (var caminhoLocal in report.photoUrls) {
        debugPrint('VS: Convertendo foto para Base64...');
        final xFile = XFile(caminhoLocal);
        final bytes = await xFile.readAsBytes();
        
        // O segredo eh esse: transformar os bytes da imagem em uma String
        // Coloquei o prefixo 'data:image/jpeg;base64,' pra gente saber o que eh depois
        String base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        fotosEmBase64.add(base64Image);
        debugPrint('VS: Conversao concluida! Tamanho do texto: ${base64Image.length}');
      }

      // Agora salva tudo direto no Firestore
      debugPrint('VS: Salvando tudo no Firestore...');
      final hashSimples = 'vs_${reportId.substring(0, 5)}';

      await _firestore.collection('reports').doc(reportId).set({
        'description': report.description,
        'createdAt': FieldValue.serverTimestamp(),
        'photoUrls': fotosEmBase64, // Agora aqui vao as Strings do Base64
        'contentHash': hashSimples,
      }).timeout(const Duration(seconds: 20));
      
      debugPrint('VS: Relato salvo com sucesso no Firestore!');
      
    } catch (e) {
      debugPrint('VS: ERRO no Plano B: $e');
      rethrow; 
    }
  }

  @override
  Future<List<Report>> getReports() async {
    try {
      debugPrint('VS: Buscando relatos...');
      QuerySnapshot snapshot = await _firestore
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return Report.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      debugPrint('VS: Erro ao buscar: $e');
      return [];
    }
  }
}
