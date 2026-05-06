import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../auth/data/firebase_auth_repository.dart';
import '../data/firestore_contact_repository.dart';
import '../domain/contact.dart';

part 'contacts_controller.g.dart';

@riverpod
class ContactsController extends _$ContactsController {
  @override
  FutureOr<void> build() {
    // Initial state
  }

  Future<void> saveContact(Contact contact) async {
    state = const AsyncLoading();
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    state = await AsyncValue.guard(() async {
      if (contact.id == null) {
        await ref.read(contactRepositoryProvider).addContact(user.uid, contact);
      } else {
        await ref.read(contactRepositoryProvider).updateContact(user.uid, contact);
      }
    });
  }

  Future<void> deleteContact(String contactId) async {
    state = const AsyncLoading();
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    state = await AsyncValue.guard(() => 
      ref.read(contactRepositoryProvider).deleteContact(user.uid, contactId)
    );
  }
}
