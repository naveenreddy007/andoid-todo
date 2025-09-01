import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'dart:io';

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

  static const String _dbName = 'note_taking_app.db';
  static const int _dbVersion = 2;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      return await openDatabase(
        inMemoryDatabasePath,
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
      );
    }

    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    String path = join(await getDatabasesPath(), _dbName);
    print('Database path: $path');
    return await openDatabase(
      path,
      version: _dbVersion,
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
    // Handle database migrations here
    // For now, we'll just recreate the database
    if (oldVersion < newVersion) {
      await _dropTables(db);
      await _createTables(db);
      await _createIndexes(db);
      await _createFtsTriggers(db);
      await _insertDefaultData(db);
    }
  }

  Future<void> _createTables(Database db) async {
    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        icon TEXT,
        color TEXT DEFAULT '#2196F3',
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Tags table
    await db.execute('''
      CREATE TABLE tags (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        color TEXT DEFAULT '#FF9800',
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Notes table
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        plain_text TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        reminder_date TEXT,
        priority TEXT DEFAULT 'medium',
        category_id TEXT,
        is_archived INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        sync_status TEXT DEFAULT 'pending',
        last_synced TEXT,
        cloud_file_id TEXT,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    // Note-Tag junction table
    await db.execute('''
      CREATE TABLE note_tags (
        note_id TEXT,
        tag_id TEXT,
        PRIMARY KEY (note_id, tag_id),
        FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
      )
    ''');

    // Attachments table
    await db.execute('''
      CREATE TABLE attachments (
        id TEXT PRIMARY KEY,
        note_id TEXT NOT NULL,
        file_name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        mime_type TEXT,
        file_size INTEGER,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE
      )
    ''');

    // Sync metadata table
    await db.execute('''
      CREATE TABLE sync_metadata (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        local_hash TEXT,
        cloud_hash TEXT,
        last_sync TEXT,
        conflict_status TEXT DEFAULT 'none',
        UNIQUE(entity_type, entity_id)
      )
    ''');

    // Search table (replacing FTS5 for compatibility)
    await db.execute('''
      CREATE TABLE notes_search (
        id INTEGER PRIMARY KEY,
        note_id TEXT NOT NULL,
        title TEXT,
        plain_text TEXT,
        FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX idx_notes_updated_at ON notes(updated_at)');
    await db.execute(
      'CREATE INDEX idx_notes_reminder_date ON notes(reminder_date)',
    );
    await db.execute('CREATE INDEX idx_notes_category ON notes(category_id)');
    await db.execute(
      'CREATE INDEX idx_notes_sync_status ON notes(sync_status)',
    );
    await db.execute(
      'CREATE INDEX idx_sync_metadata_entity ON sync_metadata(entity_type, entity_id)',
    );
    await db.execute('CREATE INDEX idx_notes_priority ON notes(priority)');
    await db.execute(
      'CREATE INDEX idx_notes_is_archived ON notes(is_archived)',
    );
    await db.execute('CREATE INDEX idx_notes_is_deleted ON notes(is_deleted)');

    // Search table indexes
    await db.execute(
      'CREATE INDEX idx_notes_search_title ON notes_search(title)',
    );
    await db.execute(
      'CREATE INDEX idx_notes_search_content ON notes_search(plain_text)',
    );
    await db.execute(
      'CREATE INDEX idx_notes_search_note_id ON notes_search(note_id)',
    );
  }

  Future<void> _insertDefaultData(Database db) async {
    // Insert default categories
    await db.insert('categories', {
      'id': 'personal',
      'name': 'Personal',
      'icon': 'person',
      'color': '#2196F3',
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('categories', {
      'id': 'work',
      'name': 'Work',
      'icon': 'work',
      'color': '#4CAF50',
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('categories', {
      'id': 'ideas',
      'name': 'Ideas',
      'icon': 'lightbulb',
      'color': '#FF9800',
      'created_at': DateTime.now().toIso8601String(),
    });

    // Insert default tags
    await db.insert('tags', {
      'id': 'important',
      'name': 'Important',
      'color': '#F44336',
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('tags', {
      'id': 'todo',
      'name': 'Todo',
      'color': '#9C27B0',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _dropTables(Database db) async {
    await db.execute('DROP TABLE IF EXISTS notes_search');
    await db.execute('DROP TABLE IF EXISTS sync_metadata');
    await db.execute('DROP TABLE IF EXISTS attachments');
    await db.execute('DROP TABLE IF EXISTS note_tags');
    await db.execute('DROP TABLE IF EXISTS notes');
    await db.execute('DROP TABLE IF EXISTS tags');
    await db.execute('DROP TABLE IF EXISTS categories');
  }

  // Search trigger management
  Future<void> _createFtsTriggers(Database db) async {
    // Insert trigger
    await db.execute('''
      CREATE TRIGGER notes_search_insert AFTER INSERT ON notes BEGIN
        INSERT INTO notes_search(note_id, title, plain_text) 
        VALUES (new.id, new.title, new.plain_text);
      END
    ''');

    // Update trigger
    await db.execute('''
      CREATE TRIGGER notes_search_update AFTER UPDATE ON notes BEGIN
        UPDATE notes_search SET title = new.title, plain_text = new.plain_text 
        WHERE note_id = old.id;
      END
    ''');

    // Delete trigger
    await db.execute('''
      CREATE TRIGGER notes_search_delete AFTER DELETE ON notes BEGIN
        DELETE FROM notes_search WHERE note_id = old.id;
      END
    ''');
  }

  // Utility methods for database operations
  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    final result = await db.insert(table, values);
    _databaseStreamController.add(null);
    return result;
  } return await db.insert(table, values);
  }

  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    final result = await db.update(table, values, where: where, whereArgs: whereArgs);
    _databaseStreamController.add(null);
    return result;
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    final result = await db.delete(table, where: where, whereArgs: whereArgs);
    _databaseStreamController.add(null);
    return result;
  }

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  Future<int> rawInsert(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawInsert(sql, arguments);
  }

  Future<int> rawUpdate(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawUpdate(sql, arguments);
  }

  Future<int> rawDelete(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawDelete(sql, arguments);
  }

  // Transaction support
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    final result = await db.transaction(action);
    _databaseStreamController.add(null);
    return result;
  }

  // Batch operations
  Batch batch() {
    return _database!.batch();
  }

  Future<List<dynamic>> commitBatch(Batch batch) async {
    return await batch.commit();
  }

  // Search functionality using LIKE queries
  Future<List<Map<String, dynamic>>> searchNotes(String query) async {
    final db = await database;
    final searchTerm = '%$query%';
    return await db.rawQuery(
      '''
      SELECT DISTINCT notes.* FROM notes
      LEFT JOIN notes_search ON notes.id = notes_search.note_id
      WHERE (notes.title LIKE ? OR notes.plain_text LIKE ? OR 
             notes_search.title LIKE ? OR notes_search.plain_text LIKE ?)
      AND notes.is_deleted = 0
      ORDER BY notes.updated_at DESC
    ''',
      [searchTerm, searchTerm, searchTerm, searchTerm],
    );
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // Test helper method
  static DatabaseHelper? get testInstance {
    return _instance;
  }

  // Clear all data (for testing)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('sync_metadata');
    await db.delete('attachments');
    await db.delete('note_tags');
    await db.delete('notes_search');
    await db.delete('notes');
    await db.delete('tags');
    await db.delete('categories');
  }
}