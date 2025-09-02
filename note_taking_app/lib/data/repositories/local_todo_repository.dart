import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../../core/constants/database_constants.dart';
import '../../core/errors/app_exceptions.dart' as app_exceptions;
import '../../domain/entities/todo.dart';
import '../../domain/entities/todo_status.dart';
import '../../domain/entities/priority.dart';
import '../../domain/repositories/todo_repository.dart';
import '../../services/local/database_helper.dart';
import '../models/todo_model.dart';

class LocalTodoRepository implements TodoRepository {
  final DatabaseHelper _databaseHelper;
  final _todosStreamController = StreamController<List<Todo>>.broadcast();

  LocalTodoRepository(this._databaseHelper) {
    // Load initial data
    getAllTodos().then((todos) {
      print('🔄 LocalTodoRepository: Loading initial todos, count: ${todos.length}');
      _todosStreamController.add(todos);
    });
    
    // Listen for database changes
    _databaseHelper.databaseStream.listen((_) {
      getAllTodos().then((todos) {
        print('🔄 LocalTodoRepository: Database changed, reloading todos, count: ${todos.length}');
        _todosStreamController.add(todos);
      });
    });
  }

  @override
  Stream<List<Todo>> watchTodos() {
    print('👀 DEBUG: watchTodos() called - returning stream');
    return _todosStreamController.stream;
  }

  @override
  Future<List<Todo>> getAllTodos({bool includeDeleted = false}) async {
    try {
      final db = await _databaseHelper.database;
      final whereClause = includeDeleted ? null : '${DatabaseConstants.todoIsDeleted} = ?';
      final whereArgs = includeDeleted ? null : [0];
      
      final maps = await db.query(
        DatabaseConstants.todosTable,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: '${DatabaseConstants.todoUpdatedAt} DESC',
      );

      final todos = <Todo>[];
      for (final map in maps) {
        final todoModel = TodoModel.fromJson(map);
        final tagIds = await _getTagIdsForTodo(todoModel.id);
        final attachmentIds = await _getAttachmentIdsForTodo(todoModel.id);
        final reminderIds = await _getReminderIdsForTodo(todoModel.id);
        todos.add(
          todoModel.toEntity(tagIds: tagIds, attachmentIds: attachmentIds, reminderIds: reminderIds),
        );
      }

      return todos;
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get all todos: $e');
    }
  }

  @override
  Future<Todo?> getTodoById(String id) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.todosTable,
        where: '${DatabaseConstants.todoId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) return null;

      final todoModel = TodoModel.fromJson(maps.first);
      final tagIds = await _getTagIdsForTodo(todoModel.id);
      final attachmentIds = await _getAttachmentIdsForTodo(todoModel.id);
      final reminderIds = await _getReminderIdsForTodo(todoModel.id);

