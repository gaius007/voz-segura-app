import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../auth/data/firebase_auth_repository.dart';
import '../domain/contact.dart';

part 'firestore_contact_repository.g.dart';

abstract class ContactRepository {
  Stream<List<Contact>> watchContacts(String userId);
  Future<void> addContact(String userId, Contact contact);
  Future<void> updateContact(String userId, Contact contact);
  Future<void> deleteContact(String userId, String contactId);
}

class FirestoreContactRepository implements ContactRepository {
  final FirebaseFirestore _firestore;

  FirestoreContactRepository(this._firestore);

  @override
  Stream<List<Contact>> watchContacts(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return Contact.fromJson({...data, 'id': doc.id, 'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String()});
            }).toList());
  }

  @override
  Future<void> addContact(String userId, Contact contact) {
    return _firestore.collection('users').doc(userId).collection('contacts').add({
      ...contact.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    }..remove('id'));
  }

  @override
  Future<void> updateContact(String userId, Contact contact) {
    return _firestore.collection('users').doc(userId).collection('contacts').doc(contact.id).update({
      ...contact.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    }..remove('id'));
  }

  @override
  Future<void> deleteContact(String userId, String contactId) {
    return _firestore.collection('users').doc(userId).collection('contacts').doc(contactId).delete();
  }
}

@riverpod
ContactRepository contactRepository(ContactRepositoryRef ref) {
  return FirestoreContactRepository(ref.watch(firestoreProvider));
}

@riverpod
Stream<List<Contact>> contactsStream(ContactsStreamRef ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return Stream.value([]);
  return ref.watch(contactRepositoryProvider).watchContacts(user.uid);
}
