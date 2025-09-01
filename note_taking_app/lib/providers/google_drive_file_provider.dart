import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/local_google_drive_file_repository.dart';
import '../domain/entities/google_drive_file.dart';
import '../domain/repositories/google_drive_file_repository.dart';
import 'todo_provider.dart';

// Google Drive file repository provider
final googleDriveFileRepositoryProvider = Provider<GoogleDriveFileRepository>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return LocalGoogleDriveFileRepository(databaseHelper);
});

// Google Drive files list provider
final googleDriveFilesProvider = FutureProvider<List<GoogleDriveFile>>((ref) async {
  final repository = ref.watch(googleDriveFileRepositoryProvider);
  return repository.getAllGoogleDriveFiles();
});

// Google Drive files stream provider
final googleDriveFilesStreamProvider = StreamProvider<List<GoogleDriveFile>>((ref) {
  final repository = ref.watch(googleDriveFileRepositoryProvider);
  return repository.watchGoogleDriveFiles();
});

// Individual Google Drive file provider
final googleDriveFileProvider = FutureProvider.family<GoogleDriveFile?, String>((ref, id) async {
  final repository = ref.watch(googleDriveFileRepositoryProvider);
  return repository.getGoogleDriveFileById(id);
});

// Google Drive file by entity provider
final googleDriveFileByEntityProvider = FutureProvider.family<GoogleDriveFile?, ({String entityId, EntityType entityType})>((ref, params) async {
  final repository = ref.watch(googleDriveFileRepositoryProvider);
  return repository.getGoogleDriveFileByEntity(params.entityType, params.entityId);
});

// Google Drive file by Google file ID provider
final googleDriveFileByGoogleFileIdProvider = FutureProvider.family<GoogleDriveFile?, String>((ref, googleFileId) async {
  final repository = ref.watch(googleDriveFileRepositoryProvider);
  return repository.getGoogleDriveFileByGoogleFileId(googleFileId);
});

// Google Drive files by type provider
final googleDriveFilesByTypeProvider = FutureProvider.family<List<GoogleDriveFile>, EntityType>((ref, entityType) async {
  final repository = ref.watch(googleDriveFileRepositoryProvider);
  return repository.getGoogleDriveFilesByEntityType(entityType);
});

// Google Drive file operations notifier
class GoogleDriveFileOperationsNotifier extends StateNotifier<AsyncValue<void>> {
  final GoogleDriveFileRepository _repository;

  GoogleDriveFileOperationsNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> saveGoogleDriveFile(GoogleDriveFile googleDriveFile) async {
    state = const AsyncValue.loading();
    try {
      await _repository.saveGoogleDriveFile(googleDriveFile);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateGoogleDriveFile(GoogleDriveFile googleDriveFile) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateGoogleDriveFile(googleDriveFile);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteGoogleDriveFile(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteGoogleDriveFile(id);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteGoogleDriveFileByEntity(String entityId, EntityType entityType) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteGoogleDriveFileByEntity(entityType, entityId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final googleDriveFileOperationsProvider =
    StateNotifierProvider<GoogleDriveFileOperationsNotifier, AsyncValue<void>>((ref) {
      final repository = ref.watch(googleDriveFileRepositoryProvider);
      return GoogleDriveFileOperationsNotifier(repository);
    });