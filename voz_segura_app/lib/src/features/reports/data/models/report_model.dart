import 'dart:convert';
import '../../domain/entities/report.dart';

class ReportModel {
  final String id;
  final String description;
  final DateTime createdAt;
  final List<String> photoUrls;
  final String contentHash;

  const ReportModel({
    required this.id,
    required this.description,
    required this.createdAt,
    required this.photoUrls,
    required this.contentHash,
  });

  factory ReportModel.fromEntity(Report entity) {
    return ReportModel(
      id: entity.id,
      description: entity.description,
      createdAt: entity.createdAt,
      photoUrls: entity.photoUrls,
      contentHash: entity.contentHash,
    );
  }

  Report toEntity() {
    return Report(
      id: id,
      description: description,
      createdAt: createdAt,
      photoUrls: photoUrls,
      contentHash: contentHash,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'photoUrls': jsonEncode(photoUrls),
      'contentHash': contentHash,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      id: map['id'] as String,
      description: map['description'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      photoUrls: List<String>.from(jsonDecode(map['photoUrls'] as String)),
      contentHash: map['contentHash'] as String,
    );
  }
}
