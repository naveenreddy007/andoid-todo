enum ConflictStatus {
  none,
  detected,
  resolved,
}

class SyncMetadata {
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncMetadata &&
        other.id == id &&
        other.entityType == entityType &&
        other.entityId == entityId &&
        other.localHash == localHash &&
        other.cloudHash == cloudHash &&
        other.lastSync == lastSync &&
        other.conflictStatus == conflictStatus;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      entityType,
      entityId,
      localHash,
      cloudHash,
      lastSync,
      conflictStatus,
    );
  }
}