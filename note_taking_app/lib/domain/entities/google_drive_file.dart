import 'package:equatable/equatable.dart';

enum EntityType { todo, reminder, attachment, category, tag }

class GoogleDriveFile extends Equatable {
  final String id;
  final EntityType entityType;
  final String entityId;
  final String googleFileId;
  final String fileName;
  final DateTime modifiedTime;
  final DateTime createdAt;

  const GoogleDriveFile({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.googleFileId,
    required this.fileName,
    required this.modifiedTime,
    required this.createdAt,
  });

  GoogleDriveFile copyWith({
    String? id,
    EntityType? entityType,
    String? entityId,
    String? googleFileId,
    String? fileName,
    DateTime? modifiedTime,
    DateTime? createdAt,
  }) {
    return GoogleDriveFile(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      googleFileId: googleFileId ?? this.googleFileId,
      fileName: fileName ?? this.fileName,
      modifiedTime: modifiedTime ?? this.modifiedTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        entityType,
        entityId,
        googleFileId,
        fileName,
        modifiedTime,
        createdAt,
      ];
}