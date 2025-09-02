import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/local_todo_repository.dart';
import '../domain/entities/todo.dart';
import '../domain/entities/todo_status.dart';
import '../domain/entities/priority.dart';
import '../domain/repositories/todo_repository.dart';
import '../services/local/database_helper.dart';

// Database helper provider
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

// Todo repository provider
final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return LocalTodoRepository(databaseHelper);
});

// Todos list provider
final todosProvider = StreamProvider<List<Todo>>((ref) {
  final repository = ref.watch(todoRepositoryProvider);
  return repository.watchTodos();
});

// Individual todo provider
final todoProvider = FutureProvider.family<Todo?, String>((ref, id) async {
  final repository = ref.watch(todoRepositoryProvider);
  return repository.getTodoById(id);
});

// Todos by status provider
final todosByStatusProvider = FutureProvider.family<List<Todo>, TodoStatus>((ref, status) async {
  final repository = ref.watch(todoRepositoryProvider);
  return repository.getTodosByStatus(status);
});

// Todos due today provider
final todosDueTodayProvider = FutureProvider<List<Todo>>((ref) async {
  final repository = ref.watch(todoRepositoryProvider);
  return repository.getTodosDueToday();
});

// Overdue todos provider
final overdueTodosProvider = FutureProvider<List<Todo>>((ref) async {
  final repository = ref.watch(todoRepositoryProvider);
  return repository.getOverdueTodos();
});

// Todo operations notifier
class TodoOperationsNotifier extends StateNotifier<AsyncValue<void>> {
  final TodoRepository _repository;

  TodoOperationsNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> saveTodo(Todo todo) async {
    print('🔄 DEBUG: TodoOperationsNotifier.saveTodo called - ID: ${todo.id}, Title: "${todo.title}"');
    state = const AsyncValue.loading();
    try {
      print('💾 DEBUG: Calling repository.saveTodo');
      await _repository.saveTodo(todo);
      print('✅ DEBUG: Repository.saveTodo completed successfully');
      state = const AsyncValue.data(null);
      print('🎯 DEBUG: TodoOperationsNotifier state set to success');
    } catch (error, stackTrace) {
      print('❌ DEBUG: TodoOperationsNotifier.saveTodo error: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateTodo(Todo todo) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateTodo(todo);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteTodo(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteTodo(id);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> completeTodo(String id) async {
    state = const AsyncValue.loading();
    try {
      final todo = await _repository.getTodoById(id);
      if (todo != null) {
        final updatedTodo = todo.copyWith(
          status: TodoStatus.completed,
          completedAt: DateTime.now(),
        );
        await _repository.updateTodo(updatedTodo);
      }
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> uncompleteTodo(String id) async {
    state = const AsyncValue.loading();
    try {
      final todo = await _repository.getTodoById(id);
      if (todo != null) {
        final updatedTodo = todo.copyWith(
          status: TodoStatus.pending,
          completedAt: null,
        );
        await _repository.updateTodo(updatedTodo);
      }
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final todoOperationsProvider =
    StateNotifierProvider<TodoOperationsNotifier, AsyncValue<void>>((ref) {
      final repository = ref.watch(todoRepositoryProvider);
      return TodoOperationsNotifier(repository);
    });
