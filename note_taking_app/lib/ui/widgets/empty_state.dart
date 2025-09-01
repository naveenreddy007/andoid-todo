import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(16);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
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
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.white.withValues(alpha: 0.40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.35)
                            : Colors.grey.shade300.withValues(alpha: 0.7),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                    borderRadius: borderRadius,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 80,
                          color: theme.colorScheme.primary.withValues(alpha: 0.9),
                        ),
                        const SizedBox(height: 16),
                        AnimatedOpacity(
                          opacity: 1,
                          duration: const Duration(milliseconds: 220),
                          child: Text(
                            title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.95)
                                  : Colors.black.withValues(alpha: 0.88),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.35,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.80)
                                : Colors.black.withValues(alpha: 0.72),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (action != null) ...[
                          const SizedBox(height: 20),
                          action!
                        ]
                      ],
                    ),
                  ),
        ),
      ),
    );
  }
}
