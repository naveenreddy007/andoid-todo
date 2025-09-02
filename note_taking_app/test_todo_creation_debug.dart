import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'lib/services/local/database_helper.dart';
import 'lib/repositories/local_todo_repository.dart';
import 'lib/models/todo.dart';

void main() async {
  // Initialize sqflite for desktop
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  
  print('🔍 Starting todo creation debug test...');
  
  try {
    // Initialize database helper
    final dbHelper = DatabaseHelper();
    await dbHelper.database; // Initialize database
    print('✅ Database initialized');
    
    // Initialize repository
    final repository = LocalTodoRepository(dbHelper);
    print('✅ Repository initialized');
    
    // Create a test todo
    final testTodo = Todo(
      title: 'Debug Test Todo',
      description: 'Testing todo creation flow',
      isCompleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    print('📝 Creating todo: ${testTodo.title}');
    
    // Save the todo
    final savedTodo = await repository.saveTodo(testTodo);
    print('✅ Todo saved with ID: ${savedTodo.id}');
    
    // Get all todos to verify
    final allTodos = await repository.getAllTodos();
    print('📋 Total todos in database: ${allTodos.length}');
    
    for (final todo in allTodos) {
      print('  - ${todo.title} (ID: ${todo.id}, Created: ${todo.createdAt})');
    }
    
    // Test the stream
    print('🔄 Testing todo stream...');
    final streamSubscription = repository.watchTodos().listen((todos) {
      print('📡 Stream update received: ${todos.length} todos');
      for (final todo in todos) {
        print('  - Stream: ${todo.title} (ID: ${todo.id})');
      }
    });
    
    // Wait a bit for stream updates
    await Future.delayed(Duration(seconds: 2));
    
    // Cancel subscription
    await streamSubscription.cancel();
    
    print('✅ Test completed successfully!');
    
  } catch (e, stackTrace) {
    print('❌ Error during test: $e');
    print('Stack trace: $stackTrace');
  }
  
  exit(0);
}