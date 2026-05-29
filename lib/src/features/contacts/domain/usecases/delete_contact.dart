import '../repositories/contact_repository.dart';

class DeleteContact {
  final ContactRepository repository;

  DeleteContact(this.repository);

  Future<void> execute(String userId, String contactId) async {
    if (contactId.isEmpty) {
      throw Exception('ID do contato inválido!');
    }
    return await repository.deleteContact(userId, contactId);
  }
}
