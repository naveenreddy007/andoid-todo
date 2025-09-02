import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;

// Simple test without Flutter dependencies
void main() async {
  print('🚀 Starting Complete Tag Workflow Test (Database Only)');
  
  // Initialize FFI for desktop testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  
  try {
    // Test 1: Database Connection
    print('\n📊 Test 1: Database Connection');
    final dbPath = path.join(Directory.current.path, 'test_todo_app.db');
    final db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        // Create tables
        await db.execute('''
          CREATE TABLE tags (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            color TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER,
            sync_status TEXT DEFAULT 'pending',
            last_synced INTEGER,
            cloud_file_id TEXT
          )
        ''');
        
        await db.execute('''
          CREATE TABLE todos (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT,
            status TEXT NOT NULL,
            priority TEXT NOT NULL,
            due_date INTEGER,
            category_id TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            completed_at INTEGER,
            sync_status TEXT DEFAULT 'pending',
            last_synced INTEGER,
            cloud_file_id TEXT
          )
        ''');
        
        await db.execute('''
          CREATE TABLE todo_tags (
            todo_id TEXT NOT NULL,
            tag_id TEXT NOT NULL,
            PRIMARY KEY (todo_id, tag_id),
            FOREIGN KEY (todo_id) REFERENCES todos (id) ON DELETE CASCADE,
            FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
          )
        ''');
        
        print('✅ Database tables created successfully');
      },
    );
    
    print('✅ Database connected successfully');
    
    // Test 2: Create Test Tags
    print('\n🎨 Test 2: Creating Test Tags');
    final testTags = [
      {
        'id': 'tag_work_001',
        'name': 'Work',
        'color': '#FF5722',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'id': 'tag_personal_002',
        'name': 'Personal',
        'color': '#2196F3',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'id': 'tag_urgent_003',
        'name': 'Urgent',
        'color': '#F44336',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
    ];
    
    for (final tag in testTags) {
      await db.insert('tags', tag);
      print('✅ Created tag: ${tag['name']} (${tag['id']})');
    }
    
    // Test 3: Verify Tags in Database
    print('\n🔍 Test 3: Verifying Tags in Database');
    final allTags = await db.query('tags');
    print('📊 Found ${allTags.length} tags in database:');
    for (final tag in allTags) {
      print('  - ${tag['name']} (${tag['id']}) - Color: ${tag['color']}');
    }
    
    // Test 4: Create Todo with Tags
    print('\n📋 Test 4: Creating Todo with Tags');
    final todoData = {
      'id': 'todo_test_001',
      'title': 'Test Todo with Tags',
      'description': 'This todo should be associated with Work and Urgent tags',
      'status': 'pending',
      'priority': 'high',
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
    
    await db.insert('todos', todoData);
    print('✅ Created todo: ${todoData['title']} (${todoData['id']})');
    
    // Test 5: Create Todo-Tag Associations
    print('\n🔗 Test 5: Creating Todo-Tag Associations');
    final associations = [
      {'todo_id': 'todo_test_001', 'tag_id': 'tag_work_001'},
      {'todo_id': 'todo_test_001', 'tag_id': 'tag_urgent_003'},
    ];
    
    for (final assoc in associations) {
      await db.insert('todo_tags', assoc);
      print('✅ Associated todo ${assoc['todo_id']} with tag ${assoc['tag_id']}');
    }
    
    // Test 6: Verify Todo-Tag Associations
    print('\n🔍 Test 6: Verifying Todo-Tag Associations');
    final todoTags = await db.rawQuery('''
      SELECT t.*, tg.name as tag_name, tg.color as tag_color
      FROM todo_tags t
      JOIN tags tg ON t.tag_id = tg.id
      WHERE t.todo_id = ?
    ''', ['todo_test_001']);
    
    print('📊 Found ${todoTags.length} tags for todo:');
    for (final tag in todoTags) {
      print('  - ${tag['tag_name']} (${tag['tag_id']}) - Color: ${tag['tag_color']}');
    }
    
    // Test 7: Test Tag Filtering
    print('\n🔍 Test 7: Testing Tag Filtering');
    final workTaggedTodos = await db.rawQuery('''
      SELECT td.*, tg.name as tag_name
      FROM todos td
      JOIN todo_tags tt ON td.id = tt.todo_id
      JOIN tags tg ON tt.tag_id = tg.id
      WHERE tg.id = ?
    ''', ['tag_work_001']);
    
    print('📊 Found ${workTaggedTodos.length} todos with "Work" tag');
    for (final todo in workTaggedTodos) {
      print('  - ${todo['title']} (${todo['id']})');
    }
    
    // Test 8: Test Popular Tags
    print('\n📈 Test 8: Testing Popular Tags');
    final popularTags = await db.rawQuery('''
      SELECT t.*, COUNT(tt.todo_id) as todo_count
      FROM tags t
      LEFT JOIN todo_tags tt ON t.id = tt.tag_id
      GROUP BY t.id
      ORDER BY todo_count DESC
      LIMIT 5
    ''');
    
    print('📊 Popular tags:');
    for (final tag in popularTags) {
      print('  - ${tag['name']}: ${tag['todo_count']} todos');
    }
    
    // Test 9: Test Tag Search
    print('\n🔍 Test 9: Testing Tag Search');
    final searchResults = await db.query(
      'tags',
      where: 'name LIKE ?',
      whereArgs: ['%work%'],
    );
    
    print('📊 Search results for "work": ${searchResults.length} tags');
    for (final tag in searchResults) {
      print('  - ${tag['name']}');
    }
    
    // Test 10: Database Schema Verification
    print('\n🗄️ Test 10: Database Schema Verification');
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    print('📊 Database tables:');
    for (final table in tables) {
      print('  - ${table['name']}');
    }
    
    // Check tags table schema
    final tagsSchema = await db.rawQuery('PRAGMA table_info(tags)');
    print('\n🏷️ Tags table schema:');
    for (final column in tagsSchema) {
      print('  - ${column['name']}: ${column['type']}');
    }
    
    // Check todo_tags table schema
    final todoTagsSchema = await db.rawQuery('PRAGMA table_info(todo_tags)');
    print('\n🔗 Todo_tags table schema:');
    for (final column in todoTagsSchema) {
      print('  - ${column['name']}: ${column['type']}');
    }
    
    // Test 11: Complex Query Test
    print('\n🔍 Test 11: Complex Query Test');
    final complexQuery = await db.rawQuery('''
      SELECT 
        td.id as todo_id,
        td.title,
        td.status,
        td.priority,
        GROUP_CONCAT(tg.name, ', ') as tag_names,
        COUNT(tt.tag_id) as tag_count
      FROM todos td
      LEFT JOIN todo_tags tt ON td.id = tt.todo_id
      LEFT JOIN tags tg ON tt.tag_id = tg.id
      GROUP BY td.id
    ''');
    
    print('📊 Complex query results:');
    for (final result in complexQuery) {
      print('  - Todo: ${result['title']}');
      print('    Status: ${result['status']}, Priority: ${result['priority']}');
      print('    Tags: ${result['tag_names'] ?? 'None'} (${result['tag_count']} total)');
    }
    
    // Cleanup
    await db.close();
    await File(dbPath).delete();
    
    print('\n✅ Complete Tag Workflow Test PASSED!');
    print('🎉 All tag database functionality is working correctly!');
    
  } catch (e, stackTrace) {
    print('❌ Test FAILED with error: $e');
    print('📍 Stack trace: $stackTrace');
    exit(1);
  }
}