import '../entities/sync_metadata.dart';

abstract class SyncMetadataRepository {
  Future<List<SyncMetadata>> getAllSyncMetadata();
  Future<SyncMetadata?> getSyncMetadataById(String id);
  Future<SyncMetadata?> getSyncMetadataByEntity(String entityType, String entityId);
  Future<List<SyncMetadata>> getSyncMetadataByType(String entityType);
  Future<void> saveSyncMetadata(SyncMetadata syncMetadata);
  Future<void> updateSyncMetadata(SyncMetadata syncMetadata);
  Future<void> deleteSyncMetadata(String id);
  Future<void> deleteSyncMetadataByEntity(String entityType, String entityId);
  Future<List<SyncMetadata>> getConflictedEntities();
  Future<List<SyncMetadata>> getPendingSyncEntities();
  Future<List<SyncMetadata>> getConflictedSyncMetadata();
  Future<List<SyncMetadata>> getOutdatedSyncMetadata(DateTime threshold);
  Future<void> clearAllSyncMetadata();
  Stream<List<SyncMetadata>> watchSyncMetadata();
}