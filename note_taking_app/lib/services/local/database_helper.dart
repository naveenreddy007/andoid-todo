import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  static const String _dbName = 'note_taking_app.db';
  static const int _dbVersion = 1;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _dbName);
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

    // Full-text search virtual table
    await db.execute('''
      CREATE VIRTUAL TABLE notes_fts USING fts5(
        title, plain_text, content='notes', content_rowid='ROWID'
      )
    ''');
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX idx_notes_updated_at ON notes(updated_at)');
    await db.execute('CREATE INDEX idx_notes_reminder_date ON notes(reminder_date)');
    await db.execute('CREATE INDEX idx_notes_category ON notes(category_id)');
    await db.execute('CREATE INDEX idx_notes_sync_status ON notes(sync_status)');
    await db.execute('CREATE INDEX idx_sync_metadata_entity ON sync_metadata(entity_type, entity_id)');
    await db.execute('CREATE INDEX idx_notes_priority ON notes(priority)');
    await db.execute('CREATE INDEX idx_notes_is_archived ON notes(is_archived)');
    await db.execute('CREATE INDEX idx_notes_is_deleted ON notes(is_deleted)');
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
    await db.execute('DROP TABLE IF EXISTS notes_fts');
    await db.execute('DROP TABLE IF EXISTS sync_metadata');
    await db.execute('DROP TABLE IF EXISTS attachments');
    await db.execute('DROP TABLE IF EXISTS note_tags');
    await db.execute('DROP TABLE IF EXISTS notes');
    await db.execute('DROP TABLE IF EXISTS tags');
    await db.execute('DROP TABLE IF EXISTS categories');
  }

  // FTS trigger management
  Future<void> _createFtsTriggers(Database db) async {
    // Insert trigger
    await db.execute('''
      CREATE TRIGGER notes_fts_insert AFTER INSERT ON notes BEGIN
        INSERT INTO notes_fts(rowid, title, plain_text) 
        VALUES (new.rowid, new.title, new.plain_text);
      END
    ''');

    // Update trigger
    await db.execute('''
      CREATE TRIGGER notes_fts_update AFTER UPDATE ON notes BEGIN
        UPDATE notes_fts SET title = new.title, plain_text = new.plain_text 
        WHERE rowid = old.rowid;
      END
    ''');

    // Delete trigger
    await db.execute('''
      CREATE TRIGGER notes_fts_delete AFTER DELETE ON notes BEGIN
        DELETE FROM notes_fts WHERE rowid = old.rowid;
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
    return await db.insert(table, values);
  }

  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, values, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
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
    return await db.transaction(action);
  }

  // Batch operations
  Batch batch() {
    return _database!.batch();
  }

  Future<List<dynamic>> commitBatch(Batch batch) async {
    return await batch.commit();
  }

  // Full-text search
  Future<List<Map<String, dynamic>>> searchNotes(String query) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT notes.* FROM notes
      INNER JOIN notes_fts ON notes.rowid = notes_fts.rowid
      WHERE notes_fts MATCH ? AND notes.is_deleted = 0
      ORDER BY rank
    ''', [query]);
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
    await db.delete('notes');
    await db.delete('tags');
    await db.delete('categories');
    await db.execute('DELETE FROM notes_fts');
  }
}