import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../domain/entities/todo.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/priority.dart';
import '../../domain/entities/todo_status.dart';
import '../../providers/providers.dart';
import '../../core/utils/id_generator.dart';
import '../../core/utils/date_time_utils.dart';


class TodoEditorScreen extends ConsumerStatefulWidget {
  final Todo? todo;

  const TodoEditorScreen({super.key, this.todo});

  @override
  ConsumerState<TodoEditorScreen> createState() => _TodoEditorScreenState();
}

class _TodoEditorScreenState extends ConsumerState<TodoEditorScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isEditing = false;
  Priority _selectedPriority = Priority.medium;
  DateTime? _dueDate;
  String? _selectedCategoryId;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeEditor();
  }

  void _initializeEditor() {
    if (widget.todo != null) {
      _titleController.text = widget.todo!.title;
      _descriptionController.text = widget.todo!.description ?? '';
      _selectedPriority = widget.todo!.priority;
      _dueDate = widget.todo!.dueDate;
      _selectedCategoryId = widget.todo!.categoryId;
      _isCompleted = widget.todo!.isCompleted;
      _isEditing = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsyncValue = ref.watch(categoriesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Todo' : 'New Todo'),
        actions: [
          IconButton(
            icon: const Icon(Symbols.schedule),
            onPressed: _showDueDatePicker,
          ),
          IconButton(
            icon: const Icon(Symbols.category),
            onPressed: () => _showCategoryPicker(categoriesAsyncValue),
          ),
          IconButton(
            icon: const Icon(Symbols.priority_high),
            onPressed: _showPriorityPicker,
          ),
          IconButton(
            icon: const Icon(Symbols.save),
            onPressed: _saveTodo,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title field
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Todo title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Symbols.task_alt),
              ),
              style: Theme.of(context).textTheme.titleLarge,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            
            // Description field
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Description (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Symbols.description),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            
            // Completion status (only show when editing)
            if (_isEditing) ...[
              Card(
                child: SwitchListTile(
                  title: const Text('Completed'),
                  subtitle: Text(_isCompleted ? 'This todo is completed' : 'Mark as completed'),
                  value: _isCompleted,
                  onChanged: (value) {
                    setState(() {
                      _isCompleted = value;
                    });
                  },
                  secondary: Icon(
                    _isCompleted ? Symbols.check_circle : Symbols.radio_button_unchecked,
                    color: _isCompleted ? Colors.green : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Due date
            Card(
              child: ListTile(
                leading: const Icon(Symbols.schedule),
                title: const Text('Due Date'),
                subtitle: _dueDate != null
                    ? Text(DateTimeUtils.formatDateTime(_dueDate!))
                    : const Text('No due date set'),
                trailing: _dueDate != null
                    ? IconButton(
                        icon: const Icon(Symbols.close),
                        onPressed: () {
                          setState(() {
                            _dueDate = null;
                          });
                        },
                      )
                    : const Icon(Symbols.chevron_right),
                onTap: _showDueDatePicker,
              ),
            ),
            const SizedBox(height: 16),
            
            // Category
            Card(
              child: categoriesAsyncValue.when(
                data: (categories) {
                  final selectedCategory = categories.firstWhere(
                    (cat) => cat.id == _selectedCategoryId,
                    orElse: () => Category(
                      id: '',
                      name: 'No category',
                      color: '#9E9E9E',
                      icon: 'category',
                      createdAt: DateTime.now(),
                    ),
                  );
                  
                  return ListTile(
                    leading: Icon(
                      selectedCategory.icon != null 
                        ? IconData(int.tryParse(selectedCategory.icon!) ?? Symbols.category.codePoint, fontFamily: 'MaterialSymbolsOutlined')
                        : Symbols.category,
                      color: Color(int.tryParse(selectedCategory.color.replaceAll('#', '0xFF')) ?? 0xFF2196F3),
                    ),
                    title: const Text('Category'),
                    subtitle: Text(selectedCategory.name),
                    trailing: const Icon(Symbols.chevron_right),
                    onTap: () => _showCategoryPicker(categoriesAsyncValue),
                  );
                },
                loading: () => const ListTile(
                  leading: Icon(Symbols.category),
                  title: Text('Category'),
                  subtitle: Text('Loading...'),
                ),
                error: (error, stack) => ListTile(
                  leading: const Icon(Symbols.category),
                  title: const Text('Category'),
                  subtitle: Text('Error: $error'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Priority
            Card(
              child: ListTile(
                leading: Icon(
                  Symbols.priority_high,
                  color: _getPriorityColor(_selectedPriority),
                ),
                title: const Text('Priority'),
                subtitle: Text(_selectedPriority.name.toUpperCase()),
                trailing: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getPriorityColor(_selectedPriority),
                    shape: BoxShape.circle,
                  ),
                ),
                onTap: _showPriorityPicker,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDueDatePicker() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (date != null && mounted) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dueDate ?? DateTime.now()),
      );

      if (time != null && mounted) {
        setState(() {
          _dueDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _showCategoryPicker(AsyncValue<List<Category>> categoriesAsyncValue) {
    categoriesAsyncValue.when(
      data: (categories) {
        showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Select Category'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    leading: const Icon(Symbols.clear),
                    title: const Text('No Category'),
                    onTap: () {
                      setState(() {
                        _selectedCategoryId = null;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(),
                  ...categories.map((category) {
                    return ListTile(
                      leading: Icon(
                        category.icon != null 
                          ? IconData(int.tryParse(category.icon!) ?? Symbols.category.codePoint, fontFamily: 'MaterialSymbolsOutlined')
                          : Symbols.category,
                        color: Color(int.tryParse(category.color.replaceAll('#', '0xFF')) ?? 0xFF2196F3),
                      ),
                      title: Text(category.name),
                      selected: _selectedCategoryId == category.id,
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = category.id;
                        });
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading categories...')),
      ),
      error: (error, stack) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading categories: $error')),
      ),
    );
  }

  void _showPriorityPicker() {
    showDialog<Priority>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Priority'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: Priority.values.map((priority) {
            return ListTile(
              title: Text(priority.name.toUpperCase()),
              leading: Icon(
                _selectedPriority == priority
                    ? Symbols.radio_button_checked
                    : Symbols.radio_button_unchecked,
                color: Theme.of(context).colorScheme.primary,
              ),
              trailing: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getPriorityColor(priority),
                  shape: BoxShape.circle,
                ),
              ),
              onTap: () {
                setState(() {
                  _selectedPriority = priority;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
      case Priority.urgent:
        return Colors.purple;
    }
  }

  void _saveTodo() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    final now = DateTime.now();
    final todo = Todo(
      id: widget.todo?.id ?? IdGenerator.generateId(),
      title: title,
      description: description.isEmpty ? null : description,
      status: _isCompleted ? TodoStatus.completed : TodoStatus.pending,
      priority: _selectedPriority,
      dueDate: _dueDate,
      categoryId: _selectedCategoryId,
      tagIds: widget.todo?.tagIds ?? [],
      createdAt: widget.todo?.createdAt ?? now,
      updatedAt: now,
      completedAt: _isCompleted ? (widget.todo?.completedAt ?? now) : null,
      syncStatus: SyncStatus.pending,
      lastSynced: widget.todo?.lastSynced,
      cloudFileId: widget.todo?.cloudFileId,
      attachmentIds: widget.todo?.attachmentIds ?? [],
      reminderIds: widget.todo?.reminderIds ?? [],
    );

    try {
      final operations = ref.read(todoOperationsProvider.notifier);
      if (_isEditing) {
        await operations.updateTodo(todo);
      } else {
        await operations.saveTodo(todo);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todo saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save todo: $e')),
        );
      }
    }
  }
}