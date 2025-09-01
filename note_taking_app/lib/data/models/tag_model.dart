import '../../domain/entities/tag.dart';
import '../../domain/entities/todo.dart';

class TagModel {
  final String id;
  final String name;
  final String color;
  final String createdAt;
  final String syncStatus;
  final String? lastSynced;

  const TagModel({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
    required this.syncStatus,
    this.lastSynced,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      createdAt: json['created_at'] as String,
      syncStatus: json['sync_status'] as String,
      lastSynced: json['last_synced'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'created_at': createdAt,
      'sync_status': syncStatus,
      'last_synced': lastSynced,
    };
  }

  Tag toEntity() {
    return Tag(
      id: id,
      name: name,
      color: color,
      createdAt: DateTime.parse(createdAt),
    );
  }

  static TagModel fromEntity(Tag tag) {
    return TagModel(
      id: tag.id,
      name: tag.name,
      color: tag.color,
      createdAt: tag.createdAt.toIso8601String(),
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
