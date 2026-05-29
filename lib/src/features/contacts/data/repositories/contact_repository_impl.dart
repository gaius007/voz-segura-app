import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/contact.dart';
import '../../domain/repositories/contact_repository.dart';

// Repositorio de contatos com proteção de tempo (timeout)
class ContactRepositoryImpl implements ContactRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<Contact>> watchContacts(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return Contact.fromMap(doc.data(), doc.id);
            }).toList());
  }

  // Salva contato novo (com limite de 15 segundos)
  @override
  Future<void> addContact(String userId, Contact contact) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .add({
          ...contact.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .timeout(const Duration(seconds: 15));
  }

  // Edita contato (com limite de 15 segundos)
  @override
  Future<void> updateContact(String userId, Contact contact) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .doc(contact.id)
        .update({
          ...contact.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .timeout(const Duration(seconds: 15));
  }

  // Deleta contato
  @override
  Future<void> deleteContact(String userId, String contactId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .doc(contactId)
        .delete()
        .timeout(const Duration(seconds: 10));
  }
}
