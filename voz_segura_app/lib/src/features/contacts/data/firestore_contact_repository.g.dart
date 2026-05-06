// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firestore_contact_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$contactRepositoryHash() => r'ca2aeac584045275a1b2f41108d6d913070d8855';

/// See also [contactRepository].
@ProviderFor(contactRepository)
final contactRepositoryProvider =
    AutoDisposeProvider<ContactRepository>.internal(
      contactRepository,
      name: r'contactRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$contactRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ContactRepositoryRef = AutoDisposeProviderRef<ContactRepository>;
String _$contactsStreamHash() => r'4f1ca10b6d2687a29d0e242428b34274869b8d21';

/// See also [contactsStream].
@ProviderFor(contactsStream)
final contactsStreamProvider =
    AutoDisposeStreamProvider<List<Contact>>.internal(
      contactsStream,
      name: r'contactsStreamProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$contactsStreamHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ContactsStreamRef = AutoDisposeStreamProviderRef<List<Contact>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
