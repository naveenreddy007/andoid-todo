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
    await _createFtsTriggers(db);
    await _insertDefaultData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      await _dropTables(db);
      await _createTables(db);
      await _createIndexes(db);
      await _createFtsTriggers(db);
      await _insertDefaultData(db);
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute(DatabaseConstants.createCategoriesTable);
    await db.execute(DatabaseConstants.createTagsTable);
    await db.execute(DatabaseConstants.createNotesTable);
    await db.execute(DatabaseConstants.createNoteTagsTable);
    await db.execute(DatabaseConstants.createAttachmentsTable);
    await db.execute(DatabaseConstants.createSyncMetadataTable);
    await db.execute(DatabaseConstants.createNotesSearchTable);
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute(DatabaseConstants.idxNotesUpdatedAt);
    await db.execute(DatabaseConstants.idxNotesReminderDate);
    await db.execute(DatabaseConstants.idxNotesCategory);
    await db.execute(DatabaseConstants.idxNotesSyncStatus);
    await db.execute(DatabaseConstants.idxSyncMetadataEntity);
    await db.execute(DatabaseConstants.idxNotesPriority);
    await db.execute(DatabaseConstants.idxNotesIsArchived);
    await db.execute(DatabaseConstants.idxNotesIsDeleted);
    await db.execute(DatabaseConstants.idxNotesSearchTitle);
    await db.execute(DatabaseConstants.idxNotesSearchContent);
    await db.execute(DatabaseConstants.idxNotesSearchNoteId);
  }

  Future<void> _insertDefaultData(Database db) async {
    await db.insert(DatabaseConstants.categoriesTable, {
      'id': 'personal',
      'name': 'Personal',
      'icon': 'person',
      'color': '#2196F3',
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert(DatabaseConstants.categoriesTable, {
      'id': 'work',
      'name': 'Work',
      'icon': 'work',
      'color': '#4CAF50',
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert(DatabaseConstants.categoriesTable, {
      'id': 'ideas',
      'name': 'Ideas',
      'icon': 'lightbulb',
      'color': '#FF9800',
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert(DatabaseConstants.tagsTable, {
      'id': 'important',
      'name': 'Important',
      'color': '#F44336',
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert(DatabaseConstants.tagsTable, {
      'id': 'todo',
      'name': 'Todo',
      'color': '#9C27B0',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _dropTables(Database db) async {
    await db.execute(
      'DROP TABLE IF EXISTS ${DatabaseConstants.notesSearchTable}',
    );
    await db.execute(
      'DROP TABLE IF EXISTS ${DatabaseConstants.syncMetadataTable}',
    );
    await db.execute(
      'DROP TABLE IF EXISTS ${DatabaseConstants.attachmentsTable}',
    );
    await db.execute('DROP TABLE IF EXISTS ${DatabaseConstants.noteTagsTable}');
    await db.execute('DROP TABLE IF EXISTS ${DatabaseConstants.notesTable}');
    await db.execute('DROP TABLE IF EXISTS ${DatabaseConstants.tagsTable}');
    await db.execute(
      'DROP TABLE IF EXISTS ${DatabaseConstants.categoriesTable}',
    );
  }

  Future<void> _createFtsTriggers(Database db) async {
    await db.execute(DatabaseConstants.notesSearchInsertTrigger);
    await db.execute(DatabaseConstants.notesSearchUpdateTrigger);
    await db.execute(DatabaseConstants.notesSearchDeleteTrigger);
  }

  void notifyListeners() {
    _databaseStreamController.add(null);
  }

  Future<List<Map<String, dynamic>>> searchNotes(String query) async {
    final db = await database;
    final searchTerm = '%$query%';
    return await db.rawQuery(
      '''
      SELECT DISTINCT n.* FROM ${DatabaseConstants.notesTable} n
      LEFT JOIN ${DatabaseConstants.notesSearchTable} ns ON n.id = ns.note_id
      WHERE (n.title LIKE ? OR n.plain_text LIKE ? OR 
             ns.title LIKE ? OR ns.plain_text LIKE ?)
      AND n.is_deleted = 0
      ORDER BY n.updated_at DESC
    ''',
      [searchTerm, searchTerm, searchTerm, searchTerm],
    );
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
      DatabaseConstants.noteTagsTable,
      DatabaseConstants.notesSearchTable,
      DatabaseConstants.notesTable,
      DatabaseConstants.tagsTable,
      DatabaseConstants.categoriesTable,
    ];
    for (final table in tables) {
      await db.delete(table);
    }
    notifyListeners();
  }
}
