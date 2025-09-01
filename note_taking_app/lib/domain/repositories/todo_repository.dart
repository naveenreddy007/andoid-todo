import '../entities/todo.dart';
import '../entities/priority.dart';
import '../entities/todo_status.dart';

abstract class TodoRepository {
  Future<List<Todo>> getAllTodos();
  Future<Todo?> getTodoById(String id);
  Future<void> saveTodo(Todo todo);
  Future<void> updateTodo(Todo todo);
  Future<void> deleteTodo(String id);
  Future<void> completeTodo(String id);
  Future<void> markTodoInProgress(String id);
  Stream<List<Todo>> watchTodos();
  Future<List<Todo>> getTodosByCategory(String categoryId);
  Future<List<Todo>> getTodosByTag(String tagId);
  Future<List<Todo>> getTodosByPriority(Priority priority);
  Future<List<Todo>> getTodosByStatus(TodoStatus status);
  Future<List<Todo>> getDeletedTodos();
  Future<List<Todo>> getTodosDueToday();
  Future<List<Todo>> getOverdueTodos();
  Future<List<Todo>> getTodosWithReminders();
  Future<List<Todo>> getTodosDueForSync();
}