import '../../domain/entities/reminder.dart';
import '../../domain/entities/todo.dart';

class ReminderModel {
  final String id;
  final String todoId;
  final String type;
  final String dateTime;
  final String? message;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final String syncStatus;
  final String? lastSynced;

  const ReminderModel({
    required this.id,
    required this.todoId,
    required this.type,
    required this.dateTime,
    this.message,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.lastSynced,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] as String,
      todoId: json['todo_id'] as String,
      type: json['type'] as String,
      dateTime: json['date_time'] as String,
      message: json['message'] as String?,
      isActive: (json['is_active'] as int) == 1,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      syncStatus: json['sync_status'] as String,
      lastSynced: json['last_synced'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'todo_id': todoId,
      'type': type,
      'date_time': dateTime,
      'message': message,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'sync_status': syncStatus,
      'last_synced': lastSynced,
    };
  }

  Reminder toEntity() {
    return Reminder(
      id: id,
      todoId: todoId,
      type: _stringToReminderType(type),
      dateTime: DateTime.parse(dateTime),
      isActive: isActive,
      createdAt: DateTime.parse(createdAt),
    );
  }

  static ReminderModel fromEntity(Reminder reminder) {
    return ReminderModel(
      id: reminder.id,
      todoId: reminder.todoId,
      type: _reminderTypeToString(reminder.type),
      dateTime: reminder.dateTime.toIso8601String(),
      message: null, // Not available in entity
      isActive: reminder.isActive,
      createdAt: reminder.createdAt.toIso8601String(),
      updatedAt: reminder.createdAt.toIso8601String(), // Use createdAt as fallback
      syncStatus: 'pending', // Default value
      lastSynced: null, // Not available in entity
    );
  }

  static ReminderType _stringToReminderType(String type) {
    switch (type) {
      case 'oneTime':
        return ReminderType.oneTime;
      case 'recurring':
        return ReminderType.recurring;
      default:
        return ReminderType.oneTime;
    }
  }

  static String _reminderTypeToString(ReminderType type) {
    switch (type) {
      case ReminderType.oneTime:
        return 'oneTime';
      case ReminderType.recurring:
        return 'recurring';
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