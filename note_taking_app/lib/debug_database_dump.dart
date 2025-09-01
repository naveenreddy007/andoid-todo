// Debug helper to dump database contents via Flutter
// This can be called from main.dart or triggered via debug commands

import 'package:flutter/foundation.dart';
import 'data/repositories/local_todo_repository.dart';
import 'data/repositories/local_category_repository.dart';
import 'data/repositories/local_tag_repository.dart';
import 'services/local/database_helper.dart';
import 'domain/entities/todo.dart';
import 'domain/entities/category.dart';
import 'domain/entities/tag.dart';
import 'domain/entities/todo_status.dart';

class DatabaseDumper {
  static Future<void> dumpAllData() async {
    try {
      print('=== DATABASE DUMP START ===');
      
      final dbHelper = DatabaseHelper();
      final todoRepo = LocalTodoRepository(dbHelper);
      final categoryRepo = LocalCategoryRepository(dbHelper);
      final tagRepo = LocalTagRepository(dbHelper);
      
      // Dump todos
      print('\n--- TODOS ---');
      final todos = await todoRepo.getAllTodos();
      print('Total todos: ${todos.length}');
      
      for (final todo in todos) {
        print('ID: ${todo.id}');
        print('Title: ${todo.title}');
        print('Description: ${todo.description}');
        print('Status: ${todo.status}');
        print('Priority: ${todo.priority}');
        print('Created: ${todo.createdAt}');
        print('Updated: ${todo.updatedAt}');
        print('Category ID: ${todo.categoryId}');
        print('Due Date: ${todo.dueDate}');
        print('---');
      }
      
      // Dump categories
      print('\n--- CATEGORIES ---');
      final categories = await categoryRepo.getAllCategories();
      print('Total categories: ${categories.length}');
      
      for (final category in categories) {
        print('ID: ${category.id}');
        print('Name: ${category.name}');
        print('Color: ${category.color}');
        print('Icon: ${category.icon}');
        print('Created: ${category.createdAt}');
        print('---');
      }
      
      // Dump tags
      print('\n--- TAGS ---');
      final tags = await tagRepo.getAllTags();
      print('Total tags: ${tags.length}');
      
      for (final tag in tags) {
        print('ID: ${tag.id}');
        print('Name: ${tag.name}');
        print('Color: ${tag.color}');
        print('Created: ${tag.createdAt}');
        print('---');
      }
      
      print('\n=== DATABASE DUMP END ===');
      
    } catch (e) {
      print('Error dumping database: $e');
    }
  }
  
  static Future<void> dumpTodosOnly() async {
    try {
      print('=== TODOS DUMP START ===');
      
      final dbHelper = DatabaseHelper();
      final todoRepo = LocalTodoRepository(dbHelper);
      
      final todos = await todoRepo.getAllTodos();
      print('Total todos: ${todos.length}');
      
      for (final todo in todos) {
        print('${todo.id}|${todo.title}|${todo.description}|${todo.status}|${todo.priority}|${todo.createdAt}|${todo.updatedAt}');
      }
      
      print('=== TODOS DUMP END ===');
      
    } catch (e) {
      print('Error dumping todos: $e');
    }
  }
  
  static Future<void> dumpTodosByStatus(TodoStatus status) async {
    try {
      print('=== TODOS BY STATUS (${status.displayName}) DUMP START ===');
      
      final dbHelper = DatabaseHelper();
      final todoRepo = LocalTodoRepository(dbHelper);
      
      final todos = await todoRepo.getTodosByStatus(status);
      print('Total todos with status "${status.displayName}": ${todos.length}');
      
      for (final todo in todos) {
        print('${todo.id}|${todo.title}|${todo.description}|${todo.status}|${todo.priority}|${todo.createdAt}|${todo.updatedAt}');
      }
      
      print('=== TODOS BY STATUS DUMP END ===');
      
    } catch (e) {
      print('Error dumping todos by status: $e');
    }
  }
}