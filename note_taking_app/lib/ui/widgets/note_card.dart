import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:material_symbols_icons/symbols.dart';
import '../../domain/entities/note.dart';
import '../../core/utils/date_time_utils.dart';
import '../theme/app_theme.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onArchive,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(12);

    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        children: [
          // Blur background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: const SizedBox.expand(),
          ),
          // Translucent gradient container with subtle border for glass effect
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withOpacity(0.06),
                        Colors.white.withOpacity(0.03),
                      ]
                    : [
                        Colors.white.withOpacity(0.55),
                        Colors.white.withOpacity(0.35),
                      ],
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.10)
                    : Colors.white.withOpacity(0.40),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.35)
                      : Colors.grey.shade300.withOpacity(0.7),
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
                splashColor: theme.colorScheme.primary.withOpacity(0.08),
                highlightColor: theme.colorScheme.primary.withOpacity(0.04),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              note.title.isEmpty ? 'Untitled' : note.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                // Ensure strong contrast over translucent bg
                                color: isDark
                                    ? Colors.white.withOpacity(0.95)
                                    : Colors.black.withOpacity(0.85),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildPriorityIndicator(context),
                        ],
                      ),
                      if (note.plainText != null && note.plainText!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          opacity: 1,
                          child: Text(
                            note.plainText!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.35,
                              color: isDark
                                  ? Colors.white.withOpacity(0.82)
                                  : Colors.black.withOpacity(0.70),
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Symbols.schedule,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(isDark ? 0.8 : 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateTimeUtils.getRelativeTime(note.updatedAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(isDark ? 0.85 : 0.75),
                            ),
                          ),
                          if (note.reminderDate != null) ...[
                            const SizedBox(width: 16),
                            Icon(
                              Symbols.notifications,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                          if (note.attachmentIds.isNotEmpty) ...[
                            const SizedBox(width: 16),
                            Icon(
                              Symbols.attach_file,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(isDark ? 0.85 : 0.75),
                            ),
                          ],
                          const Spacer(),
                          if (note.isArchived)
                            Icon(
                              Symbols.archive,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(isDark ? 0.85 : 0.75),
                            ),
                        ],
                      ),
                      if (note.tagIds.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: note.tagIds.take(3).map((tagId) {
                            return DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    theme.colorScheme.primary
                                        .withOpacity(isDark ? 0.24 : 0.18),
                                    theme.colorScheme.primaryContainer
                                        .withOpacity(isDark ? 0.22 : 0.16),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.onPrimaryContainer
                                      .withOpacity(0.20),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Text(
                                  tagId, // TODO: resolve tag name if available
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white.withOpacity(0.95)
                                        : Colors.black.withOpacity(0.85),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityIndicator(BuildContext context) {
    Color color;
    switch (note.priority) {
      case Priority.high:
        color = PriorityColors.high;
        break;
      case Priority.medium:
        color = PriorityColors.medium;
        break;
      case Priority.low:
        color = PriorityColors.low;
        break;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
