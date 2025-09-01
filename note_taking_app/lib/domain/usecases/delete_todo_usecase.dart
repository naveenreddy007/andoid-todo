import '../repositories/todo_repository.dart';
import '../repositories/attachment_repository.dart';
import '../repositories/reminder_repository.dart';

class DeleteTodoUseCase {
  final TodoRepository _todoRepository;
  final AttachmentRepository _attachmentRepository;
  final ReminderRepository _reminderRepository;

  DeleteTodoUseCase(
    this._todoRepository,
    this._attachmentRepository,
    this._reminderRepository,
  );

  Future<void> execute(String todoId, {bool permanent = false}) async {
    final todo = await _todoRepository.getTodoById(todoId);
    if (todo == null) {
      throw Exception('Todo not found');
    }

    if (permanent) {
      // Delete associated attachments
      await _attachmentRepository.deleteAttachmentsForTodo(todoId);
      
      // Delete associated reminders
      final reminders = await _reminderRepository.getRemindersByTodo(todoId);
      for (final reminder in reminders) {
        await _reminderRepository.deleteReminder(reminder.id);
      }
      
      // Permanently delete the todo
      await _todoRepository.deleteTodo(todoId);
    } else {
      // Soft delete - mark as deleted
      final updatedTodo = todo.copyWith(
        isDeleted: true,
        updatedAt: DateTime.now(),
      );
      await _todoRepository.updateTodo(updatedTodo);
    }
  }
}