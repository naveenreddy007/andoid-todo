import 'dart:async';
import 'dart:io';

import 'package:sqflite/sqflite.dart';

import '../../core/constants/database_constants.dart';
import '../../core/errors/app_exceptions.dart' as app_exceptions;
import '../../domain/entities/attachment.dart';
import '../../domain/entities/todo.dart';
import '../../domain/repositories/attachment_repository.dart';
import '../../services/local/database_helper.dart';
import '../models/attachment_model.dart';

class LocalAttachmentRepository implements AttachmentRepository {
  final DatabaseHelper _databaseHelper;
  final _attachmentsStreamController = StreamController<List<Attachment>>.broadcast();

  LocalAttachmentRepository(this._databaseHelper) {
    _databaseHelper.databaseStream.listen((_) {
      getAllAttachments().then((attachments) => _attachmentsStreamController.add(attachments));
    });
  }

  @override
  Future<List<Attachment>> getAllAttachments() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.attachmentsTable,
        orderBy: '${DatabaseConstants.attachmentCreatedAt} DESC',
      );

      return maps.map((map) {
        final attachmentModel = AttachmentModel.fromJson(map);
        return attachmentModel.toEntity();
      }).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get all attachments: $e');
    }
  }

  @override
  Future<Attachment?> getAttachmentById(String id) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.attachmentsTable,
        where: '${DatabaseConstants.attachmentId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) return null;

      final attachmentModel = AttachmentModel.fromJson(maps.first);
      return attachmentModel.toEntity();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get attachment by id: $e');
    }
  }

  @override
  Future<List<Attachment>> getAttachmentsForTodo(String todoId) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.attachmentsTable,
        where: '${DatabaseConstants.attachmentTodoId} = ?',
        whereArgs: [todoId],
        orderBy: '${DatabaseConstants.attachmentCreatedAt} DESC',
      );

      return maps.map((map) {
        final attachmentModel = AttachmentModel.fromJson(map);
        return attachmentModel.toEntity();
      }).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get attachments for todo: $e');
    }
  }

  @override
  Future<void> saveAttachment(Attachment attachment) async {
    try {
      final db = await _databaseHelper.database;
      final attachmentModel = AttachmentModel.fromEntity(attachment);
      await db.insert(
        DatabaseConstants.attachmentsTable,
        attachmentModel.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to save attachment: $e');
    }
  }

  @override
  Future<void> updateAttachment(Attachment attachment) async {
    try {
      final db = await _databaseHelper.database;
      final attachmentModel = AttachmentModel.fromEntity(attachment);
      final rowsAffected = await db.update(
        DatabaseConstants.attachmentsTable,
        attachmentModel.toJson(),
        where: '${DatabaseConstants.attachmentId} = ?',
        whereArgs: [attachment.id],
      );

      if (rowsAffected == 0) {
        throw app_exceptions.DatabaseException('Attachment not found for update');
      }
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to update attachment: $e');
    }
  }

  @override
  Future<void> deleteAttachment(String id) async {
    try {
      final db = await _databaseHelper.database;
      final rowsAffected = await db.delete(
        DatabaseConstants.attachmentsTable,
        where: '${DatabaseConstants.attachmentId} = ?',
        whereArgs: [id],
      );

      if (rowsAffected == 0) {
        throw app_exceptions.DatabaseException('Attachment not found for deletion');
      }
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to delete attachment: $e');
    }
  }

  @override
  Future<void> deleteAllAttachmentsForTodo(String todoId) async {
    try {
      final db = await _databaseHelper.database;
      await db.delete(
        DatabaseConstants.attachmentsTable,
        where: '${DatabaseConstants.attachmentTodoId} = ?',
        whereArgs: [todoId],
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to delete attachments for todo: $e');
    }
  }

  @override
  Future<void> deleteAttachmentsForTodo(String todoId) async {
    return deleteAllAttachmentsForTodo(todoId);
  }

  @override
  Future<int> getTotalAttachmentSize() async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery(
        'SELECT SUM(${DatabaseConstants.attachmentFileSize}) as total_size FROM ${DatabaseConstants.attachmentsTable}',
      );

      return result.first['total_size'] as int? ?? 0;
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get total attachment size: $e');
    }
  }

  @override
  Stream<List<Attachment>> watchAttachments() {
    getAllAttachments().then((attachments) => _attachmentsStreamController.add(attachments));
    return _attachmentsStreamController.stream;
  }

  @override
  Stream<List<Attachment>> watchAttachmentsForTodo(String todoId) {
    getAttachmentsForTodo(todoId).then((attachments) => _attachmentsStreamController.add(attachments));
    return _attachmentsStreamController.stream;
  }

  @override
  Future<bool> isAttachmentAccessible(String attachmentId) async {
    try {
      final attachment = await getAttachmentById(attachmentId);
      if (attachment == null) return false;
      
      final file = File(attachment.filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<Attachment>> getAttachmentsDueForSync() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.attachmentsTable,
        orderBy: '${DatabaseConstants.attachmentCreatedAt} ASC',
      );

      return maps.map((map) {
        final attachmentModel = AttachmentModel.fromJson(map);
        return attachmentModel.toEntity();
      }).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get attachments due for sync: $e');
    }
  }

  void dispose() {
    _attachmentsStreamController.close();
  }
}