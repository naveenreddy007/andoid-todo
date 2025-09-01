import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../../core/constants/database_constants.dart';
import '../../core/errors/app_exceptions.dart' as app_exceptions;
import '../../domain/entities/google_drive_file.dart';
import '../../domain/entities/sync_metadata.dart';
import '../../domain/repositories/sync_metadata_repository.dart';
import '../../services/local/database_helper.dart';
import '../models/sync_metadata_model.dart';

class LocalSyncMetadataRepository implements SyncMetadataRepository {
  final DatabaseHelper _databaseHelper;
  final _syncMetadataStreamController = StreamController<List<SyncMetadata>>.broadcast();

  LocalSyncMetadataRepository(this._databaseHelper) {
    _databaseHelper.databaseStream.listen((_) {
      getAllSyncMetadata().then((metadata) => _syncMetadataStreamController.add(metadata));
    });
  }

  @override
  Future<List<SyncMetadata>> getAllSyncMetadata() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.syncMetadataTable,
        orderBy: '${DatabaseConstants.syncMetadataLastSync} DESC',
      );

      return maps.map((map) {
        final syncMetadataModel = SyncMetadataModel.fromJson(map);
        return syncMetadataModel.toEntity();
      }).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get all sync metadata: $e');
    }
  }

  @override
  Future<SyncMetadata?> getSyncMetadataById(String id) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.syncMetadataTable,
        where: '${DatabaseConstants.syncMetadataId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) return null;

      final syncMetadataModel = SyncMetadataModel.fromJson(maps.first);
      return syncMetadataModel.toEntity();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get sync metadata by id: $e');
    }
  }

  @override
  Future<SyncMetadata?> getSyncMetadataByEntity(String entityType, String entityId) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.syncMetadataTable,
        where: '${DatabaseConstants.syncMetadataEntityType} = ? AND ${DatabaseConstants.syncMetadataEntityId} = ?',
        whereArgs: [entityType, entityId],
        limit: 1,
      );

      if (maps.isEmpty) return null;

      final syncMetadataModel = SyncMetadataModel.fromJson(maps.first);
      return syncMetadataModel.toEntity();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get sync metadata by entity: $e');
    }
  }

  @override
  Future<List<SyncMetadata>> getSyncMetadataByType(String entityType) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.syncMetadataTable,
        where: '${DatabaseConstants.syncMetadataEntityType} = ?',
        whereArgs: [entityType],
        orderBy: '${DatabaseConstants.syncMetadataLastSync} DESC',
      );

      return maps.map((map) {
        final syncMetadataModel = SyncMetadataModel.fromJson(map);
        return syncMetadataModel.toEntity();
      }).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get sync metadata by type: $e');
    }
  }

  @override
  Future<List<SyncMetadata>> getConflictedSyncMetadata() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.syncMetadataTable,
        where: '${DatabaseConstants.syncMetadataConflictStatus} != ?',
        whereArgs: [_conflictStatusToString(ConflictStatus.none)],
        orderBy: '${DatabaseConstants.syncMetadataLastSync} DESC',
      );

      return maps.map((map) {
        final syncMetadataModel = SyncMetadataModel.fromJson(map);
        return syncMetadataModel.toEntity();
      }).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get conflicted sync metadata: $e');
    }
  }

  @override
  Future<List<SyncMetadata>> getOutdatedSyncMetadata(DateTime threshold) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.syncMetadataTable,
        where: '${DatabaseConstants.syncMetadataLastSync} < ?',
        whereArgs: [threshold.millisecondsSinceEpoch],
        orderBy: '${DatabaseConstants.syncMetadataLastSync} ASC',
      );

      return maps.map((map) {
        final syncMetadataModel = SyncMetadataModel.fromJson(map);
        return syncMetadataModel.toEntity();
      }).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get outdated sync metadata: $e');
    }
  }

  @override
  Future<List<SyncMetadata>> getConflictedEntities() async {
    return getConflictedSyncMetadata();
  }

  @override
  Future<List<SyncMetadata>> getPendingSyncEntities() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.syncMetadataTable,
        where: '${DatabaseConstants.syncMetadataLastSync} IS NULL',
      );

      return maps.map((map) {
        final syncMetadataModel = SyncMetadataModel.fromJson(map);
        return syncMetadataModel.toEntity();
      }).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get pending sync entities: $e');
    }
  }

  @override
  Future<void> saveSyncMetadata(SyncMetadata syncMetadata) async {
    try {
      final db = await _databaseHelper.database;
      final syncMetadataModel = SyncMetadataModel.fromEntity(syncMetadata);
      await db.insert(
        DatabaseConstants.syncMetadataTable,
        syncMetadataModel.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to save sync metadata: $e');
    }
  }

  @override
  Future<void> updateSyncMetadata(SyncMetadata syncMetadata) async {
    try {
      final db = await _databaseHelper.database;
      final syncMetadataModel = SyncMetadataModel.fromEntity(syncMetadata);
      final rowsAffected = await db.update(
        DatabaseConstants.syncMetadataTable,
        syncMetadataModel.toJson(),
        where: '${DatabaseConstants.syncMetadataId} = ?',
        whereArgs: [syncMetadata.id],
      );

      if (rowsAffected == 0) {
        throw app_exceptions.DatabaseException('Sync metadata not found for update');
      }
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to update sync metadata: $e');
    }
  }

  @override
  Future<void> deleteSyncMetadata(String id) async {
    try {
      final db = await _databaseHelper.database;
      final rowsAffected = await db.delete(
        DatabaseConstants.syncMetadataTable,
        where: '${DatabaseConstants.syncMetadataId} = ?',
        whereArgs: [id],
      );

      if (rowsAffected == 0) {
        throw app_exceptions.DatabaseException('Sync metadata not found for deletion');
      }
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to delete sync metadata: $e');
    }
  }

  @override
  Future<void> deleteSyncMetadataByEntity(String entityType, String entityId) async {
    try {
      final db = await _databaseHelper.database;
      await db.delete(
        DatabaseConstants.syncMetadataTable,
        where: '${DatabaseConstants.syncMetadataEntityType} = ? AND ${DatabaseConstants.syncMetadataEntityId} = ?',
        whereArgs: [entityType, entityId],
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to delete sync metadata by entity: $e');
    }
  }

  @override
  Future<void> clearAllSyncMetadata() async {
    try {
      final db = await _databaseHelper.database;
      await db.delete(DatabaseConstants.syncMetadataTable);
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to clear all sync metadata: $e');
    }
  }

  @override
  Stream<List<SyncMetadata>> watchSyncMetadata() {
    getAllSyncMetadata().then((metadata) => _syncMetadataStreamController.add(metadata));
    return _syncMetadataStreamController.stream;
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

  String _conflictStatusToString(ConflictStatus status) {
    switch (status) {
      case ConflictStatus.none:
        return 'none';
      case ConflictStatus.detected:
        return 'detected';
      case ConflictStatus.resolved:
        return 'resolved';
    }
  }

  void dispose() {
    _syncMetadataStreamController.close();
  }
}