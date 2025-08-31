import 'package:equatable/equatable.dart';

enum Priority { low, medium, high }

enum SyncStatus { pending, synced, failed, conflict }

class Note extends Equatable {
  final String id;
  final String title;
  final String content;
  final String? plainText;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? reminderDate;
  final Priority priority;
  final String? categoryId;
  final List<String> tagIds;
  final bool isArchived;
  final bool isDeleted;
  final SyncStatus syncStatus;
  final DateTime? lastSynced;
  final String? cloudFileId;
  final List<String> attachmentIds;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    this.plainText,
    required this.createdAt,
    required this.updatedAt,
    this.reminderDate,
    this.priority = Priority.medium,
    this.categoryId,
    this.tagIds = const [],
    this.isArchived = false,
    this.isDeleted = false,
    this.syncStatus = SyncStatus.pending,
    this.lastSynced,
    this.cloudFileId,
    this.attachmentIds = const [],
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? plainText,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? reminderDate,
    Priority? priority,
    String? categoryId,
    List<String>? tagIds,
    bool? isArchived,
    bool? isDeleted,
    SyncStatus? syncStatus,
    DateTime? lastSynced,
    String? cloudFileId,
    List<String>? attachmentIds,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      plainText: plainText ?? this.plainText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reminderDate: reminderDate ?? this.reminderDate,
      priority: priority ?? this.priority,
      categoryId: categoryId ?? this.categoryId,
      tagIds: tagIds ?? this.tagIds,
      isArchived: isArchived ?? this.isArchived,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSynced: lastSynced ?? this.lastSynced,
      cloudFileId: cloudFileId ?? this.cloudFileId,
      attachmentIds: attachmentIds ?? this.attachmentIds,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        plainText,
        createdAt,
        updatedAt,
        reminderDate,
        priority,
        categoryId,
        tagIds,
        isArchived,
        isDeleted,
        syncStatus,
        lastSynced,
        cloudFileId,
        attachmentIds,
      ];
}
