import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

class CreateTodoUseCase {
  final TodoRepository _todoRepository;

  CreateTodoUseCase(this._todoRepository);

  Future<void> execute({
    required String title,
    String? description,
    Priority priority = Priority.medium,
    String? categoryId,
    List<String> tagIds = const [],
    DateTime? dueDate,
  }) async {
    final todo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description ?? '',
      status: TodoStatus.pending,
      priority: priority,
      categoryId: categoryId,
      tagIds: tagIds,
      dueDate: dueDate,
      completedAt: null,
      reminderIds: [],
      attachmentIds: [],
      isDeleted: false,
      syncStatus: SyncStatus.pending,
      lastSynced: null,
      cloudFileId: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _todoRepository.saveTodo(todo);
  }
}