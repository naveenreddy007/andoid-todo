import '../entities/reminder.dart';

abstract class ReminderRepository {
  Future<List<Reminder>> getAllReminders();
  Future<Reminder?> getReminderById(String id);
  Future<void> saveReminder(Reminder reminder);
  Future<void> updateReminder(Reminder reminder);
  Future<void> deleteReminder(String id);
  Future<void> deleteAllRemindersForTodo(String todoId);
  Future<void> activateReminder(String id);
  Future<void> deactivateReminder(String id);
  Stream<List<Reminder>> watchReminders();
  Future<List<Reminder>> getRemindersByTodo(String todoId);
  Future<List<Reminder>> getRemindersForTodo(String todoId);
  Stream<List<Reminder>> watchRemindersForTodo(String todoId);
  Future<List<Reminder>> getActiveReminders();
  Future<List<Reminder>> getPendingReminders();
  Future<List<Reminder>> getRemindersByType(ReminderType type);
  Future<List<Reminder>> getUpcomingReminders(DateTime before);
  Future<List<Reminder>> getOverdueReminders();
  Future<List<Reminder>> getRemindersDueForSync();
}