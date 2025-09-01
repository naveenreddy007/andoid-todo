import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../../core/constants/database_constants.dart';
import '../../core/errors/app_exceptions.dart' as app_exceptions;
import '../../domain/entities/google_drive_file.dart';
import '../../domain/repositories/google_drive_file_repository.dart';
import '../../services/local/database_helper.dart';
import '../models/google_drive_file_model.dart';

class LocalGoogleDriveFileRepository implements GoogleDriveFileRepository {
  final DatabaseHelper _databaseHelper;
  final _googleDriveFilesStreamController = StreamController<List<GoogleDriveFile>>.broadcast();

  LocalGoogleDriveFileRepository(this._databaseHelper) {
    _databaseHelper.databaseStream.listen((_) {
      getAllGoogleDriveFiles().then((files) => _googleDriveFilesStreamController.add(files));
    });
  }

  @override
  Future<List<GoogleDriveFile>> getAllGoogleDriveFiles() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.googleDriveFilesTable,
        orderBy: '${DatabaseConstants.googleDriveFileCreatedAt} DESC',
      );

      return maps.map((map) {
        final googleDriveFileModel = GoogleDriveFileModel.fromJson(map);
        return googleDriveFileModel.toEntity();
      }).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get all Google Drive files: $e');
    }
  }

  @override
  Future<GoogleDriveFile?> getGoogleDriveFileById(String id) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.googleDriveFilesTable,
        where: '${DatabaseConstants.googleDriveFileId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) return null;

      final googleDriveFileModel = GoogleDriveFileModel.fromJson(maps.first);
      return googleDriveFileModel.toEntity();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get Google Drive file by id: $e');
    }
  }

  @override
  Future<GoogleDriveFile?> getGoogleDriveFileByEntity(EntityType entityType, String entityId) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.googleDriveFilesTable,
        where: '${DatabaseConstants.googleDriveFileEntityType} = ? AND ${DatabaseConstants.googleDriveFileEntityId} = ?',
        whereArgs: [_entityTypeToString(entityType), entityId],
        limit: 1,
      );

      if (maps.isEmpty) return null;

      final googleDriveFileModel = GoogleDriveFileModel.fromJson(maps.first);
      return googleDriveFileModel.toEntity();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get Google Drive file by entity: $e');
    }
  }

  @override
  Future<GoogleDriveFile?> getGoogleDriveFileByGoogleFileId(String googleFileId) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.googleDriveFilesTable,
        where: '${DatabaseConstants.googleDriveFileGoogleFileId} = ?',
        whereArgs: [googleFileId],
        limit: 1,
      );

      if (maps.isEmpty) return null;

      final googleDriveFileModel = GoogleDriveFileModel.fromJson(maps.first);
      return googleDriveFileModel.toEntity();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get Google Drive file by Google file id: $e');
    }
  }

  @override
  Future<List<GoogleDriveFile>> getGoogleDriveFilesByType(EntityType entityType) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.googleDriveFilesTable,
        where: '${DatabaseConstants.googleDriveFileEntityType} = ?',
        whereArgs: [_entityTypeToString(entityType)],
        orderBy: '${DatabaseConstants.googleDriveFileCreatedAt} DESC',
      );

      return maps.map((map) {
        final googleDriveFileModel = GoogleDriveFileModel.fromJson(map);
        return googleDriveFileModel.toEntity();
      }).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get Google Drive files by type: $e');
    }
  }

  @override
  Future<List<GoogleDriveFile>> getRecentlyModifiedFiles(DateTime since) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.googleDriveFilesTable,
        where: '${DatabaseConstants.googleDriveFileModifiedTime} >= ?',
        whereArgs: [since.millisecondsSinceEpoch],
        orderBy: '${DatabaseConstants.googleDriveFileModifiedTime} DESC',
      );

      return maps.map((map) {
        final googleDriveFileModel = GoogleDriveFileModel.fromJson(map);
        return googleDriveFileModel.toEntity();
      }).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get recently modified files: $e');
    }
  }

  @override
  Future<void> saveGoogleDriveFile(GoogleDriveFile googleDriveFile) async {
    try {
      final db = await _databaseHelper.database;
      final googleDriveFileModel = GoogleDriveFileModel.fromEntity(googleDriveFile);
      await db.insert(
        DatabaseConstants.googleDriveFilesTable,
        googleDriveFileModel.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to save Google Drive file: $e');
    }
  }

  @override
  Future<void> updateGoogleDriveFile(GoogleDriveFile googleDriveFile) async {
    try {
      final db = await _databaseHelper.database;
      final googleDriveFileModel = GoogleDriveFileModel.fromEntity(googleDriveFile);
      final rowsAffected = await db.update(
        DatabaseConstants.googleDriveFilesTable,
        googleDriveFileModel.toJson(),
        where: '${DatabaseConstants.googleDriveFileId} = ?',
        whereArgs: [googleDriveFile.id],
      );

      if (rowsAffected == 0) {
        throw app_exceptions.DatabaseException('Google Drive file not found for update');
      }
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to update Google Drive file: $e');
    }
  }

  @override
  Future<void> deleteGoogleDriveFile(String id) async {
    try {
      final db = await _databaseHelper.database;
      final rowsAffected = await db.delete(
        DatabaseConstants.googleDriveFilesTable,
        where: '${DatabaseConstants.googleDriveFileId} = ?',
        whereArgs: [id],
      );

      if (rowsAffected == 0) {
        throw app_exceptions.DatabaseException('Google Drive file not found for deletion');
      }
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to delete Google Drive file: $e');
    }
  }

  @override
  Future<void> deleteGoogleDriveFileByEntity(EntityType entityType, String entityId) async {
    try {
      final db = await _databaseHelper.database;
      await db.delete(
        DatabaseConstants.googleDriveFilesTable,
        where: '${DatabaseConstants.googleDriveFileEntityType} = ? AND ${DatabaseConstants.googleDriveFileEntityId} = ?',
        whereArgs: [_entityTypeToString(entityType), entityId],
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to delete Google Drive file by entity: $e');
    }
  }

  @override
  Future<void> deleteGoogleDriveFileByGoogleFileId(String googleFileId) async {
    try {
      final db = await _databaseHelper.database;
      await db.delete(
        DatabaseConstants.googleDriveFilesTable,
        where: '${DatabaseConstants.googleDriveFileGoogleFileId} = ?',
        whereArgs: [googleFileId],
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to delete Google Drive file by Google file id: $e');
    }
  }

  @override
  Stream<List<GoogleDriveFile>> watchGoogleDriveFiles() {
    getAllGoogleDriveFiles().then((files) => _googleDriveFilesStreamController.add(files));
    return _googleDriveFilesStreamController.stream;
  }

  @override
  Future<List<GoogleDriveFile>> getGoogleDriveFilesByEntityType(EntityType entityType) async {
    return getGoogleDriveFilesByType(entityType);
  }

  @override
  Future<List<GoogleDriveFile>> getGoogleDriveFilesDueForSync() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.googleDriveFilesTable,
        orderBy: '${DatabaseConstants.googleDriveFileCreatedAt} ASC',
      );

      return maps.map((map) {
        final googleDriveFileModel = GoogleDriveFileModel.fromJson(map);
        return googleDriveFileModel.toEntity();
      }).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get Google Drive files due for sync: $e');
    }
  }

  @override
  Future<List<GoogleDriveFile>> getOutdatedGoogleDriveFiles() async {
    try {
      final db = await _databaseHelper.database;
      final oneDayAgo = DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;
      final maps = await db.query(
        DatabaseConstants.googleDriveFilesTable,
        where: '${DatabaseConstants.googleDriveFileModifiedTime} < ?',
        whereArgs: [oneDayAgo],
        orderBy: '${DatabaseConstants.googleDriveFileModifiedTime} ASC',
      );

      return maps.map((map) {
        final googleDriveFileModel = GoogleDriveFileModel.fromJson(map);
        return googleDriveFileModel.toEntity();
      }).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get outdated Google Drive files: $e');
    }
  }

  String _entityTypeToString(EntityType type) {
    switch (type) {
      case EntityType.todo:
        return 'todo';
      case EntityType.category:
        return 'category';
      case EntityType.tag:
        return 'tag';
      case EntityType.attachment:
        return 'attachment';
      case EntityType.reminder:
        return 'reminder';
    }
  }

  void dispose() {
    _googleDriveFilesStreamController.close();
  }
}