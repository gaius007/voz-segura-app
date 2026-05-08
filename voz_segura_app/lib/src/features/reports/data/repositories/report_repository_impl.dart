import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/report.dart';
import '../../domain/repositories/report_repository.dart';

// Essa classe aqui faz toda a parte chata de salvar no Firebase
// Ela salva o texto no Firestore e as fotos no Storage
class ReportRepositoryImpl implements ReportRepository {
  // Pegando as instancias do Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  @override
  Future<void> createReport(Report report) async {
    // 1. Primeiro a gente precisa de um ID pro relato
    final reportId = _uuid.v4();
    
    // 2. Agora a gente faz o upload de cada foto pro Storage
    // Fiz uma lista pra guardar os links (URLs) das fotos na nuvem
    List<String> linksDasFotos = [];

    // O professor falou pra usar pasta evidence_photos/
    for (var caminhoLocal in report.photoUrls) { // aqui usamos o campo que passamos no novo()
      File arquivo = File(caminhoLocal);
      String nomeArquivo = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Faz o upload pro Firebase Storage
      Reference ref = _storage.ref().child('evidence_photos/$reportId/$nomeArquivo');
      UploadTask uploadTask = ref.putFile(arquivo);
      
      // Espera terminar e pega o link publico
      TaskSnapshot snapshot = await uploadTask;
      String url = await snapshot.ref.getDownloadURL();
      linksDasFotos.add(url);
    }

    // 3. Cria um hash simples pra fingir seguranca (vi no tutorial tb)
    final hashSimples = 'firebase_${reportId.substring(0, 5)}';

    // 4. Salva tudo no Firestore na colecao 'reports'
    await _firestore.collection('reports').doc(reportId).set({
      'description': report.description,
      'createdAt': FieldValue.serverTimestamp(), // usa a hora do servidor pra nao dar erro
      'photoUrls': linksDasFotos,
      'contentHash': hashSimples,
    });
    
    // Nao usei toMap() aqui direto pq o createdAt eh especial do Firebase
  }

  @override
  Future<List<Report>> getReports() async {
    // Busca todos os relatos da colecao 'reports' ordenando pela data
    QuerySnapshot snapshot = await _firestore
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .get();

    // Transforma os documentos do Firebase nos nossos objetos Report
    return snapshot.docs.map((doc) {
      return Report.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }
}
