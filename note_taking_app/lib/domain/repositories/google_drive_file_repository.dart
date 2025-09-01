import '../entities/google_drive_file.dart';

abstract class GoogleDriveFileRepository {
  Future<List<GoogleDriveFile>> getAllGoogleDriveFiles();
  Future<GoogleDriveFile?> getGoogleDriveFileById(String id);
  Future<GoogleDriveFile?> getGoogleDriveFileByEntity(EntityType entityType, String entityId);
  Future<GoogleDriveFile?> getGoogleDriveFileByGoogleFileId(String googleFileId);
  Future<void> saveGoogleDriveFile(GoogleDriveFile file);
  Future<void> updateGoogleDriveFile(GoogleDriveFile file);
  Future<void> deleteGoogleDriveFile(String id);
  Future<void> deleteGoogleDriveFileByEntity(EntityType entityType, String entityId);
  Stream<List<GoogleDriveFile>> watchGoogleDriveFiles();
  Future<List<GoogleDriveFile>> getGoogleDriveFilesByEntityType(EntityType entityType);
  Future<List<GoogleDriveFile>> getGoogleDriveFilesDueForSync();
  Future<List<GoogleDriveFile>> getOutdatedGoogleDriveFiles();
}