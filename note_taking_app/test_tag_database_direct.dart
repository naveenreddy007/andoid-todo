import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() async {
  print('🔍 Testing Tag Database Operations Directly');
  
  try {
    // Get the database path
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'todo_app.db');
    
    print('📁 Database path: $path');
    
    // Check if database exists
    final dbFile = File(path);
    if (!dbFile.existsSync()) {
      print('❌ Database file does not exist');
      return;
    }
    
    print('✅ Database file exists');
    
    // Open database
    final db = await openDatabase(path);
    
    print('\n🔍 Checking database schema...');
    
    // Check if tags table exists
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='tags'"
    );
    
    if (tables.isEmpty) {
      print('❌ Tags table does not exist');
      await db.close();
      return;
    }
    
    print('✅ Tags table exists');
    
    // Check tags table schema
    final tagSchema = await db.rawQuery('PRAGMA table_info(tags)');
    print('\n📋 Tags table schema:');
    for (final column in tagSchema) {
      print('  - ${column['name']}: ${column['type']}');
    }
    
    // Check if todo_tags table exists
    final todoTagsTables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='todo_tags'"
    );
    
    if (todoTagsTables.isEmpty) {
      print('❌ Todo_tags table does not exist');
    } else {
      print('✅ Todo_tags table exists');
      
      // Check todo_tags table schema
      final todoTagsSchema = await db.rawQuery('PRAGMA table_info(todo_tags)');
      print('\n📋 Todo_tags table schema:');
      for (final column in todoTagsSchema) {
        print('  - ${column['name']}: ${column['type']}');
      }
    }
    
    // Check existing tags
    final existingTags = await db.query('tags');
    print('\n🏷️ Existing tags (${existingTags.length}):');
    for (final tag in existingTags) {
      print('  - ID: ${tag['id']}, Name: ${tag['name']}, Color: ${tag['color']}');
    }
    
    // Test creating a new tag
    print('\n➕ Testing tag creation...');
    final testTagId = 'test_tag_${DateTime.now().millisecondsSinceEpoch}';
    
    try {
      await db.insert('tags', {
        'id': testTagId,
        'name': 'Test Tag',
        'color': '#FF5722',
        'created_at': DateTime.now().toIso8601String(),
      });
      print('✅ Test tag created successfully');
      
      // Verify the tag was created
      final createdTag = await db.query(
        'tags',
        where: 'id = ?',
        whereArgs: [testTagId],
      );
      
      if (createdTag.isNotEmpty) {
        print('✅ Test tag verified in database');
        print('   Tag data: ${createdTag.first}');
        
        // Clean up - delete the test tag
        await db.delete('tags', where: 'id = ?', whereArgs: [testTagId]);
        print('🧹 Test tag cleaned up');
      } else {
        print('❌ Test tag not found after creation');
      }
      
    } catch (e) {
      print('❌ Error creating test tag: $e');
    }
    
    // Check existing todos
    final existingTodos = await db.query('todos', limit: 5);
    print('\n📝 Sample todos (${existingTodos.length}):');
    for (final todo in existingTodos) {
      print('  - ID: ${todo['id']}, Title: ${todo['title']}');
    }
    
    // Check todo-tag associations
    final todoTagAssociations = await db.query('todo_tags');
    print('\n🔗 Todo-tag associations (${todoTagAssociations.length}):');
    for (final association in todoTagAssociations) {
      print('  - Todo: ${association['todo_id']}, Tag: ${association['tag_id']}');
    }
    
    await db.close();
    print('\n✅ Database test completed successfully!');
    
  } catch (e) {
    print('❌ Error during database test: $e');
  }
}