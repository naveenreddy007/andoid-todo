import 'dart:async';

import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../../core/constants/database_constants.dart';
import '../../core/errors/app_exceptions.dart' as app_exceptions;
import '../../domain/entities/tag.dart';
import '../../domain/repositories/tag_repository.dart';
import '../../services/local/database_helper.dart';
import '../models/tag_model.dart';

class LocalTagRepository implements TagRepository {
  final DatabaseHelper _databaseHelper;

  LocalTagRepository(this._databaseHelper);

  @override
  Future<List<Tag>> getAllTags() async {
    try {
      final maps = await _databaseHelper.query(
        DatabaseConstants.tagsTable,
        orderBy: '${DatabaseConstants.tagName} ASC',
      );

      return maps.map((map) {
        final tagModel = TagModel.fromJson(map);
        return tagModel.toEntity();
      }).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get all tags: $e');
    }
  }

  @override
  Future<Tag?> getTagById(String id) async {
    try {
      final maps = await _databaseHelper.query(
        DatabaseConstants.tagsTable,
        where: '${DatabaseConstants.tagId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) return null;

      final tagModel = TagModel.fromJson(maps.first);
      return tagModel.toEntity();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get tag by id: $e');
    }
  }

  @override
  Future<Tag?> getTagByName(String name) async {
    try {
      final maps = await _databaseHelper.query(
        DatabaseConstants.tagsTable,
        where: '${DatabaseConstants.tagName} = ?',
        whereArgs: [name],
        limit: 1,
      );

      if (maps.isEmpty) return null;

      final tagModel = TagModel.fromJson(maps.first);
      return tagModel.toEntity();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get tag by name: $e');
    }
  }

  @override
  Future<void> saveTag(Tag tag) async {
    try {
      final tagModel = TagModel.fromEntity(tag);
      await _databaseHelper.insert(
        DatabaseConstants.tagsTable,
        tagModel.toJson(),
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to save tag: $e');
    }
  }

  @override
  Future<void> updateTag(Tag tag) async {
    try {
      final tagModel = TagModel.fromEntity(tag);
      final rowsAffected = await _databaseHelper.update(
        DatabaseConstants.tagsTable,
        tagModel.toJson(),
        where: '${DatabaseConstants.tagId} = ?',
        whereArgs: [tag.id],
      );

      if (rowsAffected == 0) {
        throw app_exceptions.DatabaseException('Tag not found for update');
      }
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to update tag: $e');
    }
  }

  @override
  Future<void> deleteTag(String id) async {
    try {
      final rowsAffected = await _databaseHelper.delete(
        DatabaseConstants.tagsTable,
        where: '${DatabaseConstants.tagId} = ?',
        whereArgs: [id],
      );

      if (rowsAffected == 0) {
        throw app_exceptions.DatabaseException('Tag not found for deletion');
      }
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to delete tag: $e');
    }
  }

  @override
  Stream<List<Tag>> watchTags() {
    late StreamController<List<Tag>> controller;
    Timer? timer;

    controller = StreamController<List<Tag>>(
      onListen: () {
        _loadAndEmitTags(controller);
        timer = Timer.periodic(const Duration(seconds: 2), (_) {
          _loadAndEmitTags(controller);
        });
      },
      onCancel: () {
        timer?.cancel();
      },
    );

    return controller.stream;
  }

  void _loadAndEmitTags(StreamController<List<Tag>> controller) {
    getAllTags()
        .then((tags) {
          if (!controller.isClosed) {
            controller.add(tags);
          }
        })
        .catchError((error) {
          if (!controller.isClosed) {
            controller.addError(error);
          }
        });
  }

  @override
  Future<List<Tag>> getTagsForNote(String noteId) async {
    try {
      final maps = await _databaseHelper.rawQuery(
        '''
        SELECT t.* FROM ${DatabaseConstants.tagsTable} t
        INNER JOIN ${DatabaseConstants.noteTagsTable} nt ON t.${DatabaseConstants.tagId} = nt.${DatabaseConstants.noteTagTagId}
        WHERE nt.${DatabaseConstants.noteTagNoteId} = ?
        ORDER BY t.${DatabaseConstants.tagName} ASC
      ''',
        [noteId],
      );

      return maps.map((map) {
        final tagModel = TagModel.fromJson(map);
        return tagModel.toEntity();
      }).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get tags for note: $e');
    }
  }

  @override
  Future<void> addTagToNote(String noteId, String tagId) async {
    try {
      await _databaseHelper.insert(DatabaseConstants.noteTagsTable, {
        DatabaseConstants.noteTagNoteId: noteId,
        DatabaseConstants.noteTagTagId: tagId,
      });
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to add tag to note: $e');
    }
  }

  @override
  Future<void> removeTagFromNote(String noteId, String tagId) async {
    try {
      await _databaseHelper.delete(
        DatabaseConstants.noteTagsTable,
        where:
            '${DatabaseConstants.noteTagNoteId} = ? AND ${DatabaseConstants.noteTagTagId} = ?',
        whereArgs: [noteId, tagId],
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to remove tag from note: $e');
    }
  }

  @override
  Future<List<Tag>> getPopularTags(int limit) async {
    try {
      final maps = await _databaseHelper.rawQuery(
        '''
        SELECT t.*, COUNT(nt.${DatabaseConstants.noteTagTagId}) as usage_count
        FROM ${DatabaseConstants.tagsTable} t
        LEFT JOIN ${DatabaseConstants.noteTagsTable} nt ON t.${DatabaseConstants.tagId} = nt.${DatabaseConstants.noteTagTagId}
        GROUP BY t.${DatabaseConstants.tagId}
        ORDER BY usage_count DESC, t.${DatabaseConstants.tagName} ASC
        LIMIT ?
      ''',
        [limit],
      );

      return maps.map((map) {
        final tagModel = TagModel.fromJson(map);
        return tagModel.toEntity();
      }).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get popular tags: $e');
    }
  }
}