      return todoModel.toEntity(tagIds: tagIds, attachmentIds: attachmentIds, reminderIds: reminderIds);
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get todo by id: $e');
    }
  }

  @override
  Future<void> saveTodo(Todo todo) async {
    print('💾 DEBUG: LocalTodoRepository.saveTodo called - ID: ${todo.id}, Title: "${todo.title}"');
    try {
      final db = await _databaseHelper.database;
      print('🗄️ DEBUG: Got database instance');
      
      await db.transaction((txn) async {
        final todoModel = TodoModel.fromEntity(todo);
        print('🔄 DEBUG: Created TodoModel from entity');

        // Insert or update todo
        final result = await txn.insert(
          DatabaseConstants.todosTable,
          todoModel.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print('✅ DEBUG: Inserted todo into database, result: $result');

        // Handle tags
        await _saveTodoTags(txn, todo.id, todo.tagIds);
        print('🏷️ DEBUG: Saved todo tags: ${todo.tagIds}');
      });
      
      // Notify listeners after transaction completes
      print('🔔 DEBUG: Calling notifyListeners()');
      _databaseHelper.notifyListeners();
      print('✅ DEBUG: LocalTodoRepository.saveTodo completed successfully');
    } catch (e) {
      print('❌ DEBUG: LocalTodoRepository.saveTodo error: $e');
      throw app_exceptions.DatabaseException('Failed to save todo: $e');
    }
  }

  @override
  Future<void> updateTodo(Todo todo) async {
    try {
      final db = await _databaseHelper.database;
      await db.transaction((txn) async {
        final todoModel = TodoModel.fromEntity(todo);

        // Update todo
        final rowsAffected = await txn.update(
          DatabaseConstants.todosTable,
          todoModel.toJson(),
          where: '${DatabaseConstants.todoId} = ?',
          whereArgs: [todo.id],
        );

        if (rowsAffected == 0) {
          throw app_exceptions.DatabaseException('Todo not found for update');
        }

        // Handle tags
        await _saveTodoTags(txn, todo.id, todo.tagIds);
      });
      
      // Notify listeners after transaction completes
      _databaseHelper.notifyListeners();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to update todo: $e');
    }
  }

  @override
  Future<void> deleteTodo(String id, {bool permanent = false}) async {
    try {
      final db = await _databaseHelper.database;
      
      if (permanent) {
        // Permanently delete the todo
        final rowsAffected = await db.delete(
          DatabaseConstants.todosTable,
          where: '${DatabaseConstants.todoId} = ?',
          whereArgs: [id],
        );

        if (rowsAffected == 0) {
          throw app_exceptions.DatabaseException('Todo not found for deletion');
        }
      } else {
        // Soft delete
        final rowsAffected = await db.update(
          DatabaseConstants.todosTable,
          {
            DatabaseConstants.todoIsDeleted: 1,
            DatabaseConstants.todoUpdatedAt: DateTime.now().toIso8601String(),
          },
          where: '${DatabaseConstants.todoId} = ?',
          whereArgs: [id],
        );

        if (rowsAffected == 0) {
          throw app_exceptions.DatabaseException('Todo not found for deletion');
        }
      }
      
      // Notify listeners after operation completes
      _databaseHelper.notifyListeners();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to delete todo: $e');
    }
  }

  @override
  Future<List<Todo>> getTodosByStatus(TodoStatus status) async {
    try {
      final db = await _databaseHelper.database;
      final statusString = _statusToString(status);
      final maps = await db.query(
        DatabaseConstants.todosTable,
        where:
            '${DatabaseConstants.todoStatus} = ? AND ${DatabaseConstants.todoIsDeleted} = ?',
        whereArgs: [statusString, 0],
        orderBy: '${DatabaseConstants.todoUpdatedAt} DESC',
      );

      final todos = <Todo>[];
      for (final map in maps) {
        final todoModel = TodoModel.fromJson(map);
        final tagIds = await _getTagIdsForTodo(todoModel.id);
        final attachmentIds = await _getAttachmentIdsForTodo(todoModel.id);
        final reminderIds = await _getReminderIdsForTodo(todoModel.id);
        todos.add(
          todoModel.toEntity(tagIds: tagIds, attachmentIds: attachmentIds, reminderIds: reminderIds),
        );
      }

      return todos;
    } catch (e) {
      throw app_exceptions.DatabaseException(
        'Failed to get todos by status: $e',
      );
    }
  }

  @override
  Future<List<Todo>> getTodosByCategory(String categoryId) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.todosTable,
        where:
            '${DatabaseConstants.todoCategoryId} = ? AND ${DatabaseConstants.todoIsDeleted} = ?',
        whereArgs: [categoryId, 0],
        orderBy: '${DatabaseConstants.todoUpdatedAt} DESC',
      );

      final todos = <Todo>[];
      for (final map in maps) {
        final todoModel = TodoModel.fromJson(map);
        final tagIds = await _getTagIdsForTodo(todoModel.id);
        final attachmentIds = await _getAttachmentIdsForTodo(todoModel.id);
        final reminderIds = await _getReminderIdsForTodo(todoModel.id);
        todos.add(
          todoModel.toEntity(tagIds: tagIds, attachmentIds: attachmentIds, reminderIds: reminderIds),
        );
      }

      return todos;
    } catch (e) {
      throw app_exceptions.DatabaseException(
        'Failed to get todos by category: $e',
      );
    }
  }

  @override
  Future<List<Todo>> getTodosByTag(String tagId) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.rawQuery(
        '''
        SELECT t.* FROM ${DatabaseConstants.todosTable} t
        INNER JOIN ${DatabaseConstants.todoTagsTable} tt ON t.${DatabaseConstants.todoId} = tt.${DatabaseConstants.todoTagTodoId}
        WHERE tt.${DatabaseConstants.todoTagTagId} = ? AND t.${DatabaseConstants.todoIsDeleted} = ?
        ORDER BY t.${DatabaseConstants.todoUpdatedAt} DESC
      ''',
        [tagId, 0],
      );

      final todos = <Todo>[];
      for (final map in maps) {
        final todoModel = TodoModel.fromJson(map);
        final tagIds = await _getTagIdsForTodo(todoModel.id);
        final attachmentIds = await _getAttachmentIdsForTodo(todoModel.id);
        final reminderIds = await _getReminderIdsForTodo(todoModel.id);
        todos.add(
          todoModel.toEntity(tagIds: tagIds, attachmentIds: attachmentIds, reminderIds: reminderIds),
        );
      }

      return todos;
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get todos by tag: $e');
    }
  }

  @override
  Future<List<Todo>> getTodosByPriority(Priority priority) async {
    try {
      final db = await _databaseHelper.database;
      final priorityString = _priorityToString(priority);
      final maps = await db.query(
        DatabaseConstants.todosTable,
        where:
            '${DatabaseConstants.todoPriority} = ? AND ${DatabaseConstants.todoIsDeleted} = ?',
        whereArgs: [priorityString, 0],
        orderBy: '${DatabaseConstants.todoUpdatedAt} DESC',
      );

      final todos = <Todo>[];
      for (final map in maps) {
        final todoModel = TodoModel.fromJson(map);
        final tagIds = await _getTagIdsForTodo(todoModel.id);
        final attachmentIds = await _getAttachmentIdsForTodo(todoModel.id);
        final reminderIds = await _getReminderIdsForTodo(todoModel.id);
        todos.add(
          todoModel.toEntity(tagIds: tagIds, attachmentIds: attachmentIds, reminderIds: reminderIds),
        );
      }

      return todos;
    } catch (e) {
      throw app_exceptions.DatabaseException(
        'Failed to get todos by priority: $e',
      );
    }
  }

  @override
  Future<List<Todo>> getTodosDueToday() async {
    try {
      final db = await _databaseHelper.database;
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final maps = await db.query(
        DatabaseConstants.todosTable,
        where:
            '${DatabaseConstants.todoDueDate} >= ? AND ${DatabaseConstants.todoDueDate} < ? AND ${DatabaseConstants.todoIsDeleted} = ?',
        whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String(), 0],
        orderBy: '${DatabaseConstants.todoDueDate} ASC',
      );

      final todos = <Todo>[];
      for (final map in maps) {
        final todoModel = TodoModel.fromJson(map);
        final tagIds = await _getTagIdsForTodo(todoModel.id);
        final attachmentIds = await _getAttachmentIdsForTodo(todoModel.id);
        final reminderIds = await _getReminderIdsForTodo(todoModel.id);
        todos.add(
          todoModel.toEntity(tagIds: tagIds, attachmentIds: attachmentIds, reminderIds: reminderIds),
        );
      }

      return todos;
    } catch (e) {
      throw app_exceptions.DatabaseException(
        'Failed to get todos due today: $e',
      );
    }
  }

  @override
  Future<List<Todo>> getOverdueTodos() async {
    try {
      final db = await _databaseHelper.database;
      final now = DateTime.now().toIso8601String();
      
      final maps = await db.query(
        DatabaseConstants.todosTable,
        where:
            '${DatabaseConstants.todoDueDate} < ? AND ${DatabaseConstants.todoStatus} != ? AND ${DatabaseConstants.todoIsDeleted} = ?',
        whereArgs: [now, _statusToString(TodoStatus.completed), 0],
        orderBy: '${DatabaseConstants.todoDueDate} ASC',
      );

      final todos = <Todo>[];
      for (final map in maps) {
        final todoModel = TodoModel.fromJson(map);
        final tagIds = await _getTagIdsForTodo(todoModel.id);
        final attachmentIds = await _getAttachmentIdsForTodo(todoModel.id);
        final reminderIds = await _getReminderIdsForTodo(todoModel.id);
        todos.add(
          todoModel.toEntity(tagIds: tagIds, attachmentIds: attachmentIds, reminderIds: reminderIds),
        );
      }

      return todos;
    } catch (e) {
      throw app_exceptions.DatabaseException(
        'Failed to get overdue todos: $e',
      );
    }
  }

  @override
  Future<List<Todo>> getTodosDueForSync() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.todosTable,
        where: '${DatabaseConstants.todoSyncStatus} = ?',
        whereArgs: [_syncStatusToString(SyncStatus.pending)],
        orderBy: '${DatabaseConstants.todoUpdatedAt} DESC',
      );

      final todos = <Todo>[];
      for (final map in maps) {
        final todoModel = TodoModel.fromJson(map);
        final tagIds = await _getTagIdsForTodo(todoModel.id);
        final attachmentIds = await _getAttachmentIdsForTodo(todoModel.id);
        final reminderIds = await _getReminderIdsForTodo(todoModel.id);
        todos.add(
          todoModel.toEntity(tagIds: tagIds, attachmentIds: attachmentIds, reminderIds: reminderIds),
        );
      }

      return todos;
    } catch (e) {
      throw app_exceptions.DatabaseException(
        'Failed to get todos due for sync: $e',
      );
    }
  }

  @override
  Future<void> completeTodo(String id) async {
    try {
      final db = await _databaseHelper.database;
      final rowsAffected = await db.update(
        DatabaseConstants.todosTable,
        {
          DatabaseConstants.todoStatus: _statusToString(TodoStatus.completed),
          DatabaseConstants.todoUpdatedAt: DateTime.now().toIso8601String(),
        },
        where: '${DatabaseConstants.todoId} = ?',
        whereArgs: [id],
      );

      if (rowsAffected == 0) {
        throw app_exceptions.DatabaseException('Todo not found for completion');
      }
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to complete todo: $e');
    }
  }

  @override
  Future<void> markTodoInProgress(String id) async {
    try {
      final db = await _databaseHelper.database;
      final rowsAffected = await db.update(
        DatabaseConstants.todosTable,
        {
          DatabaseConstants.todoStatus: _statusToString(TodoStatus.inProgress),
          DatabaseConstants.todoUpdatedAt: DateTime.now().toIso8601String(),
        },
        where: '${DatabaseConstants.todoId} = ?',
        whereArgs: [id],
      );

      if (rowsAffected == 0) {
        throw app_exceptions.DatabaseException('Todo not found for status update');
      }
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to mark todo in progress: $e');
    }
  }

  @override
  Future<List<Todo>> getDeletedTodos() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.todosTable,
        where: '${DatabaseConstants.todoIsDeleted} = ?',
        whereArgs: [1],
        orderBy: '${DatabaseConstants.todoUpdatedAt} DESC',
      );

      final todos = <Todo>[];
      for (final map in maps) {
        final todoModel = TodoModel.fromJson(map);
        final tagIds = await _getTagIdsForTodo(todoModel.id);
        final attachmentIds = await _getAttachmentIdsForTodo(todoModel.id);
        final reminderIds = await _getReminderIdsForTodo(todoModel.id);
        todos.add(
          todoModel.toEntity(tagIds: tagIds, attachmentIds: attachmentIds, reminderIds: reminderIds),
        );
      }

      return todos;
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get deleted todos: $e');
    }
  }

  @override
  Future<List<Todo>> getTodosWithReminders() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.rawQuery(
        '''
        SELECT DISTINCT t.* FROM ${DatabaseConstants.todosTable} t
        INNER JOIN ${DatabaseConstants.remindersTable} r ON t.${DatabaseConstants.todoId} = r.${DatabaseConstants.reminderTodoId}
        WHERE t.${DatabaseConstants.todoIsDeleted} = ?
        ORDER BY t.${DatabaseConstants.todoUpdatedAt} DESC
      ''',
        [0],
      );

      final todos = <Todo>[];
      for (final map in maps) {
        final todoModel = TodoModel.fromJson(map);
        final tagIds = await _getTagIdsForTodo(todoModel.id);
        final attachmentIds = await _getAttachmentIdsForTodo(todoModel.id);
        final reminderIds = await _getReminderIdsForTodo(todoModel.id);
        todos.add(
          todoModel.toEntity(tagIds: tagIds, attachmentIds: attachmentIds, reminderIds: reminderIds),
        );
      }

      return todos;
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get todos with reminders: $e');
    }
  }

  // Private helper methods
  Future<List<String>> _getTagIdsForTodo(String todoId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DatabaseConstants.todoTagsTable,
      columns: [DatabaseConstants.todoTagTagId],
      where: '${DatabaseConstants.todoTagTodoId} = ?',
      whereArgs: [todoId],
    );

    return maps
        .map((map) => map[DatabaseConstants.todoTagTagId] as String)
        .toList();
  }

  Future<List<String>> _getAttachmentIdsForTodo(String todoId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DatabaseConstants.attachmentsTable,
      columns: [DatabaseConstants.attachmentId],
      where: '${DatabaseConstants.attachmentTodoId} = ?',
      whereArgs: [todoId],
    );

    return maps
        .map((map) => map[DatabaseConstants.attachmentId] as String)
        .toList();
  }

  Future<List<String>> _getReminderIdsForTodo(String todoId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DatabaseConstants.remindersTable,
      columns: [DatabaseConstants.reminderId],
      where: '${DatabaseConstants.reminderTodoId} = ?',
      whereArgs: [todoId],
    );

    return maps
        .map((map) => map[DatabaseConstants.reminderId] as String)
        .toList();
  }

  Future<void> _saveTodoTags(
    Transaction txn,
    String todoId,
    List<String> tagIds,
  ) async {
    // Delete existing tags for this todo
    await txn.delete(
      DatabaseConstants.todoTagsTable,
      where: '${DatabaseConstants.todoTagTodoId} = ?',
      whereArgs: [todoId],
    );

    // Insert new tags
    for (final tagId in tagIds) {
      await txn.insert(DatabaseConstants.todoTagsTable, {
        DatabaseConstants.todoTagTodoId: todoId,
        DatabaseConstants.todoTagTagId: tagId,
      });
    }
  }

  String _statusToString(TodoStatus status) {
    switch (status) {
      case TodoStatus.pending:
        return 'pending';
      case TodoStatus.inProgress:
        return 'in_progress';
      case TodoStatus.completed:
        return 'completed';
      case TodoStatus.cancelled:
        return 'cancelled';
    }
  }

  String _priorityToString(Priority priority) {
    switch (priority) {
      case Priority.low:
        return 'low';
      case Priority.medium:
        return 'medium';
      case Priority.high:
        return 'high';
      case Priority.urgent:
        return 'urgent';
    }
  }

  String _syncStatusToString(SyncStatus syncStatus) {
    switch (syncStatus) {
      case SyncStatus.pending:
        return 'pending';
      case SyncStatus.synced:
        return 'synced';
      case SyncStatus.failed:
        return 'failed';
      case SyncStatus.conflict:
        return 'conflict';
    }
  }

  void dispose() {
    _todosStreamController.close();
  }
}
