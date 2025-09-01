import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

class GetTodosUseCase {
  final TodoRepository _todoRepository;

  GetTodosUseCase(this._todoRepository);

  Future<List<Todo>> execute({
    TodoStatus? status,
    Priority? priority,
    String? categoryId,
    String? tagId,
    bool includeDeleted = false,
  }) async {
    List<Todo> todos;

    if (status != null) {
      todos = await _todoRepository.getTodosByStatus(status);
    } else if (priority != null) {
      todos = await _todoRepository.getTodosByPriority(priority);
    } else if (categoryId != null) {
      todos = await _todoRepository.getTodosByCategory(categoryId);
    } else if (tagId != null) {
      todos = await _todoRepository.getTodosByTag(tagId);
    } else {
      todos = await _todoRepository.getAllTodos();
    }

    // Filter out deleted todos unless explicitly requested
    if (!includeDeleted) {
      todos = todos.where((todo) => !todo.isDeleted).toList();
    }

    // Sort by priority and due date
    todos.sort((a, b) {
      // First sort by priority (high to low)
      final priorityComparison = _comparePriority(a.priority, b.priority);
      if (priorityComparison != 0) return priorityComparison;

      // Then sort by due date (earliest first)
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      } else if (a.dueDate != null) {
        return -1;
      } else if (b.dueDate != null) {
        return 1;
      }

      // Finally sort by creation date (newest first)
      return b.createdAt.compareTo(a.createdAt);
    });

    return todos;
  }

  int _comparePriority(Priority a, Priority b) {
    const priorityOrder = {
      Priority.high: 3,
      Priority.medium: 2,
      Priority.low: 1,
    };
    return priorityOrder[b]!.compareTo(priorityOrder[a]!);
  }

  Future<List<Todo>> getTodosForToday() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final allTodos = await _todoRepository.getAllTodos();
    return allTodos.where((todo) {
      if (todo.isDeleted) return false;
      if (todo.dueDate == null) return false;
      return todo.dueDate!.isAfter(today.subtract(const Duration(milliseconds: 1))) &&
             todo.dueDate!.isBefore(tomorrow);
    }).toList();
  }

  Future<List<Todo>> getOverdueTodos() async {
    return await _todoRepository.getOverdueTodos();
  }
}