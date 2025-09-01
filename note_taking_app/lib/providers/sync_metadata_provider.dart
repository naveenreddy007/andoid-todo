import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/local_sync_metadata_repository.dart';
import '../domain/entities/sync_metadata.dart';
import '../domain/repositories/sync_metadata_repository.dart';
import 'todo_provider.dart';

// Sync metadata repository provider
final syncMetadataRepositoryProvider = Provider<SyncMetadataRepository>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return LocalSyncMetadataRepository(databaseHelper);
});

// Sync metadata list provider
final syncMetadataProvider = FutureProvider<List<SyncMetadata>>((ref) async {
  final repository = ref.watch(syncMetadataRepositoryProvider);
  return repository.getAllSyncMetadata();
});

// Sync metadata stream provider
final syncMetadataStreamProvider = StreamProvider<List<SyncMetadata>>((ref) {
  final repository = ref.watch(syncMetadataRepositoryProvider);
  return repository.watchSyncMetadata();
});

// Individual sync metadata provider
final syncMetadataByIdProvider = FutureProvider.family<SyncMetadata?, String>((ref, id) async {
  final repository = ref.watch(syncMetadataRepositoryProvider);
  return repository.getSyncMetadataById(id);
});

// Sync metadata by entity provider
final syncMetadataByEntityProvider = FutureProvider.family<SyncMetadata?, ({String entityId, String entityType})>((ref, params) async {
  final repository = ref.watch(syncMetadataRepositoryProvider);
  return repository.getSyncMetadataByEntity(params.entityType, params.entityId);
});

// Sync metadata by type provider
final syncMetadataByTypeProvider = FutureProvider.family<List<SyncMetadata>, String>((ref, entityType) async {
  final repository = ref.watch(syncMetadataRepositoryProvider);
  return repository.getSyncMetadataByType(entityType);
});

// Conflicted sync metadata provider
final conflictedSyncMetadataProvider = FutureProvider<List<SyncMetadata>>((ref) async {
  final repository = ref.watch(syncMetadataRepositoryProvider);
  return repository.getConflictedSyncMetadata();
});

// Outdated sync metadata provider
final outdatedSyncMetadataProvider = FutureProvider.family<List<SyncMetadata>, DateTime>((ref, threshold) async {
  final repository = ref.watch(syncMetadataRepositoryProvider);
  return repository.getOutdatedSyncMetadata(threshold);
});

// Sync metadata operations notifier
class SyncMetadataOperationsNotifier extends StateNotifier<AsyncValue<void>> {
  final SyncMetadataRepository _repository;

  SyncMetadataOperationsNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> saveSyncMetadata(SyncMetadata syncMetadata) async {
    state = const AsyncValue.loading();
    try {
      await _repository.saveSyncMetadata(syncMetadata);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateSyncMetadata(SyncMetadata syncMetadata) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateSyncMetadata(syncMetadata);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteSyncMetadata(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteSyncMetadata(id);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteSyncMetadataByEntity(String entityId, String entityType) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteSyncMetadataByEntity(entityType, entityId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> clearAllSyncMetadata() async {
    state = const AsyncValue.loading();
    try {
      await _repository.clearAllSyncMetadata();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final syncMetadataOperationsProvider =
    StateNotifierProvider<SyncMetadataOperationsNotifier, AsyncValue<void>>((ref) {
      final repository = ref.watch(syncMetadataRepositoryProvider);
      return SyncMetadataOperationsNotifier(repository);
    });