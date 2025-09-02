import 'dart:async';
import 'package:flutter/foundation.dart';
import '../domain/entities/reminder.dart';
import '../domain/entities/todo.dart';
import '../domain/repositories/reminder_repository.dart';
import '../domain/repositories/todo_repository.dart';
import 'notification_service.dart';

class ReminderService {
  final ReminderRepository _reminderRepository;
  final TodoRepository _todoRepository;
  final NotificationService _notificationService;
  
  Timer? _reminderCheckTimer;
  static const Duration _checkInterval = Duration(minutes: 1);

  ReminderService(
    this._reminderRepository,
    this._todoRepository,
    this._notificationService,
  );

  /// Initialize the reminder service
  Future<void> initialize() async {
    await _notificationService.initialize();
    await _scheduleAllActiveReminders();
    _startReminderChecker();
    debugPrint('🔔 ReminderService: Initialized successfully');
  }

  /// Start the periodic reminder checker
  void _startReminderChecker() {
    _reminderCheckTimer?.cancel();
    _reminderCheckTimer = Timer.periodic(_checkInterval, (_) {
      _checkAndTriggerReminders();
    });
  }

  /// Stop the reminder checker
  void dispose() {
    _reminderCheckTimer?.cancel();
  }

  /// Schedule all active reminders
  Future<void> _scheduleAllActiveReminders() async {
    try {
      final activeReminders = await _reminderRepository.getActiveReminders();
      debugPrint('🔔 ReminderService: Scheduling ${activeReminders.length} active reminders');
      
      for (final reminder in activeReminders) {
        await _scheduleReminderNotification(reminder);
      }
    } catch (e) {
      debugPrint('🔔 ReminderService: Error scheduling reminders: $e');
    }
  }

  /// Schedule a single reminder notification
  Future<void> _scheduleReminderNotification(Reminder reminder) async {
    try {
      final todo = await _todoRepository.getTodoById(reminder.todoId);
      if (todo != null && reminder.isActive) {
        await _notificationService.scheduleReminderNotification(
          reminder: reminder,
          todo: todo,
        );
      }
    } catch (e) {
      debugPrint('🔔 ReminderService: Error scheduling reminder ${reminder.id}: $e');
    }
  }

  /// Check for reminders that should trigger now
  Future<void> _checkAndTriggerReminders() async {
    try {
      final now = DateTime.now();
      final pendingReminders = await _reminderRepository.getPendingReminders();
      
      for (final reminder in pendingReminders) {
        if (reminder.dateTime.isBefore(now) || 
            reminder.dateTime.difference(now).inMinutes <= 1) {
          await _triggerReminder(reminder);
        }
      }
    } catch (e) {
      debugPrint('🔔 ReminderService: Error checking reminders: $e');
    }
  }

  /// Trigger a reminder (mark as triggered and handle recurring)
  Future<void> _triggerReminder(Reminder reminder) async {
    try {
      debugPrint('🔔 ReminderService: Triggering reminder ${reminder.id}');
      
      // Handle recurring reminders
      if (reminder.type != ReminderType.oneTime) {
        await _scheduleNextRecurrence(reminder);
      } else {
        // Deactivate one-time reminders after triggering
        await _reminderRepository.deactivateReminder(reminder.id);
      }
    } catch (e) {
      debugPrint('🔔 ReminderService: Error triggering reminder ${reminder.id}: $e');
    }
  }

  /// Schedule the next recurrence for recurring reminders
  Future<void> _scheduleNextRecurrence(Reminder reminder) async {
    try {
      DateTime nextDateTime;
      
      switch (reminder.type) {
        case ReminderType.daily:
          nextDateTime = reminder.dateTime.add(const Duration(days: 1));
          break;
        case ReminderType.weekly:
          nextDateTime = reminder.dateTime.add(const Duration(days: 7));
          break;
        case ReminderType.monthly:
          nextDateTime = DateTime(
            reminder.dateTime.year,
            reminder.dateTime.month + 1,
            reminder.dateTime.day,
            reminder.dateTime.hour,
            reminder.dateTime.minute,
          );
          break;
        case ReminderType.oneTime:
          return; // No recurrence for one-time reminders
      }
      
      // Update the reminder with the new date
      final updatedReminder = reminder.copyWith(dateTime: nextDateTime);
      await _reminderRepository.updateReminder(updatedReminder);
      
      // Schedule the notification for the new date
      await _scheduleReminderNotification(updatedReminder);
      
      debugPrint('🔔 ReminderService: Scheduled next recurrence for ${reminder.id} at $nextDateTime');
    } catch (e) {
      debugPrint('🔔 ReminderService: Error scheduling next recurrence for ${reminder.id}: $e');
    }
  }

