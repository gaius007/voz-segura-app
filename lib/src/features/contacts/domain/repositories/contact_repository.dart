import '../contact.dart';

// Contrato do repositório de contatos de emergência.
// A camada de apresentação depende desta abstração, nunca da implementação concreta.
abstract class ContactRepository {
  Stream<List<Contact>> watchContacts(String userId);
  Future<void> addContact(String userId, Contact contact);
  Future<void> updateContact(String userId, Contact contact);
  Future<void> deleteContact(String userId, String contactId);
}
