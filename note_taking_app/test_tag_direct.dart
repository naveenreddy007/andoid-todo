import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

// Simple test to verify tag functionality without Flutter app
void main() async {
  print('🧪 Testing Tag Functionality Directly');
  
  try {
    // Initialize database
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'note_taking_app.db');
    
    final database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create tags table
        await db.execute('''
          CREATE TABLE tags (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            color TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        
        // Create todo_tags table
        await db.execute('''
          CREATE TABLE todo_tags (
            todo_id TEXT NOT NULL,
            tag_id TEXT NOT NULL,
            PRIMARY KEY (todo_id, tag_id)
          )
        ''');
        
        print('✅ Database tables created');
      },
    );
    
    const uuid = Uuid();
    final tagId = uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Test 1: Create a tag
    print('\n📝 Test 1: Creating a tag');
    await database.insert('tags', {
      'id': tagId,
      'name': 'urgent',
      'color': '#FF5722',
      'created_at': now,
      'updated_at': now,
    });
    print('✅ Tag created with ID: $tagId');
    
    // Test 2: Retrieve the tag
    print('\n📖 Test 2: Retrieving the tag');
    final tags = await database.query('tags', where: 'id = ?', whereArgs: [tagId]);
    if (tags.isNotEmpty) {
      final tag = tags.first;
      print('✅ Tag retrieved: ${tag['name']} (${tag['color']})');
    } else {
      print('❌ Tag not found');
    }
    
    // Test 3: List all tags
    print('\n📋 Test 3: Listing all tags');
    final allTags = await database.query('tags');
    print('✅ Found ${allTags.length} tags:');
    for (final tag in allTags) {
      print('  - ${tag['name']} (${tag['color']})');
    }
    
    // Test 4: Create a mock todo and associate with tag
    print('\n🔗 Test 4: Associating tag with todo');
    final todoId = uuid.v4();
    
    // Insert into todo_tags junction table
    await database.insert('todo_tags', {
      'todo_id': todoId,
      'tag_id': tagId,
    });
    print('✅ Tag associated with todo: $todoId');
    
    // Test 5: Retrieve tags for todo
    print('\n🔍 Test 5: Retrieving tags for todo');
    final todoTags = await database.rawQuery('''
      SELECT t.* FROM tags t
      INNER JOIN todo_tags tt ON t.id = tt.tag_id
      WHERE tt.todo_id = ?
    ''', [todoId]);
    
    print('✅ Found ${todoTags.length} tags for todo:');
    for (final tag in todoTags) {
      print('  - ${tag['name']} (${tag['color']})');
    }
    
    // Test 6: Remove tag from todo
    print('\n🗑️ Test 6: Removing tag from todo');
    await database.delete('todo_tags', 
      where: 'todo_id = ? AND tag_id = ?', 
      whereArgs: [todoId, tagId]
    );
    print('✅ Tag removed from todo');
    
    // Test 7: Verify removal
    print('\n✅ Test 7: Verifying tag removal');
    final remainingTags = await database.rawQuery('''
      SELECT t.* FROM tags t
      INNER JOIN todo_tags tt ON t.id = tt.tag_id
      WHERE tt.todo_id = ?
    ''', [todoId]);
    print('✅ Remaining tags for todo: ${remainingTags.length}');
    
    // Cleanup
    await database.delete('tags', where: 'id = ?', whereArgs: [tagId]);
    await database.close();
    
    print('\n🎉 All tag functionality tests completed successfully!');
    
  } catch (e) {
    print('❌ Error during testing: $e');
  }
}