import '../entities/reminder.dart';
import '../repositories/reminder_repository.dart';
import '../repositories/todo_repository.dart';

class ManageRemindersUseCase {
  final ReminderRepository _reminderRepository;
  final TodoRepository _todoRepository;

  ManageRemindersUseCase(
    this._reminderRepository,
    this._todoRepository,
  );

  Future<String> createReminder({
    required String todoId,
    required DateTime dateTime,
    required ReminderType type,
  }) async {
    // Verify todo exists
    final todo = await _todoRepository.getTodoById(todoId);
    if (todo == null) {
      throw Exception('Todo not found');
    }

    final reminder = Reminder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      todoId: todoId,
      dateTime: dateTime,
      type: type,
      isActive: true,
      createdAt: DateTime.now(),
    );

    await _reminderRepository.saveReminder(reminder);

    // Update todo with reminder ID
    final updatedTodo = todo.copyWith(
      reminderIds: [...todo.reminderIds, reminder.id],
      updatedAt: DateTime.now(),
    );
    await _todoRepository.updateTodo(updatedTodo);

    return reminder.id;
  }

  Future<void> updateReminder({
    required String reminderId,
    DateTime? dateTime,
    ReminderType? type,
    bool? isActive,
  }) async {
    final existingReminder = await _reminderRepository.getReminderById(reminderId);
    if (existingReminder == null) {
      throw Exception('Reminder not found');
    }

    final updatedReminder = existingReminder.copyWith(
      dateTime: dateTime,
      type: type,
      isActive: isActive,
    );

    await _reminderRepository.updateReminder(updatedReminder);
  }

  Future<void> deleteReminder(String reminderId) async {
    final reminder = await _reminderRepository.getReminderById(reminderId);
    if (reminder == null) {
      throw Exception('Reminder not found');
    }

    // Remove reminder from todo
    final todo = await _todoRepository.getTodoById(reminder.todoId);
    if (todo != null) {
      final updatedReminderIds = todo.reminderIds.where((id) => id != reminderId).toList();
      final updatedTodo = todo.copyWith(
        reminderIds: updatedReminderIds,
        updatedAt: DateTime.now(),
      );
      await _todoRepository.updateTodo(updatedTodo);
    }

    await _reminderRepository.deleteReminder(reminderId);
  }

  Future<List<Reminder>> getUpcomingReminders({int hours = 24}) async {
    final cutoffTime = DateTime.now().add(Duration(hours: hours));
    return await _reminderRepository.getUpcomingReminders(cutoffTime);
  }

  Future<List<Reminder>> getRemindersForTodo(String todoId) async {
    return await _reminderRepository.getRemindersByTodo(todoId);
  }

  Future<void> activateReminder(String reminderId) async {
    await _reminderRepository.activateReminder(reminderId);
  }

  Future<void> deactivateReminder(String reminderId) async {
    await _reminderRepository.deactivateReminder(reminderId);
  }
}