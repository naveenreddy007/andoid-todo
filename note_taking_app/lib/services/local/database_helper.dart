import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:note_taking_app/core/constants/database_constants.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;
  final _databaseStreamController = StreamController<void>.broadcast();

  Stream<void> get databaseStream => _databaseStreamController.stream;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      return await openDatabase(
        inMemoryDatabasePath,
        version: DatabaseConstants.dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
      );
    }

    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    String path = join(await getDatabasesPath(), DatabaseConstants.dbName);
    print('Database path: $path');
    return await openDatabase(
      path,
      version: DatabaseConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _createIndexes(db);
    await _insertDefaultData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      await _dropTables(db);
      await _createTables(db);
      await _createIndexes(db);
      await _insertDefaultData(db);
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute(DatabaseConstants.createCategoriesTable);
    await db.execute(DatabaseConstants.createTagsTable);
    await db.execute(DatabaseConstants.createTodosTable);
    await db.execute(DatabaseConstants.createTodoTagsTable);
    await db.execute(DatabaseConstants.createRemindersTable);
    await db.execute(DatabaseConstants.createAttachmentsTable);
    await db.execute(DatabaseConstants.createSyncMetadataTable);
    await db.execute(DatabaseConstants.createGoogleDriveFilesTable);
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute(DatabaseConstants.idxTodosPriority);
    await db.execute(DatabaseConstants.idxTodosStatus);
    await db.execute(DatabaseConstants.idxTodosDueDate);
    await db.execute(DatabaseConstants.idxTodosIsDeleted);
    await db.execute(DatabaseConstants.idxRemindersDateTime);
    await db.execute(DatabaseConstants.idxRemindersTodoId);
  }

  Future<void> _insertDefaultData(Database db) async {
    // Insert default categories
    await db.insert(DatabaseConstants.categoriesTable, {
      DatabaseConstants.categoryId: 'personal',
      DatabaseConstants.categoryName: 'Personal',
      DatabaseConstants.categoryIcon: 'person',
      DatabaseConstants.categoryColor: '#2196F3',
      DatabaseConstants.categoryCreatedAt: DateTime.now().toIso8601String(),
    });

    await db.insert(DatabaseConstants.categoriesTable, {
      DatabaseConstants.categoryId: 'work',
      DatabaseConstants.categoryName: 'Work',
      DatabaseConstants.categoryIcon: 'work',
      DatabaseConstants.categoryColor: '#4CAF50',
      DatabaseConstants.categoryCreatedAt: DateTime.now().toIso8601String(),
    });

    await db.insert(DatabaseConstants.categoriesTable, {
      DatabaseConstants.categoryId: 'shopping',
      DatabaseConstants.categoryName: 'Shopping',
      DatabaseConstants.categoryIcon: 'shopping_cart',
      DatabaseConstants.categoryColor: '#FF9800',
      DatabaseConstants.categoryCreatedAt: DateTime.now().toIso8601String(),
    });

    await db.insert(DatabaseConstants.categoriesTable, {
      DatabaseConstants.categoryId: 'health',
      DatabaseConstants.categoryName: 'Health',
      DatabaseConstants.categoryIcon: 'favorite',
      DatabaseConstants.categoryColor: '#E91E63',
      DatabaseConstants.categoryCreatedAt: DateTime.now().toIso8601String(),
    });

    // Insert default tags
    await db.insert(DatabaseConstants.tagsTable, {
      DatabaseConstants.tagId: 'urgent',
      DatabaseConstants.tagName: 'Urgent',
      DatabaseConstants.tagColor: '#F44336',
      DatabaseConstants.tagCreatedAt: DateTime.now().toIso8601String(),
    });

    await db.insert(DatabaseConstants.tagsTable, {
      DatabaseConstants.tagId: 'important',
      DatabaseConstants.tagName: 'Important',
      DatabaseConstants.tagColor: '#FF5722',
      DatabaseConstants.tagCreatedAt: DateTime.now().toIso8601String(),
    });

    await db.insert(DatabaseConstants.tagsTable, {
      DatabaseConstants.tagId: 'quick',
      DatabaseConstants.tagName: 'Quick',
      DatabaseConstants.tagColor: '#4CAF50',
      DatabaseConstants.tagCreatedAt: DateTime.now().toIso8601String(),
    });

    await db.insert(DatabaseConstants.tagsTable, {
      DatabaseConstants.tagId: 'meeting',
      DatabaseConstants.tagName: 'Meeting',
      DatabaseConstants.tagColor: '#9C27B0',
      DatabaseConstants.tagCreatedAt: DateTime.now().toIso8601String(),
    });
  }

  Future<void> _dropTables(Database db) async {
    await db.execute('DROP TABLE IF EXISTS ${DatabaseConstants.googleDriveFilesTable}');
    await db.execute('DROP TABLE IF EXISTS ${DatabaseConstants.todoTagsTable}');
    await db.execute('DROP TABLE IF EXISTS ${DatabaseConstants.remindersTable}');
    await db.execute('DROP TABLE IF EXISTS ${DatabaseConstants.attachmentsTable}');
    await db.execute('DROP TABLE IF EXISTS ${DatabaseConstants.syncMetadataTable}');
    await db.execute('DROP TABLE IF EXISTS ${DatabaseConstants.todosTable}');
    await db.execute('DROP TABLE IF EXISTS ${DatabaseConstants.tagsTable}');
    await db.execute('DROP TABLE IF EXISTS ${DatabaseConstants.categoriesTable}');
  }

  Future<void> _createFtsTriggers(Database db) async {
    // FTS triggers not implemented yet
  }

  void notifyListeners() {
    print('🔔 DEBUG: DatabaseHelper.notifyListeners() called - broadcasting to stream');
    _databaseStreamController.add(null);
    print('📡 DEBUG: Stream notification sent');
  }

  // Basic CRUD operations for todos
  Future<String> insertTodo(Map<String, dynamic> todo) async {
    final db = await database;
    await db.insert(DatabaseConstants.todosTable, todo);
    notifyListeners();
    return todo[DatabaseConstants.todoId];
  }

  Future<Map<String, dynamic>?> getTodo(String id) async {
    final db = await database;
    final result = await db.query(
      DatabaseConstants.todosTable,
      where: '${DatabaseConstants.todoId} = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllTodos() async {
    final db = await database;
    return await db.query(
      DatabaseConstants.todosTable,
      where: '${DatabaseConstants.todoIsDeleted} = ?',
      whereArgs: [0],
      orderBy: '${DatabaseConstants.todoCreatedAt} DESC',
    );
  }

  Future<void> updateTodo(String id, Map<String, dynamic> todo) async {
    final db = await database;
    await db.update(
      DatabaseConstants.todosTable,
      todo,
      where: '${DatabaseConstants.todoId} = ?',
      whereArgs: [id],
    );
    notifyListeners();
  }

  Future<void> deleteTodo(String id) async {
    final db = await database;
    await db.update(
      DatabaseConstants.todosTable,
      {
        DatabaseConstants.todoIsDeleted: 1,
        DatabaseConstants.todoUpdatedAt: DateTime.now().toIso8601String(),
      },
      where: '${DatabaseConstants.todoId} = ?',
      whereArgs: [id],
    );
    notifyListeners();
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<void> clearAllData() async {
    final db = await database;
    final tables = [
      DatabaseConstants.syncMetadataTable,
      DatabaseConstants.attachmentsTable,
      DatabaseConstants.todoTagsTable,
      DatabaseConstants.remindersTable,
      DatabaseConstants.todosTable,
      DatabaseConstants.tagsTable,
      DatabaseConstants.categoriesTable,
    ];
    for (final table in tables) {
      await db.delete(table);
    }
    notifyListeners();
  }
}
