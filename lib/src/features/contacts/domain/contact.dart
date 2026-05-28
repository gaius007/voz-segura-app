// Classe que representa um meio de contato (WhatsApp, Telefone, E-mail)
class ContactMethod {
  final String type;
  final String value;

  ContactMethod({required this.type, required this.value});

  factory ContactMethod.fromMap(Map<String, dynamic> map) {
    return ContactMethod(
      type: map['type'] ?? '',
      value: map['value'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'value': value,
    };
  }
}

// Classe que representa um contato de emergencia
class Contact {
  final String? id;
  final String name;
  final List<ContactMethod> methods;
  final DateTime? updatedAt;

  Contact({
    this.id,
    required this.name,
    required this.methods,
    this.updatedAt,
  });

  // Converte o Map do banco (SQLite ou Firebase) pro nosso objeto
  factory Contact.fromMap(Map<String, dynamic> map, [String? docId]) {
    List<ContactMethod> methods = [];
    
    // Suporte para o formato novo (lista de metodos)
    if (map['methods'] != null) {
      methods = (map['methods'] as List)
          .map((m) => ContactMethod.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    } 
    // Compatibilidade com o formato antigo (unico tipo e valor)
    else if (map['type'] != null && map['value'] != null) {
      methods = [
        ContactMethod(type: map['type'], value: map['value'])
      ];
    }

    return Contact(
      id: docId ?? map['id'],
      name: map['name'] ?? '',
      methods: methods,
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as dynamic).toDate() 
          : null,
    );
  }

  // Converte pra Map pra salvar na nuvem
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'methods': methods.map((m) => m.toMap()).toList(),
      'updatedAt': updatedAt ?? DateTime.now(),
    };
  }
}
