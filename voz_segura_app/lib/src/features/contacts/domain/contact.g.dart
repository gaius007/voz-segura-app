// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ContactImpl _$$ContactImplFromJson(Map<String, dynamic> json) =>
    _$ContactImpl(
      id: json['id'] as String?,
      name: json['name'] as String,
      type: json['type'] as String,
      value: json['value'] as String,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$ContactImplToJson(_$ContactImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'value': instance.value,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
