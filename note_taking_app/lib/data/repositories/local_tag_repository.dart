import 'dart:async';
import 'dart:developer' as developer;

import 'package:sqflite/sqflite.dart';

import '../../core/constants/database_constants.dart';
import '../../core/errors/app_exceptions.dart' as app_exceptions;
import '../../domain/entities/tag.dart';
import '../../domain/entities/todo.dart';
import '../../domain/repositories/tag_repository.dart';
import '../../services/local/database_helper.dart';
import '../models/tag_model.dart';

class LocalTagRepository implements TagRepository {
  final DatabaseHelper _databaseHelper;
  final _tagsStreamController = StreamController<List<Tag>>.broadcast();

  LocalTagRepository(this._databaseHelper) {
    _databaseHelper.databaseStream.listen((_) {
      getAllTags().then((tags) => _tagsStreamController.add(tags));
    });
  }

  @override
  Future<List<Tag>> getAllTags() async {
    try {
      developer.log('🏷️ Getting all tags from database', name: 'TagRepository');
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.tagsTable,
        orderBy: '${DatabaseConstants.tagName} ASC',
      );

      developer.log('🏷️ Found ${maps.length} tags in database', name: 'TagRepository');
      final tags = maps.map((map) {
        final tagModel = TagModel.fromJson(map);
        return tagModel.toEntity();
      }).toList();
      
      for (final tag in tags) {
        developer.log('🏷️ Tag: ${tag.name} (${tag.id}) - Color: ${tag.color}', name: 'TagRepository');
      }
      
      return tags;
    } catch (e) {
      developer.log('❌ Failed to get all tags: $e', name: 'TagRepository');
      throw app_exceptions.DatabaseException('Failed to get all tags: $e');
    }
  }

  @override
  Future<Tag?> getTagById(String id) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
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
      final db = await _databaseHelper.database;
      final maps = await db.query(
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
      developer.log('💾 Saving tag: ${tag.name} (${tag.id}) - Color: ${tag.color}', name: 'TagRepository');
      final db = await _databaseHelper.database;
      final tagModel = TagModel.fromEntity(tag);
      final tagData = tagModel.toJson();
      developer.log('💾 Tag data to save: $tagData', name: 'TagRepository');
      
      await db.insert(
        DatabaseConstants.tagsTable,
        tagData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      developer.log('✅ Tag saved successfully: ${tag.name}', name: 'TagRepository');
      
      // Notify listeners about the database change
      _databaseHelper.notifyListeners();
      // Also update the stream immediately
      final updatedTags = await getAllTags();
      _tagsStreamController.add(updatedTags);
    } catch (e) {
      developer.log('❌ Failed to save tag: $e', name: 'TagRepository');
      throw app_exceptions.DatabaseException('Failed to save tag: $e');
    }
  }

  @override
  Future<void> updateTag(Tag tag) async {
    try {
      final db = await _databaseHelper.database;
      final tagModel = TagModel.fromEntity(tag);
      final rowsAffected = await db.update(
        DatabaseConstants.tagsTable,
        tagModel.toJson(),
        where: '${DatabaseConstants.tagId} = ?',
        whereArgs: [tag.id],
      );

      if (rowsAffected == 0) {
        throw app_exceptions.DatabaseException('Tag not found for update');
      }
      
      // Notify listeners about the database change
      _databaseHelper.notifyListeners();
      // Also update the stream immediately
      final updatedTags = await getAllTags();
      _tagsStreamController.add(updatedTags);
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to update tag: $e');
    }
  }

  @override
  Future<void> deleteTag(String id) async {
    try {
      final db = await _databaseHelper.database;
      final rowsAffected = await db.delete(
        DatabaseConstants.tagsTable,
        where: '${DatabaseConstants.tagId} = ?',
        whereArgs: [id],
      );

      if (rowsAffected == 0) {
        throw app_exceptions.DatabaseException('Tag not found for deletion');
      }
      
      // Notify listeners about the database change
      _databaseHelper.notifyListeners();
      // Also update the stream immediately
      final updatedTags = await getAllTags();
      _tagsStreamController.add(updatedTags);
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to delete tag: $e');
    }
  }

  @override
  Stream<List<Tag>> watchTags() {
    getAllTags().then((tags) => _tagsStreamController.add(tags));
    return _tagsStreamController.stream;
  }

  @override
  Future<List<Tag>> getTagsForTodo(String todoId) async {
    try {
      developer.log('🔍 Getting tags for todo: $todoId', name: 'TagRepository');
      final db = await _databaseHelper.database;
      final maps = await db.rawQuery(
        '''
        SELECT t.* FROM ${DatabaseConstants.tagsTable} t
        INNER JOIN ${DatabaseConstants.todoTagsTable} tt ON t.${DatabaseConstants.tagId} = tt.${DatabaseConstants.todoTagTagId}
        WHERE tt.${DatabaseConstants.todoTagTodoId} = ?
        ORDER BY t.${DatabaseConstants.tagName} ASC
      ''',
        [todoId],
      );

      developer.log('🔍 Found ${maps.length} tags for todo $todoId', name: 'TagRepository');
      final tags = maps.map((map) {
        final tagModel = TagModel.fromJson(map);
        return tagModel.toEntity();
      }).toList();
      
      for (final tag in tags) {
        developer.log('🔍 Todo tag: ${tag.name} (${tag.id})', name: 'TagRepository');
      }
      
      return tags;
    } catch (e) {
      developer.log('❌ Failed to get tags for todo: $e', name: 'TagRepository');
      throw app_exceptions.DatabaseException('Failed to get tags for todo: $e');
    }
  }

  @override
  Future<void> addTagToTodo(String todoId, String tagId) async {
    try {
      developer.log('🔗 Adding tag $tagId to todo $todoId', name: 'TagRepository');
      final db = await _databaseHelper.database;
      await db.insert(DatabaseConstants.todoTagsTable, {
        DatabaseConstants.todoTagTodoId: todoId,
        DatabaseConstants.todoTagTagId: tagId,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      developer.log('✅ Tag successfully added to todo', name: 'TagRepository');
    } catch (e) {
      developer.log('❌ Failed to add tag to todo: $e', name: 'TagRepository');
      throw app_exceptions.DatabaseException('Failed to add tag to todo: $e');
    }
  }

  @override
  Future<void> removeTagFromTodo(String todoId, String tagId) async {
    try {
      developer.log('🔗 Removing tag $tagId from todo $todoId', name: 'TagRepository');
      final db = await _databaseHelper.database;
      final rowsAffected = await db.delete(
        DatabaseConstants.todoTagsTable,
        where:
            '${DatabaseConstants.todoTagTodoId} = ? AND ${DatabaseConstants.todoTagTagId} = ?',
        whereArgs: [todoId, tagId],
      );
      developer.log('✅ Removed tag from todo, rows affected: $rowsAffected', name: 'TagRepository');
    } catch (e) {
      developer.log('❌ Failed to remove tag from todo: $e', name: 'TagRepository');
      throw app_exceptions.DatabaseException('Failed to remove tag from todo: $e');
    }
  }

  @override
  Future<List<Tag>> getPopularTags(int limit) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.rawQuery(
        '''
        SELECT t.*, COUNT(tt.${DatabaseConstants.todoTagTagId}) as usage_count
        FROM ${DatabaseConstants.tagsTable} t
        LEFT JOIN ${DatabaseConstants.todoTagsTable} tt ON t.${DatabaseConstants.tagId} = tt.${DatabaseConstants.todoTagTagId}
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

  @override
  Future<List<Tag>> getTagsDueForSync() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.tagsTable,
        orderBy: '${DatabaseConstants.tagCreatedAt} ASC',
      );

      return maps.map((map) {
        final tagModel = TagModel.fromJson(map);
        return tagModel.toEntity();
      }).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get tags due for sync: $e');
    }
  }

  @override
  Future<int> getTodoCountByTag(String tagId) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery(
        '''
        SELECT COUNT(*) as count
        FROM ${DatabaseConstants.todoTagsTable}
        WHERE ${DatabaseConstants.todoTagTagId} = ?
      ''',
        [tagId],
      );

      return result.first['count'] as int;
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get todo count by tag: $e');
    }
  }

  @override
  Future<bool> isTagInUse(String tagId) async {
    try {
      final count = await getTodoCountByTag(tagId);
      return count > 0;
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to check if tag is in use: $e');
    }
  }

  void dispose() {
    _tagsStreamController.close();
  }
}
