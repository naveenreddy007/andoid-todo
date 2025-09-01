import '../../domain/entities/google_drive_file.dart';

class GoogleDriveFileModel {
  final String id;
  final String entityType;
  final String entityId;
  final String googleFileId;
  final String fileName;
  final String modifiedTime;
  final String createdAt;

  const GoogleDriveFileModel({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.googleFileId,
    required this.fileName,
    required this.modifiedTime,
    required this.createdAt,
  });

  factory GoogleDriveFileModel.fromJson(Map<String, dynamic> json) {
    return GoogleDriveFileModel(
      id: json['id'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      googleFileId: json['google_file_id'] as String,
      fileName: json['file_name'] as String,
      modifiedTime: json['modified_time'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'google_file_id': googleFileId,
      'file_name': fileName,
      'modified_time': modifiedTime,
      'created_at': createdAt,
    };
  }

  GoogleDriveFile toEntity() {
    return GoogleDriveFile(
      id: id,
      entityType: _stringToEntityType(entityType),
      entityId: entityId,
      googleFileId: googleFileId,
      fileName: fileName,
      modifiedTime: DateTime.parse(modifiedTime),
      createdAt: DateTime.parse(createdAt),
    );
  }

  static GoogleDriveFileModel fromEntity(GoogleDriveFile googleDriveFile) {
    return GoogleDriveFileModel(
      id: googleDriveFile.id,
      entityType: _entityTypeToString(googleDriveFile.entityType),
      entityId: googleDriveFile.entityId,
      googleFileId: googleDriveFile.googleFileId,
      fileName: googleDriveFile.fileName,
      modifiedTime: googleDriveFile.modifiedTime.toIso8601String(),
      createdAt: googleDriveFile.createdAt.toIso8601String(),
    );
  }

  static EntityType _stringToEntityType(String entityType) {
    switch (entityType) {
      case 'todo':
        return EntityType.todo;
      case 'reminder':
        return EntityType.reminder;
      case 'attachment':
        return EntityType.attachment;
      case 'category':
        return EntityType.category;
      case 'tag':
        return EntityType.tag;
      default:
        return EntityType.todo;
    }
  }

  static String _entityTypeToString(EntityType entityType) {
    switch (entityType) {
      case EntityType.todo:
        return 'todo';
      case EntityType.reminder:
        return 'reminder';
      case EntityType.attachment:
        return 'attachment';
      case EntityType.category:
        return 'category';
      case EntityType.tag:
        return 'tag';
    }
  }
}