import '../entities/sync_metadata.dart';

abstract class SyncMetadataRepository {
  Future<List<SyncMetadata>> getAllSyncMetadata();
  Future<SyncMetadata?> getSyncMetadataById(String id);
  Future<SyncMetadata?> getSyncMetadataByEntity(String entityType, String entityId);
  Future<void> saveSyncMetadata(SyncMetadata syncMetadata);
  Future<void> updateSyncMetadata(SyncMetadata syncMetadata);
  Future<void> deleteSyncMetadata(String id);
  Future<List<SyncMetadata>> getConflictedEntities();
  Future<List<SyncMetadata>> getPendingSyncEntities();
  Stream<List<SyncMetadata>> watchSyncMetadata();
}