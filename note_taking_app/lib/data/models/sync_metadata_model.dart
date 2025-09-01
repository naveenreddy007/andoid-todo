import '../../domain/entities/sync_metadata.dart';

class SyncMetadataModel {
  final String id;
  final String entityType;
  final String entityId;
  final String? localHash;
  final String? cloudHash;
  final String? lastSync;
  final String conflictStatus;

  const SyncMetadataModel({
    required this.id,
    required this.entityType,
    required this.entityId,
    this.localHash,
    this.cloudHash,
    this.lastSync,
    required this.conflictStatus,
  });

  factory SyncMetadataModel.fromJson(Map<String, dynamic> json) {
    return SyncMetadataModel(
      id: json['id'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      localHash: json['local_hash'] as String?,
      cloudHash: json['cloud_hash'] as String?,
      lastSync: json['last_sync'] as String?,
      conflictStatus: json['conflict_status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'local_hash': localHash,
      'cloud_hash': cloudHash,
      'last_sync': lastSync,
      'conflict_status': conflictStatus,
    };
  }

  SyncMetadata toEntity() {
    return SyncMetadata(
      id: id,
      entityType: entityType,
      entityId: entityId,
      localHash: localHash,
      cloudHash: cloudHash,
      lastSync: lastSync != null ? DateTime.parse(lastSync!) : null,
      conflictStatus: _stringToConflictStatus(conflictStatus),
    );
  }

  static SyncMetadataModel fromEntity(SyncMetadata syncMetadata) {
    return SyncMetadataModel(
      id: syncMetadata.id,
      entityType: syncMetadata.entityType,
      entityId: syncMetadata.entityId,
      localHash: syncMetadata.localHash,
      cloudHash: syncMetadata.cloudHash,
      lastSync: syncMetadata.lastSync?.toIso8601String(),
      conflictStatus: _conflictStatusToString(syncMetadata.conflictStatus),
    );
  }

  static ConflictStatus _stringToConflictStatus(String conflictStatus) {
    switch (conflictStatus) {
      case 'none':
        return ConflictStatus.none;
      case 'detected':
        return ConflictStatus.detected;
      case 'resolved':
        return ConflictStatus.resolved;
      default:
        return ConflictStatus.none;
    }
  }

  static String _conflictStatusToString(ConflictStatus conflictStatus) {
    switch (conflictStatus) {
      case ConflictStatus.none:
        return 'none';
      case ConflictStatus.detected:
        return 'detected';
      case ConflictStatus.resolved:
        return 'resolved';
    }
  }
}