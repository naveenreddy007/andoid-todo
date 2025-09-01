import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../domain/entities/note.dart';
import '../../providers/note_provider.dart';
import '../../core/utils/id_generator.dart';
import '../../core/utils/date_time_utils.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final Note? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  final TextEditingController _titleController = TextEditingController();
  late QuillController _contentController;

  bool _isEditing = false;
  Priority _selectedPriority = Priority.medium;
  DateTime? _reminderDate;

  @override
  void initState() {
    super.initState();
    _contentController = QuillController.basic();
    _initializeEditor();
  }

  void _initializeEditor() {
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _selectedPriority = widget.note!.priority;
      _reminderDate = widget.note!.reminderDate;
      _isEditing = true;

      // Set the HTML content
      if (widget.note!.content.isNotEmpty) {
        try {
          final doc = Document.fromJson(jsonDecode(widget.note!.content));
          _contentController = QuillController(
            document: doc,
            selection: const TextSelection.collapsed(offset: 0),
          );
        } catch (e) {
          final doc = Document()..insert(0, widget.note!.content);
          _contentController = QuillController(
            document: doc,
            selection: const TextSelection.collapsed(offset: 0),
          );
        }
      } else {
        _contentController = QuillController.basic();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Note' : 'New Note'),
        actions: [
          IconButton(
            icon: const Icon(Symbols.schedule),
            onPressed: _showReminderPicker,
          ),
          IconButton(
            icon: const Icon(Symbols.priority_high),
            onPressed: _showPriorityPicker,
          ),
          IconButton(icon: const Icon(Symbols.save), onPressed: _saveNote),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'Note title',
                    border: InputBorder.none,
                  ),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (_reminderDate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Symbols.schedule,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Reminder: ${DateTimeUtils.formatDateTime(_reminderDate!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Symbols.close, size: 16),
                        onPressed: () {
                          setState(() {
                            _reminderDate = null;
                          });
                        },
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Symbols.priority_high,
                      size: 16,
                      color: _getPriorityColor(_selectedPriority),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Priority: ${_selectedPriority.name.toUpperCase()}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getPriorityColor(_selectedPriority),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          QuillToolbar.simple(
            configurations: QuillSimpleToolbarConfigurations(
              controller: _contentController,
              sharedConfigurations: const QuillSharedConfigurations(
                locale: Locale('en'),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: QuillEditor.basic(
                configurations: QuillEditorConfigurations(
                  controller: _contentController,
                  readOnly: false,
                  sharedConfigurations: const QuillSharedConfigurations(
                    locale: Locale('en'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReminderPicker() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _reminderDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_reminderDate ?? DateTime.now()),
      );

      if (time != null && mounted) {
        setState(() {
          _reminderDate = DateTime(
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
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
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
    }
  }

  void _saveNote() async {
    final title = _titleController.text.trim();
    final content = jsonEncode(_contentController.document.toDelta().toJson());
    final plainText = _contentController.document.toPlainText();

    if (title.isEmpty && plainText.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Note cannot be empty')));
      return;
    }

    final now = DateTime.now();
    final note = Note(
      id: widget.note?.id ?? IdGenerator.generateId(),
      title: title,
      content: content,
      plainText: plainText, // For search
      createdAt: widget.note?.createdAt ?? now,
      updatedAt: now,
      reminderDate: _reminderDate,
      priority: _selectedPriority,
      categoryId: widget.note?.categoryId,
      tagIds: widget.note?.tagIds ?? [],
      isArchived: widget.note?.isArchived ?? false,
      isDeleted: widget.note?.isDeleted ?? false,
      syncStatus: SyncStatus.pending,
      lastSynced: widget.note?.lastSynced,
      cloudFileId: widget.note?.cloudFileId,
      attachmentIds: widget.note?.attachmentIds ?? [],
    );

    try {
      final operations = ref.read(noteOperationsProvider.notifier);
      if (_isEditing) {
        await operations.updateNote(note);
      } else {
        await operations.saveNote(note);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save note: $e')));
      }
    }
  }
}
