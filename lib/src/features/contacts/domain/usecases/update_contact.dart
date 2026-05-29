import '../contact.dart';
import '../repositories/contact_repository.dart';

class UpdateContact {
  final ContactRepository repository;

  UpdateContact(this.repository);

  Future<void> execute(String userId, Contact contact) async {
    if (contact.id == null || contact.id!.isEmpty) {
      throw Exception('Contato inválido!');
    }
    if (contact.name.isEmpty || contact.methods.isEmpty) {
      throw Exception('Informe um nome e ao menos um meio de contato!');
    }
    return await repository.updateContact(userId, contact);
  }
}
