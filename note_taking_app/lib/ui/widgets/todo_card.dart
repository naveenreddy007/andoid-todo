import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/utils/date_time_utils.dart';
import '../../domain/entities/todo.dart';
import '../../domain/entities/priority.dart';
import '../../domain/entities/todo_status.dart';
import '../../providers/todo_provider.dart';
import '../../providers/tag_provider.dart';
import '../theme/app_theme.dart';

class TodoCard extends StatelessWidget {
  final Todo todo;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;

  const TodoCard({
    super.key,
    required this.todo,
    this.onTap,
    this.onComplete,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(12);
    final isCompleted = todo.isCompleted;
    final isOverdue = todo.dueDate != null && 
        todo.dueDate!.isBefore(DateTime.now()) && 
        !isCompleted;

    return AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isCompleted
                    ? [
                        Colors.green.withValues(alpha: isDark ? 0.15 : 0.08),
                        Colors.green.withValues(alpha: isDark ? 0.08 : 0.04),
                      ]
                    : isOverdue
                        ? [
                            Colors.red.withValues(alpha: isDark ? 0.15 : 0.08),
                            Colors.red.withValues(alpha: isDark ? 0.08 : 0.04),
                          ]
                        : isDark
                            ? [
                                Colors.white.withValues(alpha: 0.06),
                                Colors.white.withValues(alpha: 0.03),
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.55),
                                Colors.white.withValues(alpha: 0.35),
                              ],
              ),
              border: Border.all(
                color: isCompleted
                    ? Colors.green.withValues(alpha: isDark ? 0.3 : 0.2)
                    : isOverdue
                        ? Colors.red.withValues(alpha: isDark ? 0.3 : 0.2)
                        : isDark
                            ? Colors.white.withValues(alpha: 0.10)
                            : Colors.white.withValues(alpha: 0.40),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.35)
                      : Colors.grey.shade300.withValues(alpha: 0.7),
                  blurRadius: 18,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
              borderRadius: borderRadius,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                borderRadius: borderRadius,
                splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                highlightColor: theme.colorScheme.primary.withValues(alpha: 0.04),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Completion checkbox
                          GestureDetector(
                            onTap: onComplete,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isCompleted
                                      ? Colors.green
                                      : theme.colorScheme.outline,
                                  width: 2,
                                ),
                                color: isCompleted
                                    ? Colors.green
                                    : Colors.transparent,
                              ),
                              child: isCompleted
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              todo.title.isEmpty ? 'Untitled' : todo.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isCompleted
                                    ? (isDark
                                        ? Colors.white.withValues(alpha: 0.6)
                                        : Colors.black.withValues(alpha: 0.5))
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.95)
                                        : Colors.black.withValues(alpha: 0.85)),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildPriorityIndicator(context),
                        ],
                      ),
                      if (todo.description != null && todo.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          opacity: isCompleted ? 0.6 : 1,
                          child: Text(
                            todo.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.35,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.82)
                                  : Colors.black.withValues(alpha: 0.70),
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Due date indicator
                          if (todo.dueDate != null) ...[
                            Icon(
                              Symbols.schedule,
                              size: 16,
                              color: isOverdue
                                  ? Colors.red
                                  : theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: isDark ? 0.8 : 0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateTimeUtils.formatDate(todo.dueDate!),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isOverdue
                                    ? Colors.red
                                    : theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: isDark ? 0.85 : 0.75),
                                fontWeight: isOverdue ? FontWeight.w600 : null,
                              ),
                            ),
                          ] else ...[
                            Icon(
                              Symbols.update,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: isDark ? 0.8 : 0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateTimeUtils.getRelativeTime(todo.updatedAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: isDark ? 0.85 : 0.75),
                              ),
                            ),
                          ],
                          // Reminder indicator
                          if (todo.reminderIds.isNotEmpty) ...[
                            const SizedBox(width: 16),
                            Icon(
                              Symbols.notifications,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                          // Attachment indicator
                          if (todo.attachmentIds.isNotEmpty) ...[
                            const SizedBox(width: 16),
                            Icon(
                              Symbols.attach_file,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: isDark ? 0.85 : 0.75),
                            ),
                          ],
                          const Spacer(),
                          // Completion status
                          if (isCompleted)
                            Icon(
                              Symbols.check_circle,
                              size: 16,
                              color: Colors.green,
                            ),
                        ],
                      ),
                      // Tags
                      if (todo.tagIds.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Consumer(
                          builder: (context, ref, child) {
                            final tagsAsync = ref.watch(tagsForTodoProvider(todo.id));
                            return tagsAsync.when(
                              data: (tags) => Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: tags.map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: tag.color != null
                                          ? Color(int.parse(tag.color!, radix: 16))
                                              .withOpacity(0.2)
                                          : Colors.grey.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      tag.name,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: tag.color != null
                                            ? Color(int.parse(tag.color!, radix: 16))
                                            : Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              loading: () => Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: todo.tagIds.map((tagId) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Loading...',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              error: (error, stack) => Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: todo.tagIds.map((tagId) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      tagId,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.red[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
  }

  Widget _buildPriorityIndicator(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: todo.priority.color,
        shape: BoxShape.circle,
      ),
    );
  }
}