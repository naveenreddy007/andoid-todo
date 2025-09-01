import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'dart:convert';
import 'data/repositories/local_todo_repository.dart';
import 'domain/entities/todo.dart';
import 'domain/entities/todo_status.dart';
import 'domain/entities/priority.dart';
import 'services/local/database_helper.dart';

class DebugHelper {
  static const _uuid = Uuid();
  
  static Future<void> insertTestTodos() async {
    if (!kDebugMode) return;
    
    try {
      final dbHelper = DatabaseHelper();
      final repository = LocalTodoRepository(dbHelper);
      
      // Create test todos
      final testTodos = [
        Todo(
          id: _uuid.v4(),
          title: 'Test Todo via Debug Helper',
          description: 'This is a test todo created programmatically',
          status: TodoStatus.pending,
          priority: Priority.high,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Todo(
          id: _uuid.v4(),
          title: 'Second Test Todo',
          description: 'Another test todo for verification',
          status: TodoStatus.pending,
          priority: Priority.medium,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Todo(
          id: _uuid.v4(),
          title: 'Completed Test Todo',
          description: 'A completed todo for testing',
          status: TodoStatus.completed,
          priority: Priority.low,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now(),
          completedAt: DateTime.now(),
        ),
      ];
      
      // Insert todos
      for (final todo in testTodos) {
        await repository.saveTodo(todo);
        debugPrint('✅ Inserted todo: ${todo.title}');
      }
      
      debugPrint('🎉 Successfully inserted ${testTodos.length} test todos!');
      
    } catch (e) {
      debugPrint('❌ Error inserting test todos: $e');
    }
  }
  
  static Future<void> fetchAndPrintTodos() async {
    if (!kDebugMode) return;
    
    try {
      final dbHelper = DatabaseHelper();
      final repository = LocalTodoRepository(dbHelper);
      
      final todos = await repository.getAllTodos();
      
      debugPrint('📋 Found ${todos.length} todos in database:');
      for (final todo in todos) {
        debugPrint('  - ${todo.title} (${todo.status.name}) - ${todo.priority.name}');
      }
      
    } catch (e) {
      debugPrint('❌ Error fetching todos: $e');
    }
  }
  
  static Future<void> clearAllTodos() async {
    if (!kDebugMode) return;
    
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      
      await db.delete('todos');
      debugPrint('🗑️ Cleared all todos from database');
      
    } catch (e) {
      debugPrint('❌ Error clearing todos: $e');
    }
  }
  
  // ADB-accessible methods via file system
  static Future<void> processAdbCommands() async {
    if (!kDebugMode) return;
    
    debugPrint('🔄 Checking for ADB commands...');
    
    try {
      final directory = Directory('/data/data/com.notetaking.app.note_taking_app/files');
      final commandFile = File('${directory.path}/adb_command.json');
      final responseFile = File('${directory.path}/adb_response.json');
      
      debugPrint('📁 Checking command file: ${commandFile.path}');
      
      if (await commandFile.exists()) {
        final commandJson = await commandFile.readAsString();
        final command = jsonDecode(commandJson);
        
        debugPrint('📥 Processing ADB command: ${command['action']}');
        
        Map<String, dynamic> response = {'success': false, 'data': null, 'error': null};
        
        try {
          switch (command['action']) {
            case 'create_todo':
              response = await _createTodoFromAdb(command['data']);
              break;
            case 'get_todos':
              response = await _getTodosForAdb();
              break;
            case 'get_todo_count':
              response = await _getTodoCountForAdb();
              break;
            case 'delete_todo':
              response = await _deleteTodoFromAdb(command['data']);
              break;
            default:
              response['error'] = 'Unknown action: ${command['action']}';
          }
        } catch (e) {
          response['error'] = e.toString();
        }
        
        // Write response
        await responseFile.writeAsString(jsonEncode(response));
        
        // Clean up command file
        await commandFile.delete();
        
        debugPrint('📤 ADB command processed, response written');
      }
    } catch (e) {
      debugPrint('❌ Error processing ADB commands: $e');
    }
  }
  
  static Future<Map<String, dynamic>> _createTodoFromAdb(Map<String, dynamic> data) async {
    try {
      final dbHelper = DatabaseHelper();
      final repository = LocalTodoRepository(dbHelper);
      
      final todo = Todo(
        id: _uuid.v4(),
        title: data['title'] ?? 'Untitled',
        description: data['description'] ?? '',
        status: TodoStatus.values.firstWhere(
          (s) => s.name == (data['status'] ?? 'pending'),
          orElse: () => TodoStatus.pending,
        ),
        priority: Priority.values.firstWhere(
          (p) => p.name == (data['priority'] ?? 'medium'),
          orElse: () => Priority.medium,
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await repository.saveTodo(todo);
      
      return {
        'success': true,
        'data': {
          'id': todo.id,
          'title': todo.title,
          'description': todo.description,
          'status': todo.status.name,
          'priority': todo.priority.name,
        }
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> _getTodosForAdb() async {
    try {
      final dbHelper = DatabaseHelper();
      final repository = LocalTodoRepository(dbHelper);
      
      final todos = await repository.getAllTodos();
      
      return {
        'success': true,
        'data': todos.map((todo) => {
          'id': todo.id,
          'title': todo.title,
          'description': todo.description,
          'status': todo.status.name,
          'priority': todo.priority.name,
          'created_at': todo.createdAt.millisecondsSinceEpoch,
          'updated_at': todo.updatedAt.millisecondsSinceEpoch,
        }).toList()
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> _getTodoCountForAdb() async {
    try {
      final dbHelper = DatabaseHelper();
      final repository = LocalTodoRepository(dbHelper);
      
      final todos = await repository.getAllTodos();
      
      return {
        'success': true,
        'data': {'count': todos.length}
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> _deleteTodoFromAdb(Map<String, dynamic> data) async {
    try {
      final dbHelper = DatabaseHelper();
      final repository = LocalTodoRepository(dbHelper);
      
      final todoId = data['id'];
      if (todoId == null) {
        return {'success': false, 'error': 'Todo ID is required'};
      }
      
      await repository.deleteTodo(todoId);
      
      return {
        'success': true,
        'data': {'deleted_id': todoId}
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}