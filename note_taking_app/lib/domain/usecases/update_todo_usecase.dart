import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

class UpdateTodoUseCase {
  final TodoRepository _todoRepository;

  UpdateTodoUseCase(this._todoRepository);

  Future<void> execute({
    required String id,
    String? title,
    String? description,
    Priority? priority,
    TodoStatus? status,
    String? categoryId,
    List<String>? tagIds,
    DateTime? dueDate,
    List<String>? reminderIds,
    List<String>? attachmentIds,
  }) async {
    final existingTodo = await _todoRepository.getTodoById(id);
    if (existingTodo == null) {
      throw Exception('Todo not found');
    }

    final updatedTodo = existingTodo.copyWith(
      title: title,
      description: description,
      priority: priority,
      status: status,
      categoryId: categoryId,
      tagIds: tagIds,
      dueDate: dueDate,
      reminderIds: reminderIds,
      attachmentIds: attachmentIds,
      completedAt: status == TodoStatus.completed && existingTodo.status != TodoStatus.completed
          ? DateTime.now()
          : (status != TodoStatus.completed ? null : existingTodo.completedAt),
      syncStatus: SyncStatus.pending,
      updatedAt: DateTime.now(),
    );

    await _todoRepository.updateTodo(updatedTodo);
  }
}