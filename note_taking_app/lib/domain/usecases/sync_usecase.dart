import '../entities/sync_metadata.dart';
import '../entities/google_drive_file.dart';
import '../repositories/sync_metadata_repository.dart';
import '../repositories/google_drive_file_repository.dart';
import '../repositories/todo_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/tag_repository.dart';
import '../repositories/reminder_repository.dart';
import '../repositories/attachment_repository.dart';

class SyncUseCase {
  final SyncMetadataRepository _syncMetadataRepository;
  final GoogleDriveFileRepository _googleDriveFileRepository;
  final TodoRepository _todoRepository;
  final CategoryRepository _categoryRepository;
  final TagRepository _tagRepository;
  final ReminderRepository _reminderRepository;
  final AttachmentRepository _attachmentRepository;

  SyncUseCase(
    this._syncMetadataRepository,
    this._googleDriveFileRepository,
    this._todoRepository,
    this._categoryRepository,
    this._tagRepository,
    this._reminderRepository,
    this._attachmentRepository,
  );

  Future<void> syncAllData() async {
    try {
      // Sync todos
      await _syncTodos();
      
      // Sync categories
      await _syncCategories();
      
      // Sync tags
      await _syncTags();
      
      // Sync reminders
      await _syncReminders();
      
      // Sync attachments
      await _syncAttachments();
      
    } catch (e) {
      throw Exception('Sync failed: $e');
    }
  }

  Future<void> _syncTodos() async {
    final pendingTodos = await _todoRepository.getTodosDueForSync();
    
    for (final todo in pendingTodos) {
      try {
        // Check if Google Drive file exists for this todo
        final googleDriveFile = await _googleDriveFileRepository
            .getGoogleDriveFileByEntity(EntityType.todo, todo.id);
        
        if (googleDriveFile == null) {
          // Create new file in Google Drive
          await _createGoogleDriveFile(todo.id, EntityType.todo, 'todo_${todo.id}.json');
        } else {
          // Update existing file in Google Drive
          await _updateGoogleDriveFile(googleDriveFile);
        }
        
        // Update sync metadata
        await _updateSyncMetadata('todo', todo.id);
        
      } catch (e) {
        // Mark as conflict if sync fails
        await _markSyncConflict('todo', todo.id, e.toString());
      }
    }
  }

  Future<void> _syncCategories() async {
    final pendingCategories = await _categoryRepository.getCategoriesDueForSync();
    
    for (final category in pendingCategories) {
      try {
        await _updateSyncMetadata('category', category.id);
      } catch (e) {
        await _markSyncConflict('category', category.id, e.toString());
      }
    }
  }

  Future<void> _syncTags() async {
    final pendingTags = await _tagRepository.getTagsDueForSync();
    
    for (final tag in pendingTags) {
      try {
        await _updateSyncMetadata('tag', tag.id);
      } catch (e) {
        await _markSyncConflict('tag', tag.id, e.toString());
      }
    }
  }

  Future<void> _syncReminders() async {
    final pendingReminders = await _reminderRepository.getRemindersDueForSync();
    
    for (final reminder in pendingReminders) {
      try {
        await _updateSyncMetadata('reminder', reminder.id);
      } catch (e) {
        await _markSyncConflict('reminder', reminder.id, e.toString());
      }
    }
  }

  Future<void> _syncAttachments() async {
    final pendingAttachments = await _attachmentRepository.getAttachmentsDueForSync();
    
    for (final attachment in pendingAttachments) {
      try {
        // Check if Google Drive file exists for this attachment
        final googleDriveFile = await _googleDriveFileRepository
            .getGoogleDriveFileByEntity(EntityType.attachment, attachment.id);
        
        if (googleDriveFile == null) {
          // Create new file in Google Drive
          await _createGoogleDriveFile(
            attachment.id, 
            EntityType.attachment, 
            attachment.fileName
          );
        } else {
          // Update existing file in Google Drive
          await _updateGoogleDriveFile(googleDriveFile);
        }
        
        await _updateSyncMetadata('attachment', attachment.id);
      } catch (e) {
        await _markSyncConflict('attachment', attachment.id, e.toString());
      }
    }
  }

  Future<void> _createGoogleDriveFile(String entityId, EntityType entityType, String fileName) async {
    final googleDriveFile = GoogleDriveFile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      entityType: entityType,
      entityId: entityId,
      googleFileId: 'google_file_${DateTime.now().millisecondsSinceEpoch}', // This would be actual Google Drive file ID
      fileName: fileName,
      modifiedTime: DateTime.now(),
      createdAt: DateTime.now(),
    );
    
    await _googleDriveFileRepository.saveGoogleDriveFile(googleDriveFile);
  }

  Future<void> _updateGoogleDriveFile(GoogleDriveFile googleDriveFile) async {
    final updatedFile = googleDriveFile.copyWith(
      modifiedTime: DateTime.now(),
    );
    
    await _googleDriveFileRepository.updateGoogleDriveFile(updatedFile);
  }

  Future<void> _updateSyncMetadata(String entityType, String entityId) async {
    final existingMetadata = await _syncMetadataRepository
        .getSyncMetadataByEntity(entityType, entityId);
    
    if (existingMetadata == null) {
      // Create new sync metadata
      final syncMetadata = SyncMetadata(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        entityType: entityType,
        entityId: entityId,
        localHash: 'local_hash_${DateTime.now().millisecondsSinceEpoch}',
        cloudHash: 'cloud_hash_${DateTime.now().millisecondsSinceEpoch}',
        lastSync: DateTime.now(),
        conflictStatus: ConflictStatus.none,
      );
      
      await _syncMetadataRepository.saveSyncMetadata(syncMetadata);
    } else {
      // Update existing sync metadata
      final updatedMetadata = existingMetadata.copyWith(
        localHash: 'local_hash_${DateTime.now().millisecondsSinceEpoch}',
        cloudHash: 'cloud_hash_${DateTime.now().millisecondsSinceEpoch}',
        lastSync: DateTime.now(),
        conflictStatus: ConflictStatus.none,
      );
      
      await _syncMetadataRepository.updateSyncMetadata(updatedMetadata);
    }
  }

  Future<void> _markSyncConflict(String entityType, String entityId, String error) async {
    final existingMetadata = await _syncMetadataRepository
        .getSyncMetadataByEntity(entityType, entityId);
    
    if (existingMetadata != null) {
      final conflictMetadata = existingMetadata.copyWith(
        conflictStatus: ConflictStatus.detected,
      );
      
      await _syncMetadataRepository.updateSyncMetadata(conflictMetadata);
    }
  }

  Future<List<SyncMetadata>> getConflictedEntities() async {
    return await _syncMetadataRepository.getConflictedEntities();
  }

  Future<void> resolveConflict(String syncMetadataId, ConflictStatus resolution) async {
    final metadata = await _syncMetadataRepository.getSyncMetadataById(syncMetadataId);
    if (metadata != null) {
      final resolvedMetadata = metadata.copyWith(
        conflictStatus: resolution,
      );
      
      await _syncMetadataRepository.updateSyncMetadata(resolvedMetadata);
    }
  }
}