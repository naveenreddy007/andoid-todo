import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../domain/entities/todo.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/priority.dart';
import '../../domain/entities/todo_status.dart';
import '../../domain/entities/tag.dart';
import '../../providers/providers.dart';
import '../../providers/tag_provider.dart';
import '../../core/utils/id_generator.dart';
import '../../core/utils/date_time_utils.dart';
import 'tags_screen.dart';


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
  List<String> _selectedTagIds = [];

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
      _selectedTagIds = List.from(widget.todo!.tagIds);
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
            icon: const Icon(Symbols.label),
            onPressed: _showTagPicker,
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
            const SizedBox(height: 16),
            
            // Tags
            Card(
              child: Consumer(
                builder: (context, ref, child) {
                  final tagsAsyncValue = ref.watch(tagsProvider);
                  return tagsAsyncValue.when(
                    data: (allTags) {
                      final selectedTags = allTags.where((tag) => _selectedTagIds.contains(tag.id)).toList();
                      return ListTile(
                        leading: const Icon(Symbols.label),
                        title: const Text('Tags'),
                        subtitle: selectedTags.isEmpty
                            ? const Text('No tags selected')
                            : Wrap(
                                spacing: 4,
                                children: selectedTags.take(3).map((tag) {
                                  return Chip(
                                    label: Text(
                                      tag.name,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: Color(int.tryParse(tag.color.replaceAll('#', '0xFF')) ?? 0xFF2196F3).withOpacity(0.2),
                                    side: BorderSide(
                                      color: Color(int.tryParse(tag.color.replaceAll('#', '0xFF')) ?? 0xFF2196F3),
                                    ),
                                  );
                                }).toList(),
                              ),
                        trailing: selectedTags.length > 3
                            ? Text('+${selectedTags.length - 3} more')
                            : const Icon(Symbols.chevron_right),
                        onTap: _showTagPicker,
                      );
                    },
                    loading: () => const ListTile(
                      leading: Icon(Symbols.label),
                      title: Text('Tags'),
                      subtitle: Text('Loading...'),
                    ),
                    error: (error, stack) => ListTile(
                      leading: const Icon(Symbols.label),
                      title: const Text('Tags'),
                      subtitle: Text('Error: $error'),
                    ),
                  );
                },
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

  void _showTagPicker() {
    final tagsAsyncValue = ref.read(tagsProvider);
    tagsAsyncValue.when(
      data: (allTags) {
        showDialog(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Select Tags'),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 400,
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          children: allTags.map((tag) {
                            final isSelected = _selectedTagIds.contains(tag.id);
                            return CheckboxListTile(
                              title: Text(tag.name),
                              subtitle: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Color(int.tryParse(tag.color.replaceAll('#', '0xFF')) ?? 0xFF2196F3),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              value: isSelected,
                              onChanged: (bool? value) {
                                setDialogState(() {
                                  if (value == true) {
                                    _selectedTagIds.add(tag.id);
                                  } else {
                                    _selectedTagIds.remove(tag.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TagsScreen(),
                                ),
                              ).then((_) {
                                // Refresh tags after returning from tags screen
                                ref.invalidate(tagsProvider);
                                Navigator.pop(context);
                              });
                            },
                            child: const Text('Manage Tags'),
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    // Update the main screen state
                                  });
                                  Navigator.pop(context);
                                },
                                child: const Text('Done'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading tags...')),
      ),
      error: (error, stack) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading tags: $error')),
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

    print('🔍 DEBUG: Starting _saveTodo - Title: "$title", IsEditing: $_isEditing');

    if (title.isEmpty) {
      print('❌ DEBUG: Title is empty, showing error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    final now = DateTime.now();
    final todoId = widget.todo?.id ?? IdGenerator.generateId();
    final todo = Todo(
      id: todoId,
      title: title,
      description: description.isEmpty ? null : description,
      status: _isCompleted ? TodoStatus.completed : TodoStatus.pending,
      priority: _selectedPriority,
      dueDate: _dueDate,
      categoryId: _selectedCategoryId,
      tagIds: _selectedTagIds,
      createdAt: widget.todo?.createdAt ?? now,
      updatedAt: now,
      completedAt: _isCompleted ? (widget.todo?.completedAt ?? now) : null,
      syncStatus: SyncStatus.pending,
      lastSynced: widget.todo?.lastSynced,
      cloudFileId: widget.todo?.cloudFileId,
      attachmentIds: widget.todo?.attachmentIds ?? [],
      reminderIds: widget.todo?.reminderIds ?? [],
    );

    print('📝 DEBUG: Created todo object - ID: $todoId, Title: "${todo.title}", Status: ${todo.status}');

    try {
      final operations = ref.read(todoOperationsProvider.notifier);
      print('🔄 DEBUG: Got operations provider, calling ${_isEditing ? "updateTodo" : "saveTodo"}');
      
      if (_isEditing) {
        await operations.updateTodo(todo);
        print('✅ DEBUG: updateTodo completed successfully');
      } else {
        await operations.saveTodo(todo);
        print('✅ DEBUG: saveTodo completed successfully');
      }

      if (mounted) {
        print('🏠 DEBUG: Navigating back and showing success message');
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todo saved successfully')),
        );
      }
    } catch (e) {
      print('❌ DEBUG: Error saving todo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save todo: $e')),
        );
      }
    }
  }
}