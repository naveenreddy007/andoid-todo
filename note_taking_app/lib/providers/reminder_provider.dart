import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/local_reminder_repository.dart';
import '../domain/entities/reminder.dart';
import '../domain/repositories/reminder_repository.dart';
import 'todo_provider.dart';
import '../services/local/database_helper.dart';

// Reminder repository provider
final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return LocalReminderRepository(databaseHelper);
});

// Reminders list provider
final remindersProvider = FutureProvider<List<Reminder>>((ref) async {
  final repository = ref.watch(reminderRepositoryProvider);
  return repository.getAllReminders();
});

// Individual reminder provider
final reminderProvider = FutureProvider.family<Reminder?, String>((ref, id) async {
  final repository = ref.watch(reminderRepositoryProvider);
  return repository.getReminderById(id);
});

// Reminders for todo provider
final remindersForTodoProvider = FutureProvider.family<List<Reminder>, String>((
  ref,
  todoId,
) async {
  final repository = ref.watch(reminderRepositoryProvider);
  return repository.getRemindersForTodo(todoId);
});

// Reminders stream for todo provider
final remindersStreamForTodoProvider = StreamProvider.family<List<Reminder>, String>((
  ref,
  todoId,
) {
  final repository = ref.watch(reminderRepositoryProvider);
  return repository.watchRemindersForTodo(todoId);
});

// Active reminders provider
final activeRemindersProvider = FutureProvider<List<Reminder>>((ref) async {
  final repository = ref.watch(reminderRepositoryProvider);
  return repository.getActiveReminders();
});

// Pending reminders provider
final pendingRemindersProvider = FutureProvider<List<Reminder>>((ref) async {
  final repository = ref.watch(reminderRepositoryProvider);
  return repository.getPendingReminders();
});

// Reminders by type provider
final remindersByTypeProvider = FutureProvider.family<List<Reminder>, ReminderType>((ref, type) async {
  final repository = ref.watch(reminderRepositoryProvider);
  return repository.getRemindersByType(type);
});

// Reminder operations notifier
class ReminderOperationsNotifier extends StateNotifier<AsyncValue<void>> {
  final ReminderRepository _repository;

  ReminderOperationsNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> saveReminder(Reminder reminder) async {
    state = const AsyncValue.loading();
    try {
      await _repository.saveReminder(reminder);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateReminder(Reminder reminder) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateReminder(reminder);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteReminder(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteReminder(id);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteAllRemindersForTodo(String todoId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteAllRemindersForTodo(todoId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final reminderOperationsProvider =
    StateNotifierProvider<ReminderOperationsNotifier, AsyncValue<void>>((ref) {
      final repository = ref.watch(reminderRepositoryProvider);
      return ReminderOperationsNotifier(repository);
    });