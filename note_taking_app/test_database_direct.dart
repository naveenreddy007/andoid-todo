import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

void main() async {
  // Initialize FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  
  print('🔍 Testing database operations directly...');
  
  try {
    // Get database path
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'todo_database.db');
    
    print('📁 Database path: $path');
    
    // Open database
    final database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create tables if they don't exist
        await db.execute('''
          CREATE TABLE todos(
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT,
            status TEXT NOT NULL,
            priority TEXT NOT NULL,
            category TEXT,
            color INTEGER,
            due_date INTEGER,
            reminder_date INTEGER,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            completed_at INTEGER
          )
        ''');
        
        await db.execute('''
          CREATE TABLE tags(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL UNIQUE,
            color INTEGER NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        
        await db.execute('''
          CREATE TABLE todo_tags(
            todo_id TEXT NOT NULL,
            tag_id TEXT NOT NULL,
            PRIMARY KEY (todo_id, tag_id),
            FOREIGN KEY (todo_id) REFERENCES todos (id) ON DELETE CASCADE,
            FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
          )
        ''');
        
        print('✅ Database tables created');
      },
    );
    
    // Check current todos count
    final todosCount = Sqflite.firstIntValue(await database.rawQuery('SELECT COUNT(*) FROM todos'));
    print('📊 Current todos count: $todosCount');
    
    // Insert a test todo
    final testTodoId = 'test_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await database.insert('todos', {
      'id': testTodoId,
      'title': 'Test Todo Direct DB',
      'description': 'Testing direct database insertion',
      'status': 'pending',
      'priority': 'medium',
      'category': 'test',
      'color': 0xFF2196F3,
      'due_date': null,
      'reminder_date': null,
      'created_at': now,
      'updated_at': now,
      'completed_at': null,
    });
    
    print('✅ Test todo inserted with ID: $testTodoId');
    
    // Check todos count after insertion
    final newTodosCount = Sqflite.firstIntValue(await database.rawQuery('SELECT COUNT(*) FROM todos'));
    print('📊 New todos count: $newTodosCount');
    
    // Query recent todos
    final recentTodos = await database.query(
      'todos',
      orderBy: 'created_at DESC',
      limit: 5,
    );
    
    print('📋 Recent todos:');
    for (final todo in recentTodos) {
      print('  - ${todo['title']} (${todo['id']}) - Status: ${todo['status']}');
    }
    
    await database.close();
    print('✅ Database test completed successfully');
    
  } catch (e, stackTrace) {
    print('❌ Database test failed: $e');
    print('Stack trace: $stackTrace');
  }
}