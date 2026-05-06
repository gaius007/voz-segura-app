import 'package:freezed_annotation/freezed_annotation.dart';

part 'contact.freezed.dart';
part 'contact.g.dart';

@freezed
class Contact with _$Contact {
  const factory Contact({
    String? id,
    required String name,
    required String type,
    required String value,
    DateTime? updatedAt,
  }) = _Contact;

  factory Contact.fromJson(Map<String, dynamic> json) => _$ContactFromJson(json);
}
