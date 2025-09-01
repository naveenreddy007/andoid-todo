import 'package:equatable/equatable.dart';
import 'priority.dart';
import 'todo_status.dart';

enum SyncStatus { pending, synced, failed, conflict }

class Todo extends Equatable {
  final String id;
  final String title;
  final String? description;
  final TodoStatus status;
  final Priority priority;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? categoryId;
  final List<String> tagIds;
  final bool isDeleted;
  final SyncStatus syncStatus;
  final DateTime? lastSynced;
  final String? cloudFileId;
  final List<String> attachmentIds;
  final List<String> reminderIds;

  const Todo({
    required this.id,
    required this.title,
    this.description,
    this.status = TodoStatus.pending,
    this.priority = Priority.medium,
    this.dueDate,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.categoryId,
    this.tagIds = const [],
    this.isDeleted = false,
    this.syncStatus = SyncStatus.pending,
    this.lastSynced,
    this.cloudFileId,
    this.attachmentIds = const [],
    this.reminderIds = const [],
  });

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    TodoStatus? status,
    Priority? priority,
    DateTime? dueDate,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryId,
    List<String>? tagIds,
    bool? isDeleted,
    SyncStatus? syncStatus,
    DateTime? lastSynced,
    String? cloudFileId,
    List<String>? attachmentIds,
    List<String>? reminderIds,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryId: categoryId ?? this.categoryId,
      tagIds: tagIds ?? this.tagIds,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSynced: lastSynced ?? this.lastSynced,
      cloudFileId: cloudFileId ?? this.cloudFileId,
      attachmentIds: attachmentIds ?? this.attachmentIds,
      reminderIds: reminderIds ?? this.reminderIds,
    );
  }

  // Convenience getters
  bool get isCompleted => status == TodoStatus.completed;
  bool get isPending => status == TodoStatus.pending;
  bool get isInProgress => status == TodoStatus.inProgress;
  bool get isCancelled => status == TodoStatus.cancelled;
  bool get isOverdue => dueDate != null && dueDate!.isBefore(DateTime.now()) && !isCompleted;

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        status,
        priority,
        dueDate,
        completedAt,
        createdAt,
        updatedAt,
        categoryId,
        tagIds,
        isDeleted,
        syncStatus,
        lastSynced,
        cloudFileId,
        attachmentIds,
        reminderIds,
      ];
}
