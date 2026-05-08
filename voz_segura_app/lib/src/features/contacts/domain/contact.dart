// Classe que representa um contato de emergencia
// Fiz uma classe normal msm pra ser mais direto
class Contact {
  final String? id;
  final String name;
  final String type;
  final String value;
  final DateTime? updatedAt;

  Contact({
    this.id,
    required this.name,
    required this.type,
    required this.value,
    this.updatedAt,
  });

  // Converte o Map do banco (SQLite ou Firebase) pro nosso objeto
  factory Contact.fromMap(Map<String, dynamic> map, [String? docId]) {
    return Contact(
      id: docId ?? map['id'],
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      value: map['value'] ?? '',
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as dynamic).toDate() 
          : null,
    );
  }

  // Converte pra Map pra salvar na nuvem
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'value': value,
      'updatedAt': updatedAt ?? DateTime.now(),
    };
  }
}
