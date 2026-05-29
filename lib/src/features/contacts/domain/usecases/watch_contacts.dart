import '../contact.dart';
import '../repositories/contact_repository.dart';

class WatchContacts {
  final ContactRepository repository;

  WatchContacts(this.repository);

  Stream<List<Contact>> execute(String userId) {
    if (userId.isEmpty) {
      throw Exception('Usuário inválido!');
    }
    return repository.watchContacts(userId);
  }
}
