import 'dart:convert'; // Pra converter pra Base64
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      final currentUser = FirebaseAuth.instance.currentUser;
      final authorUid = report.authorUid ?? currentUser?.uid;
      // Para relatos privados, o nome da autora eh omitido (null) para preservar total confidencialidade
      final authorName = report.visibility == ReportVisibility.public
          ? (report.authorName ?? currentUser?.displayName)
          : null;

      await _firestore.collection('reports').doc(reportId).set({
        'description': report.description,
        'createdAt': FieldValue.serverTimestamp(),
        'photoUrls': fotosEmBase64, // Agora aqui vao as Strings do Base64
        'contentHash': hashSimples,
        'visibility': report.visibility.toMapString(),
        'authorUid': authorUid,
        'authorName': authorName,
      }).timeout(const Duration(seconds: 20));
      
      debugPrint('VS: Relato salvo com sucesso no Firestore!');
      
    } catch (e) {
      debugPrint('VS: ERRO no Plano B: $e');
      rethrow; 
    }
  }

  @override
  Future<List<Report>> getReports({int? limit, DateTime? startAfter}) async {
    try {
      debugPrint('VS: Buscando relatos... limit: $limit, startAfter: $startAfter');
      Query query = _firestore
          .collection('reports')
          .orderBy('createdAt', descending: true);

      if (startAfter != null) {
        query = query.startAfter([Timestamp.fromDate(startAfter)]);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      QuerySnapshot snapshot = await query.get();

      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUid = currentUser?.uid;

      final fetchedReports = snapshot.docs.map((doc) {
        return Report.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Filtragem em memória: exibe se for público OU se for privado e pertencer à própria usuária
      return fetchedReports.where((report) {
        if (report.visibility == ReportVisibility.public) {
          return true;
        }
        return report.authorUid == currentUid;
      }).toList();
    } catch (e) {
      debugPrint('VS: Erro ao buscar: $e');
      return [];
    }
  }

  @override
  Future<void> updateReport(Report report) async {
    try {
      final docRef = _firestore.collection('reports').doc(report.id);
      final docSnap = await docRef.get();
      if (!docSnap.exists) {
        throw Exception('Relato não encontrado.');
      }

      final data = docSnap.data() as Map<String, dynamic>;
      final createdAt = data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now();

      // Validação de tempo de 10 minutos
      if (DateTime.now().difference(createdAt).inMinutes >= 10) {
        throw Exception('O prazo de 10 minutos para editar este relato já expirou.');
      }

      // Validação de autoria
      final currentUser = FirebaseAuth.instance.currentUser;
      final authorUid = data['authorUid'] as String?;
      if (currentUser?.uid != authorUid) {
        throw Exception('Você não tem permissão para editar este relato.');
      }

      await docRef.update({
        'description': report.description,
        'visibility': report.visibility.toMapString(),
      });
      debugPrint('VS: Relato editado com sucesso no Firestore!');
    } catch (e) {
      debugPrint('VS: Erro ao editar relato: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteReport(String id) async {
    try {
      final docRef = _firestore.collection('reports').doc(id);
      final docSnap = await docRef.get();
      if (!docSnap.exists) {
        throw Exception('Relato não encontrado.');
      }

      final data = docSnap.data() as Map<String, dynamic>;
      final createdAt = data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now();

      // Validação de tempo de 10 minutos
      if (DateTime.now().difference(createdAt).inMinutes >= 10) {
        throw Exception('O prazo de 10 minutos para excluir este relato já expirou.');
      }

      // Validação de autoria
      final currentUser = FirebaseAuth.instance.currentUser;
      final authorUid = data['authorUid'] as String?;
      if (currentUser?.uid != authorUid) {
        throw Exception('Você não tem permissão para excluir este relato.');
      }

      await docRef.delete();
      debugPrint('VS: Relato excluído com sucesso no Firestore!');
    } catch (e) {
      debugPrint('VS: Erro ao excluir relato: $e');
      rethrow;
    }
  }
}
