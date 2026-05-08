import 'dart:convert';
import '../../domain/entities/report.dart';

class ReportModel {
  final String id;
  final String description;
  final DateTime createdAt;
  final List<String> photoPaths;
  final String contentHash;
  final bool isSynced;

  const ReportModel({
    required this.id,
    required this.description,
    required this.createdAt,
    required this.photoPaths,
    required this.contentHash,
    this.isSynced = false,
  });

  factory ReportModel.fromEntity(Report entity) {
    return ReportModel(
      id: entity.id,
      description: entity.description,
      createdAt: entity.createdAt,
      photoPaths: entity.photoPaths,
      contentHash: entity.contentHash,
      isSynced: entity.isSynced,
    );
  }

  Report toEntity() {
    return Report(
      id: id,
      description: description,
      createdAt: createdAt,
      photoPaths: photoPaths,
      contentHash: contentHash,
      isSynced: isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'photoPaths': jsonEncode(photoPaths),
      'contentHash': contentHash,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      id: map['id'] as String,
      description: map['description'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      photoPaths: List<String>.from(jsonDecode(map['photoPaths'] as String)),
      contentHash: map['contentHash'] as String,
      isSynced: (map['isSynced'] as int) == 1,
    );
  }
}
