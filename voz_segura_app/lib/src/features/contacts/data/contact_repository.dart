import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/contact.dart';

// Repositorio de contatos completo pro Firebase
// Agora tem tudo: ler, salvar, editar e deletar
class ContactRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fica de olho nos contatos do usuario logado
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

  // Salva um contato novo na nuvem
  Future<void> addContact(String userId, Contact contact) {
    return _firestore.collection('users').doc(userId).collection('contacts').add({
      ...contact.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Atualiza um contato que ja existe
  // O professor disse que eh importante ter o edit
  Future<void> updateContact(String userId, Contact contact) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .doc(contact.id)
        .update({
          ...contact.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  // Remove o contato da rede de apoio
  Future<void> deleteContact(String userId, String contactId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .doc(contactId)
        .delete();
  }
}
