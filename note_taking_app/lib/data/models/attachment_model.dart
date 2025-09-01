import '../../domain/entities/attachment.dart';
import '../../domain/entities/todo.dart';

class AttachmentModel {
  final String id;
  final String todoId;
  final String fileName;
  final String filePath;
  final String? mimeType;
  final int? fileSize;
  final String createdAt;
  final String syncStatus;
  final String? lastSynced;

  const AttachmentModel({
    required this.id,
    required this.todoId,
    required this.fileName,
    required this.filePath,
    this.mimeType,
    this.fileSize,
    required this.createdAt,
    required this.syncStatus,
    this.lastSynced,
  });

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: json['id'] as String,
      todoId: json['todo_id'] as String,
      fileName: json['file_name'] as String,
      filePath: json['file_path'] as String,
      mimeType: json['mime_type'] as String?,
      fileSize: json['file_size'] as int?,
      createdAt: json['created_at'] as String,
      syncStatus: json['sync_status'] as String? ?? 'pending',
      lastSynced: json['last_synced'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'todo_id': todoId,
      'file_name': fileName,
      'file_path': filePath,
      'mime_type': mimeType,
      'file_size': fileSize,
      'created_at': createdAt,
      'sync_status': syncStatus,
      'last_synced': lastSynced,
    };
  }

  Attachment toEntity() {
    return Attachment(
      id: id,
      todoId: todoId,
      fileName: fileName,
      filePath: filePath,
      mimeType: mimeType,
      fileSize: fileSize,
      createdAt: DateTime.parse(createdAt),
    );
  }

  static AttachmentModel fromEntity(Attachment attachment) {
    return AttachmentModel(
      id: attachment.id,
      todoId: attachment.todoId,
      fileName: attachment.fileName,
      filePath: attachment.filePath,
      mimeType: attachment.mimeType,
      fileSize: attachment.fileSize,
      createdAt: attachment.createdAt.toIso8601String(),
      syncStatus: 'pending',
      lastSynced: null,
    );
  }

  static SyncStatus _stringToSyncStatus(String syncStatus) {
    switch (syncStatus) {
      case 'pending':
        return SyncStatus.pending;
      case 'synced':
        return SyncStatus.synced;
      case 'failed':
        return SyncStatus.failed;
      case 'conflict':
        return SyncStatus.conflict;
      default:
        return SyncStatus.pending;
    }
  }

  static String _syncStatusToString(SyncStatus syncStatus) {
    switch (syncStatus) {
      case SyncStatus.pending:
        return 'pending';
      case SyncStatus.synced:
        return 'synced';
      case SyncStatus.failed:
        return 'failed';
      case SyncStatus.conflict:
        return 'conflict';
    }
  }
}