import 'package:equatable/equatable.dart';

enum ConflictStatus {
  none,
  detected,
  resolved,
}

class SyncMetadata extends Equatable {
  final String id;
  final String entityType;
  final String entityId;
  final String? localHash;
  final String? cloudHash;
  final DateTime? lastSync;
  final ConflictStatus conflictStatus;

  const SyncMetadata({
    required this.id,
    required this.entityType,
    required this.entityId,
    this.localHash,
    this.cloudHash,
    this.lastSync,
    required this.conflictStatus,
  });

  SyncMetadata copyWith({
    String? id,
    String? entityType,
    String? entityId,
    String? localHash,
    String? cloudHash,
    DateTime? lastSync,
    ConflictStatus? conflictStatus,
  }) {
    return SyncMetadata(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      localHash: localHash ?? this.localHash,
      cloudHash: cloudHash ?? this.cloudHash,
      lastSync: lastSync ?? this.lastSync,
      conflictStatus: conflictStatus ?? this.conflictStatus,
    );
  }

  @override
  List<Object?> get props => [
        id,
        entityType,
        entityId,
        localHash,
        cloudHash,
        lastSync,
        conflictStatus,
      ];
}