  /// Create and schedule a new reminder
  Future<void> createReminder({
    required String todoId,
    required DateTime dateTime,
    required ReminderType type,
    bool isActive = true,
  }) async {
    try {
      final reminder = Reminder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        todoId: todoId,
        dateTime: dateTime,
        type: type,
        isActive: isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _reminderRepository.saveReminder(reminder);
      
      if (isActive) {
        await _scheduleReminderNotification(reminder);
      }
      
      debugPrint('🔔 ReminderService: Created reminder ${reminder.id}');
    } catch (e) {
      debugPrint('🔔 ReminderService: Error creating reminder: $e');
      rethrow;
    }
  }

  /// Update an existing reminder
  Future<void> updateReminder({
    required String reminderId,
    DateTime? dateTime,
    ReminderType? type,
    bool? isActive,
  }) async {
    try {
      final existingReminder = await _reminderRepository.getReminderById(reminderId);
      if (existingReminder == null) {
        throw Exception('Reminder not found: $reminderId');
      }
      
      // Cancel existing notification
      await _notificationService.cancelReminderNotification(reminderId);
      
      // Update reminder
      final updatedReminder = existingReminder.copyWith(
        dateTime: dateTime,
        type: type,
        isActive: isActive,
        updatedAt: DateTime.now(),
      );
      
      await _reminderRepository.updateReminder(updatedReminder);
      
      // Schedule new notification if active
      if (updatedReminder.isActive) {
        await _scheduleReminderNotification(updatedReminder);
      }
      
      debugPrint('🔔 ReminderService: Updated reminder $reminderId');
    } catch (e) {
      debugPrint('🔔 ReminderService: Error updating reminder $reminderId: $e');
      rethrow;
    }
  }

  /// Delete a reminder
  Future<void> deleteReminder(String reminderId) async {
    try {
      await _notificationService.cancelReminderNotification(reminderId);
      await _reminderRepository.deleteReminder(reminderId);
      debugPrint('🔔 ReminderService: Deleted reminder $reminderId');
    } catch (e) {
      debugPrint('🔔 ReminderService: Error deleting reminder $reminderId: $e');
      rethrow;
    }
  }

  /// Activate a reminder
  Future<void> activateReminder(String reminderId) async {
    try {
      await _reminderRepository.activateReminder(reminderId);
      
      final reminder = await _reminderRepository.getReminderById(reminderId);
      if (reminder != null) {
        await _scheduleReminderNotification(reminder);
      }
      
      debugPrint('🔔 ReminderService: Activated reminder $reminderId');
    } catch (e) {
      debugPrint('🔔 ReminderService: Error activating reminder $reminderId: $e');
      rethrow;
    }
  }

  /// Deactivate a reminder
  Future<void> deactivateReminder(String reminderId) async {
    try {
      await _notificationService.cancelReminderNotification(reminderId);
      await _reminderRepository.deactivateReminder(reminderId);
      debugPrint('🔔 ReminderService: Deactivated reminder $reminderId');
    } catch (e) {
      debugPrint('🔔 ReminderService: Error deactivating reminder $reminderId: $e');
      rethrow;
    }
  }

  /// Get upcoming reminders
  Future<List<Reminder>> getUpcomingReminders({int hours = 24}) async {
    final cutoffTime = DateTime.now().add(Duration(hours: hours));
    return await _reminderRepository.getUpcomingReminders(cutoffTime);
  }

  /// Get reminders for a specific todo
  Future<List<Reminder>> getRemindersForTodo(String todoId) async {
    return await _reminderRepository.getRemindersForTodo(todoId);
  }

  /// Get all active reminders
  Future<List<Reminder>> getActiveReminders() async {
    return await _reminderRepository.getActiveReminders();
  }

  /// Reschedule all reminders (useful after app restart)
  Future<void> rescheduleAllReminders() async {
    try {
      // Cancel all existing notifications
      await _notificationService.cancelAllNotifications();
      
      // Reschedule all active reminders
      await _scheduleAllActiveReminders();
      
      debugPrint('🔔 ReminderService: Rescheduled all reminders');
    } catch (e) {
      debugPrint('🔔 ReminderService: Error rescheduling reminders: $e');
    }
  }

  /// Show a test notification
  Future<void> showTestNotification() async {
    await _notificationService.showImmediateNotification(
      title: '🔔 Test Notification',
      body: 'Reminder notifications are working correctly!',
      payload: 'test_notification',
    );
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    return await _notificationService.areNotificationsEnabled();
  }

  /// Open notification settings
  Future<void> openNotificationSettings() async {
    await _notificationService.openNotificationSettings();
  }
}