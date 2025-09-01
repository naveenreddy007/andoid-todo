import '../../domain/entities/category.dart';
import '../../domain/entities/todo.dart';

class CategoryModel {
  final String id;
  final String name;
  final String? icon;
  final String color;
  final String createdAt;
  final String syncStatus;
  final String? lastSynced;

  const CategoryModel({
    required this.id,
    required this.name,
    this.icon,
    required this.color,
    required this.createdAt,
    required this.syncStatus,
    this.lastSynced,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String,
      createdAt: json['created_at'] as String,
      syncStatus: json['sync_status'] as String? ?? 'pending',
      lastSynced: json['last_synced'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'created_at': createdAt,
      'sync_status': syncStatus,
      'last_synced': lastSynced,
    };
  }

  Category toEntity() {
    return Category(
      id: id,
      name: name,
      icon: icon,
      color: color,
      createdAt: DateTime.parse(createdAt),
    );
  }

  static CategoryModel fromEntity(Category category) {
    return CategoryModel(
      id: category.id,
      name: category.name,
      icon: category.icon,
      color: category.color,
      createdAt: category.createdAt.toIso8601String(),
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
