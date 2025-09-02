import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/local_reminder_repository.dart';
import '../domain/entities/reminder.dart';
import '../domain/repositories/reminder_repository.dart';
import '../services/notification_service.dart';
import '../services/reminder_service.dart';
import 'todo_provider.dart';
import '../services/local/database_helper.dart';

// Reminder repository provider
final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return LocalReminderRepository(databaseHelper);
});

// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Reminder service provider
final reminderServiceProvider = Provider<ReminderService>((ref) {
  final reminderRepository = ref.watch(reminderRepositoryProvider);
  final todoRepository = ref.watch(todoRepositoryProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return ReminderService(reminderRepository, todoRepository, notificationService);
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

// Enhanced reminder operations notifier with notification support
class ReminderOperationsNotifier extends StateNotifier<AsyncValue<void>> {
  final ReminderService _reminderService;
  final Ref _ref;

  ReminderOperationsNotifier(this._reminderService, this._ref) : super(const AsyncValue.data(null));

  Future<void> createReminder({
    required String todoId,
    required DateTime dateTime,
    required ReminderType type,
    bool isActive = true,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _reminderService.createReminder(
        todoId: todoId,
        dateTime: dateTime,
        type: type,
        isActive: isActive,
      );
      state = const AsyncValue.data(null);
      _invalidateProviders();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateReminder({
    required String reminderId,
    DateTime? dateTime,
    ReminderType? type,
    bool? isActive,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _reminderService.updateReminder(
        reminderId: reminderId,
        dateTime: dateTime,
        type: type,
        isActive: isActive,
      );
      state = const AsyncValue.data(null);
      _invalidateProviders();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    state = const AsyncValue.loading();
    try {
      await _reminderService.deleteReminder(reminderId);
      state = const AsyncValue.data(null);
      _invalidateProviders();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> activateReminder(String reminderId) async {
    state = const AsyncValue.loading();
    try {
      await _reminderService.activateReminder(reminderId);
      state = const AsyncValue.data(null);
      _invalidateProviders();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deactivateReminder(String reminderId) async {
    state = const AsyncValue.loading();
    try {
      await _reminderService.deactivateReminder(reminderId);
      state = const AsyncValue.data(null);
      _invalidateProviders();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> rescheduleAllReminders() async {
    state = const AsyncValue.loading();
    try {
      await _reminderService.rescheduleAllReminders();
      state = const AsyncValue.data(null);
      _invalidateProviders();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> showTestNotification() async {
    try {
      await _reminderService.showTestNotification();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<bool> areNotificationsEnabled() async {
    return await _reminderService.areNotificationsEnabled();
  }

  Future<void> openNotificationSettings() async {
    await _reminderService.openNotificationSettings();
  }

  void _invalidateProviders() {
    _ref.invalidate(remindersProvider);
    _ref.invalidate(activeRemindersProvider);
    _ref.invalidate(pendingRemindersProvider);
  }
}

final reminderOperationsProvider =
    StateNotifierProvider<ReminderOperationsNotifier, AsyncValue<void>>((ref) {
      final reminderService = ref.watch(reminderServiceProvider);
      return ReminderOperationsNotifier(reminderService, ref);
    });

// Upcoming reminders provider
final upcomingRemindersProvider = FutureProvider.family<List<Reminder>, int>((ref, hours) async {
  final reminderService = ref.watch(reminderServiceProvider);
  return reminderService.getUpcomingReminders(hours: hours);
});

// Reminder service initialization provider
final reminderServiceInitProvider = FutureProvider<void>((ref) async {
  final reminderService = ref.watch(reminderServiceProvider);
  await reminderService.initialize();
});

// Notification status provider
final notificationStatusProvider = FutureProvider<bool>((ref) async {
  final reminderService = ref.watch(reminderServiceProvider);
  return reminderService.areNotificationsEnabled();
});

// Reminder statistics provider
final reminderStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final reminderService = ref.watch(reminderServiceProvider);
  final activeReminders = await reminderService.getActiveReminders();
  final upcomingReminders = await reminderService.getUpcomingReminders(hours: 24);
  
  final stats = <String, int>{};
  stats['total'] = activeReminders.length;
  stats['upcoming_24h'] = upcomingReminders.length;
  stats['one_time'] = activeReminders.where((r) => r.type == ReminderType.oneTime).length;
  stats['daily'] = activeReminders.where((r) => r.type == ReminderType.daily).length;
  stats['weekly'] = activeReminders.where((r) => r.type == ReminderType.weekly).length;
  stats['monthly'] = activeReminders.where((r) => r.type == ReminderType.monthly).length;
  
  return stats;
});