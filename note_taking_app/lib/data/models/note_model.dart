import '../../domain/entities/note.dart';

class NoteModel {
  final String id;
  final String title;
  final String content;
  final String? plainText;
  final String createdAt;
  final String updatedAt;
  final String? reminderDate;
  final String priority;
  final String? categoryId;
  final bool isArchived;
  final bool isDeleted;
  final String syncStatus;
  final String? lastSynced;
  final String? cloudFileId;

  const NoteModel({
    required this.id,
    required this.title,
    required this.content,
    this.plainText,
    required this.createdAt,
    required this.updatedAt,
    this.reminderDate,
    required this.priority,
    this.categoryId,
    required this.isArchived,
    required this.isDeleted,
    required this.syncStatus,
    this.lastSynced,
    this.cloudFileId,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      plainText: json['plain_text'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      reminderDate: json['reminder_date'] as String?,
      priority: json['priority'] as String,
      categoryId: json['category_id'] as String?,
      isArchived: (json['is_archived'] as int) == 1,
      isDeleted: (json['is_deleted'] as int) == 1,
      syncStatus: json['sync_status'] as String,
      lastSynced: json['last_synced'] as String?,
      cloudFileId: json['cloud_file_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'plain_text': plainText,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'reminder_date': reminderDate,
      'priority': priority,
      'category_id': categoryId,
      'is_archived': isArchived ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'sync_status': syncStatus,
      'last_synced': lastSynced,
      'cloud_file_id': cloudFileId,
    };
  }

  Note toEntity({
    List<String> tagIds = const [],
    List<String> attachmentIds = const [],
  }) {
    return Note(
      id: id,
      title: title,
      content: content,
      plainText: plainText,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      reminderDate: reminderDate != null ? DateTime.parse(reminderDate!) : null,
      priority: _stringToPriority(priority),
      categoryId: categoryId,
      tagIds: tagIds,
      isArchived: isArchived,
      isDeleted: isDeleted,
      syncStatus: _stringToSyncStatus(syncStatus),
      lastSynced: lastSynced != null ? DateTime.parse(lastSynced!) : null,
      cloudFileId: cloudFileId,
      attachmentIds: attachmentIds,
    );
  }

  static NoteModel fromEntity(Note note) {
    return NoteModel(
      id: note.id,
      title: note.title,
      content: note.content,
      plainText: note.plainText,
      createdAt: note.createdAt.toIso8601String(),
      updatedAt: note.updatedAt.toIso8601String(),
      reminderDate: note.reminderDate?.toIso8601String(),
      priority: _priorityToString(note.priority),
      categoryId: note.categoryId,
      isArchived: note.isArchived,
      isDeleted: note.isDeleted,
      syncStatus: _syncStatusToString(note.syncStatus),
      lastSynced: note.lastSynced?.toIso8601String(),
      cloudFileId: note.cloudFileId,
    );
  }

  static Priority _stringToPriority(String priority) {
    switch (priority) {
      case 'low':
        return Priority.low;
      case 'medium':
        return Priority.medium;
      case 'high':
        return Priority.high;
      default:
        return Priority.medium;
    }
  }

  static String _priorityToString(Priority priority) {
    switch (priority) {
      case Priority.low:
        return 'low';
      case Priority.medium:
        return 'medium';
      case Priority.high:
        return 'high';
    }
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
