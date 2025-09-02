import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'lib/domain/entities/todo.dart';
import 'lib/domain/entities/todo_status.dart';
import 'lib/domain/entities/priority.dart';
import 'lib/services/local/database_helper.dart';
import 'lib/data/repositories/local_todo_repository.dart';
import 'lib/providers/todo_provider.dart';

void main() async {
  print('🧪 Testing Todo Creation Flow...');
  
  try {
    // Create database helper
    final databaseHelper = DatabaseHelper();
    
    // Create repository
    final repository = LocalTodoRepository(databaseHelper);
    
    // Create a test todo
    final testTodo = Todo(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Test Todo Flow',
      description: 'Testing the complete todo creation flow',
      status: TodoStatus.pending,
      priority: Priority.medium,
      categoryId: null,
      color: 0xFF2196F3,
      tagIds: [],
      dueDate: null,
      reminderDate: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      completedAt: null,
      isDeleted: false,
    );
    
    print('📝 Creating test todo: ${testTodo.title}');
    
    // Save the todo
    await repository.saveTodo(testTodo);
    
    print('✅ Todo saved successfully');
    
    // Wait a moment for stream updates
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Get all todos to verify
    final allTodos = await repository.getAllTodos();
    print('📊 Total todos in database: ${allTodos.length}');
    
    // Listen to the stream for a few seconds
    print('👂 Listening to todo stream...');
    final streamSubscription = repository.watchTodos().listen((todos) {
      print('🔄 Stream update: ${todos.length} todos received');
      for (final todo in todos.take(3)) {
        print('  - ${todo.title} (${todo.status})');
      }
    });
    
    // Wait for stream updates
    await Future.delayed(const Duration(seconds: 2));
    
    // Cancel subscription
    await streamSubscription.cancel();
    
    print('✅ Test completed successfully');
    
  } catch (e, stackTrace) {
    print('❌ Test failed: $e');
    print('Stack trace: $stackTrace');
  }
}