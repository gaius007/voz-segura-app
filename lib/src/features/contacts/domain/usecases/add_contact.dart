import '../contact.dart';
import '../repositories/contact_repository.dart';

class AddContact {
  final ContactRepository repository;

  AddContact(this.repository);

  Future<void> execute(String userId, Contact contact) async {
    if (contact.name.isEmpty || contact.methods.isEmpty) {
      throw Exception('Informe um nome e ao menos um meio de contato!');
    }
    return await repository.addContact(userId, contact);
  }
}
