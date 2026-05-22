enum ReportVisibility {
  public,
  private;

  String toMapString() => name;

  static ReportVisibility fromMapString(String? val) {
    if (val == 'private') return ReportVisibility.private;
    return ReportVisibility.public;
  }
}

// Esse eh o nosso modelo de Relato agora pro Firebase
// O professor falou que eh melhor usar o Firestore pra salvar tudo na nuvem
class Report {
  final String id;
  final String description;
  final DateTime createdAt;
  final List<String> photoUrls; // agora salvamos as urls das fotos que estao na nuvem
  final String contentHash;
  final ReportVisibility visibility;
  final String? authorName;
  final String? authorUid;

  Report({
    required this.id,
    required this.description,
    required this.createdAt,
    required this.photoUrls,
    required this.contentHash,
    required this.visibility,
    this.authorName,
    this.authorUid,
  });

  // Construtor pra criar um novo relato na tela
  // A gente ainda nao tem o ID nem as URLs das fotos, entao comeca vazio
  factory Report.novo({
    required String description,
    required List<String> photoPaths, // aqui ainda sao os caminhos temporarios do cel
    required ReportVisibility visibility,
    String? authorName,
    String? authorUid,
  }) {
    return Report(
      id: '',
      description: description,
      createdAt: DateTime.now(),
      photoUrls: [], // as urls vao vir depois do upload
      contentHash: '',
      visibility: visibility,
      authorName: authorName,
      authorUid: authorUid,
    );
  }

  // Pega os dados do Firestore e transforma em objeto Report
  // No Firebase vem como um Map<String, dynamic>
  factory Report.fromMap(Map<String, dynamic> map, String docId) {
    return Report(
      id: docId, // o id do documento no firestore
      description: map['description'] ?? '',
      // No firestore a data vem como Timestamp, ai tem que converter
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as dynamic).toDate() 
          : DateTime.now(),
      // Transforma o que vem do banco em lista de string
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      contentHash: map['contentHash'] ?? '',
      visibility: ReportVisibility.fromMapString(map['visibility'] as String?),
      authorName: map['authorName'] as String?,
      authorUid: map['authorUid'] as String?,
    );
  }

  // Transforma o objeto em Map pra mandar pro Firestore
  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'createdAt': createdAt, // o Firebase ja entende DateTime
      'photoUrls': photoUrls,
      'contentHash': contentHash,
      'visibility': visibility.toMapString(),
      'authorName': authorName,
      'authorUid': authorUid,
    };
  }
}
