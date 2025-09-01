import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../../core/constants/database_constants.dart';
import '../../core/errors/app_exceptions.dart' as app_exceptions;
import '../../domain/entities/reminder.dart';
import '../../domain/entities/todo.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../../services/local/database_helper.dart';
import '../models/reminder_model.dart';

class LocalReminderRepository implements ReminderRepository {
  final DatabaseHelper _databaseHelper;
  final _remindersStreamController = StreamController<List<Reminder>>.broadcast();

  LocalReminderRepository(this._databaseHelper) {
    _databaseHelper.databaseStream.listen((_) {
      getAllReminders().then((reminders) => _remindersStreamController.add(reminders));
    });
  }

  @override
  Future<List<Reminder>> getAllReminders() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.remindersTable,
        orderBy: '${DatabaseConstants.reminderDateTime} ASC',
      );

      return maps.map((map) {
        final reminderModel = ReminderModel.fromJson(map);
        return reminderModel.toEntity();
      }).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get all reminders: $e');
    }
  }

  @override
  Future<Reminder?> getReminderById(String id) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.remindersTable,
        where: '${DatabaseConstants.reminderId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) return null;

      final reminderModel = ReminderModel.fromJson(maps.first);
      return reminderModel.toEntity();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get reminder by id: $e');
    }
  }

  @override
  Future<List<Reminder>> getRemindersForTodo(String todoId) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.remindersTable,
        where: '${DatabaseConstants.reminderTodoId} = ?',
        whereArgs: [todoId],
        orderBy: '${DatabaseConstants.reminderDateTime} ASC',
      );

      return maps.map((map) {
        final reminderModel = ReminderModel.fromJson(map);
        return reminderModel.toEntity();
      }).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get reminders for todo: $e');
    }
  }

  @override
  Future<List<Reminder>> getRemindersByTodo(String todoId) async {
    return getRemindersForTodo(todoId);
  }

  @override
  Future<List<Reminder>> getActiveReminders() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.remindersTable,
        where: '${DatabaseConstants.reminderIsActive} = ?',
        whereArgs: [1],
        orderBy: '${DatabaseConstants.reminderDateTime} ASC',
      );

      return maps.map((map) {
        final reminderModel = ReminderModel.fromJson(map);
        return reminderModel.toEntity();
      }).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get active reminders: $e');
    }
  }

  @override
  Future<List<Reminder>> getPendingReminders() async {
    try {
      final db = await _databaseHelper.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      final maps = await db.query(
        DatabaseConstants.remindersTable,
        where: '${DatabaseConstants.reminderIsActive} = ? AND ${DatabaseConstants.reminderDateTime} <= ?',
        whereArgs: [1, now],
        orderBy: '${DatabaseConstants.reminderDateTime} ASC',
      );

      return maps.map((map) {
        final reminderModel = ReminderModel.fromJson(map);
        return reminderModel.toEntity();
      }).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get pending reminders: $e');
    }
  }

  @override
  Future<List<Reminder>> getRemindersByType(ReminderType type) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.remindersTable,
        where: '${DatabaseConstants.reminderType} = ?',
        whereArgs: [_reminderTypeToString(type)],
        orderBy: '${DatabaseConstants.reminderDateTime} ASC',
      );

      return maps.map((map) {
        final reminderModel = ReminderModel.fromJson(map);
        return reminderModel.toEntity();
      }).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get reminders by type: $e');
    }
  }

  @override
  Future<void> saveReminder(Reminder reminder) async {
    try {
      final db = await _databaseHelper.database;
      final reminderModel = ReminderModel.fromEntity(reminder);
      await db.insert(
        DatabaseConstants.remindersTable,
        reminderModel.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to save reminder: $e');
    }
  }

  @override
  Future<void> updateReminder(Reminder reminder) async {
    try {
      final db = await _databaseHelper.database;
      final reminderModel = ReminderModel.fromEntity(reminder);
      final rowsAffected = await db.update(
        DatabaseConstants.remindersTable,
        reminderModel.toJson(),
        where: '${DatabaseConstants.reminderId} = ?',
        whereArgs: [reminder.id],
      );

      if (rowsAffected == 0) {
        throw app_exceptions.DatabaseException('Reminder not found for update');
      }
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to update reminder: $e');
    }
  }

  @override
  Future<void> deleteReminder(String id) async {
    try {
      final db = await _databaseHelper.database;
      final rowsAffected = await db.delete(
        DatabaseConstants.remindersTable,
        where: '${DatabaseConstants.reminderId} = ?',
        whereArgs: [id],
      );

      if (rowsAffected == 0) {
        throw app_exceptions.DatabaseException('Reminder not found for deletion');
      }
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to delete reminder: $e');
    }
  }

  @override
  Future<void> deleteAllRemindersForTodo(String todoId) async {
    try {
      final db = await _databaseHelper.database;
      await db.delete(
        DatabaseConstants.remindersTable,
        where: '${DatabaseConstants.reminderTodoId} = ?',
        whereArgs: [todoId],
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to delete reminders for todo: $e');
    }
  }

  @override
  Stream<List<Reminder>> watchRemindersForTodo(String todoId) {
    getRemindersForTodo(todoId).then((reminders) => _remindersStreamController.add(reminders));
    return _remindersStreamController.stream;
  }

  @override
  Future<List<Reminder>> getRemindersDueForSync() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.remindersTable,
        orderBy: '${DatabaseConstants.reminderCreatedAt} ASC',
      );

      return maps.map((map) {
        final reminderModel = ReminderModel.fromJson(map);
        return reminderModel.toEntity();
      }).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get reminders due for sync: $e');
    }
  }

  @override
  Future<void> activateReminder(String id) async {
    try {
      final db = await _databaseHelper.database;
      final rowsAffected = await db.update(
        DatabaseConstants.remindersTable,
        {DatabaseConstants.reminderIsActive: 1},
        where: '${DatabaseConstants.reminderId} = ?',
        whereArgs: [id],
      );

      if (rowsAffected == 0) {
        throw app_exceptions.DatabaseException('Reminder not found for activation');
      }
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to activate reminder: $e');
    }
  }

  @override
  Future<void> deactivateReminder(String id) async {
    try {
      final db = await _databaseHelper.database;
      final rowsAffected = await db.update(
        DatabaseConstants.remindersTable,
        {DatabaseConstants.reminderIsActive: 0},
        where: '${DatabaseConstants.reminderId} = ?',
        whereArgs: [id],
      );

      if (rowsAffected == 0) {
        throw app_exceptions.DatabaseException('Reminder not found for deactivation');
      }
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to deactivate reminder: $e');
    }
  }

  @override
  Future<List<Reminder>> getOverdueReminders() async {
    try {
      final db = await _databaseHelper.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      final maps = await db.query(
        DatabaseConstants.remindersTable,
        where: '${DatabaseConstants.reminderIsActive} = ? AND ${DatabaseConstants.reminderDateTime} < ?',
        whereArgs: [1, now],
        orderBy: '${DatabaseConstants.reminderDateTime} ASC',
      );

      return maps.map((map) {
        final reminderModel = ReminderModel.fromJson(map);
        return reminderModel.toEntity();
      }).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get overdue reminders: $e');
    }
  }

  @override
  Future<List<Reminder>> getUpcomingReminders(DateTime before) async {
    try {
      final db = await _databaseHelper.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      final beforeTimestamp = before.millisecondsSinceEpoch;
      final maps = await db.query(
        DatabaseConstants.remindersTable,
        where: '${DatabaseConstants.reminderIsActive} = ? AND ${DatabaseConstants.reminderDateTime} > ? AND ${DatabaseConstants.reminderDateTime} <= ?',
        whereArgs: [1, now, beforeTimestamp],
        orderBy: '${DatabaseConstants.reminderDateTime} ASC',
      );

      return maps.map((map) {
        final reminderModel = ReminderModel.fromJson(map);
        return reminderModel.toEntity();
      }).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get upcoming reminders: $e');
    }
  }

  @override
  Stream<List<Reminder>> watchReminders() {
    getAllReminders().then((reminders) => _remindersStreamController.add(reminders));
    return _remindersStreamController.stream;
  }

  String _reminderTypeToString(ReminderType type) {
    switch (type) {
      case ReminderType.oneTime:
        return 'one_time';
      case ReminderType.recurring:
        return 'recurring';
    }
  }



  void dispose() {
    _remindersStreamController.close();
  }
}