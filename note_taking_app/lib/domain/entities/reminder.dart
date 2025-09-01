import 'package:equatable/equatable.dart';

enum ReminderType { oneTime, recurring }

class Reminder extends Equatable {
  final String id;
  final String todoId;
  final DateTime dateTime;
  final ReminderType type;
  final bool isActive;
  final DateTime createdAt;

  const Reminder({
    required this.id,
    required this.todoId,
    required this.dateTime,
    this.type = ReminderType.oneTime,
    this.isActive = true,
    required this.createdAt,
  });

  Reminder copyWith({
    String? id,
    String? todoId,
    DateTime? dateTime,
    ReminderType? type,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      todoId: todoId ?? this.todoId,
      dateTime: dateTime ?? this.dateTime,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        todoId,
        dateTime,
        type,
        isActive,
        createdAt,
      ];
}