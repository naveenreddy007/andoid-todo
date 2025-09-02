import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/todo.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/todo_provider.dart';

class ReminderFormDialog extends ConsumerStatefulWidget {
  final Reminder? reminder;

  const ReminderFormDialog({super.key, this.reminder});

  @override
  ConsumerState<ReminderFormDialog> createState() => _ReminderFormDialogState();
}

class _ReminderFormDialogState extends ConsumerState<ReminderFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
  RecurrenceType _recurrenceType = RecurrenceType.none;
  String? _selectedTodoId;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.reminder != null) {
      _titleController.text = widget.reminder!.title;
      _messageController.text = widget.reminder!.message;
      _selectedDateTime = widget.reminder!.dateTime;
      _recurrenceType = widget.reminder!.recurrenceType;
      _selectedTodoId = widget.reminder!.todoId;
      _isActive = widget.reminder!.isActive;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todos = ref.watch(todosProvider);
    
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.reminder == null
                        ? Icons.add_alarm_outlined
                        : Icons.edit_outlined,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.reminder == null
                          ? 'Create Reminder'
                          : 'Edit Reminder',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            
            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title field
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          hintText: 'Enter reminder title',
                          prefixIcon: Icon(Icons.title_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Message field
                      TextFormField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          hintText: 'Enter reminder message (optional)',
                          prefixIcon: Icon(Icons.message_outlined),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Date and time selection
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date & Time',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _selectDate(context),
                                      icon: const Icon(Icons.calendar_today_outlined),
                                      label: Text(
                                        DateFormat('MMM d, y').format(_selectedDateTime),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _selectTime(context),
                                      icon: const Icon(Icons.access_time_outlined),
                                      label: Text(
                                        DateFormat('h:mm a').format(_selectedDateTime),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 8),
                              
                              Text(
                                _getDateTimeDescription(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: _selectedDateTime.isBefore(DateTime.now())
                                      ? theme.colorScheme.error
                                      : theme.colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Recurrence selection
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recurrence',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              Wrap(
                                spacing: 8,
                                children: RecurrenceType.values.map((type) {
                                  final isSelected = _recurrenceType == type;
                                  return FilterChip(
                                    label: Text(_getRecurrenceLabel(type)),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        _recurrenceType = type;
                                      });
                                    },
                                    avatar: isSelected
                                        ? Icon(
                                            _getRecurrenceIcon(type),
                                            size: 16,
                                            color: theme.colorScheme.onSecondaryContainer,
                                          )
                                        : null,
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Todo association
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Associate with Todo (Optional)',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              todos.when(
                                data: (todoList) {
                                  final incompleteTodos = todoList
                                      .where((todo) => !todo.isCompleted)
                                      .toList();
                                  
                                  if (incompleteTodos.isEmpty) {
                                    return Text(
                                      'No incomplete todos available',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    );
                                  }
                                  
                                  return DropdownButtonFormField<String?>(
                                    value: _selectedTodoId,
                                    decoration: const InputDecoration(
                                      labelText: 'Select Todo',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.task_outlined),
                                    ),
                                    items: [
                                      const DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text('None'),
                                      ),
                                      ...incompleteTodos.map((todo) {
                                        return DropdownMenuItem<String?>(
                                          value: todo.id,
                                          child: Text(
                                            todo.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedTodoId = value;
                                      });
                                    },
                                  );
                                },
                                loading: () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                error: (_, __) => Text(
                                  'Error loading todos',
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Active toggle
                      Card(
                        child: SwitchListTile(
                          title: const Text('Active'),
                          subtitle: Text(
                            _isActive
                                ? 'Reminder will trigger notifications'
                                : 'Reminder is paused',
                          ),
                          value: _isActive,
                          onChanged: (value) {
                            setState(() {
                              _isActive = value;
                            });
                          },
                          secondary: Icon(
                            _isActive
                                ? Icons.notifications_active_outlined
                                : Icons.notifications_off_outlined,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Action buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveReminder,
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.reminder == null ? 'Create' : 'Update'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    
    if (time != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  String _getDateTimeDescription() {
    final now = DateTime.now();
    final difference = _selectedDateTime.difference(now);
    
    if (difference.isNegative) {
      return 'This time is in the past';
    }
    
    if (difference.inMinutes < 60) {
      return 'In ${difference.inMinutes} minutes';
    } else if (difference.inHours < 24) {
      return 'In ${difference.inHours} hours';
    } else {
      return 'In ${difference.inDays} days';
    }
  }

  String _getRecurrenceLabel(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.none:
        return 'One-time';
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
    }
  }

  IconData _getRecurrenceIcon(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.none:
        return Icons.event_outlined;
      case RecurrenceType.daily:
        return Icons.today_outlined;
      case RecurrenceType.weekly:
        return Icons.view_week_outlined;
      case RecurrenceType.monthly:
        return Icons.calendar_month_outlined;
    }
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a future date and time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final reminder = Reminder(
        id: widget.reminder?.id ?? '',
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        dateTime: _selectedDateTime,
        recurrenceType: _recurrenceType,
        isActive: _isActive,
        todoId: _selectedTodoId,
        createdAt: widget.reminder?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.reminder == null) {
        await ref.read(reminderOperationsProvider.notifier).createReminder(reminder);
      } else {
        await ref.read(reminderOperationsProvider.notifier).updateReminder(reminder);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.reminder == null
                  ? 'Reminder created successfully'
                  : 'Reminder updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}