import '../../domain/entities/todo.dart';
import '../../domain/entities/priority.dart';
import '../../domain/entities/todo_status.dart';

class TodoModel {
  final String id;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final String? categoryId;
  final String? dueDate;
  final String? completedAt;
  final String createdAt;
  final String updatedAt;
  final bool isDeleted;
  final String syncStatus;
  final String? lastSynced;
  final String? cloudFileId;

  const TodoModel({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.categoryId,
    this.dueDate,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
    required this.syncStatus,
    this.lastSynced,
    this.cloudFileId,
  });

  factory TodoModel.fromJson(Map<String, dynamic> json) {
    return TodoModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      priority: json['priority'] as String,
      categoryId: json['category_id'] as String?,
      dueDate: json['due_date'] as String?,
      completedAt: json['completed_at'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
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
      'description': description,
      'status': status,
      'priority': priority,
      'category_id': categoryId,
      'due_date': dueDate,
      'completed_at': completedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_deleted': isDeleted ? 1 : 0,
      'sync_status': syncStatus,
      'last_synced': lastSynced,
      'cloud_file_id': cloudFileId,
    };
  }

  Todo toEntity({
    List<String> tagIds = const [],
    List<String> attachmentIds = const [],
    List<String> reminderIds = const [],
  }) {
    return Todo(
      id: id,
      title: title,
      description: description,
      status: _stringToStatus(status),
      priority: _stringToPriority(priority),
      categoryId: categoryId,
      tagIds: tagIds,
      attachmentIds: attachmentIds,
      reminderIds: reminderIds,
      dueDate: dueDate != null ? DateTime.parse(dueDate!) : null,
      completedAt: completedAt != null ? DateTime.parse(completedAt!) : null,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      isDeleted: isDeleted,
      syncStatus: _stringToSyncStatus(syncStatus),
      lastSynced: lastSynced != null ? DateTime.parse(lastSynced!) : null,
      cloudFileId: cloudFileId,
    );
  }

  static TodoModel fromEntity(Todo todo) {
    return TodoModel(
      id: todo.id,
      title: todo.title,
      description: todo.description,
      status: _statusToString(todo.status),
      priority: _priorityToString(todo.priority),
      categoryId: todo.categoryId,
      dueDate: todo.dueDate?.toIso8601String(),
      completedAt: todo.completedAt?.toIso8601String(),
      createdAt: todo.createdAt.toIso8601String(),
      updatedAt: todo.updatedAt.toIso8601String(),
      isDeleted: todo.isDeleted,
      syncStatus: _syncStatusToString(todo.syncStatus),
      lastSynced: todo.lastSynced?.toIso8601String(),
      cloudFileId: todo.cloudFileId,
    );
  }

  static TodoStatus _stringToStatus(String status) {
    switch (status) {
      case 'pending':
        return TodoStatus.pending;
      case 'inProgress':
        return TodoStatus.inProgress;
      case 'completed':
        return TodoStatus.completed;
      case 'cancelled':
        return TodoStatus.cancelled;
      default:
        return TodoStatus.pending;
    }
  }

  static String _statusToString(TodoStatus status) {
    switch (status) {
      case TodoStatus.pending:
        return 'pending';
      case TodoStatus.inProgress:
        return 'inProgress';
      case TodoStatus.completed:
        return 'completed';
      case TodoStatus.cancelled:
        return 'cancelled';
    }
  }

  static Priority _stringToPriority(String priority) {
    switch (priority) {
      case 'low':
        return Priority.low;
      case 'medium':
        return Priority.medium;
      case 'high':
        return Priority.high;
      case 'urgent':
        return Priority.urgent;
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
      case Priority.urgent:
        return 'urgent';
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
