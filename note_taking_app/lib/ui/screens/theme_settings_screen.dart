import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/theme_provider.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeSettingsProvider);
    final themeOperations = ref.watch(themeOperationsProvider);
    final availableColorSchemes = ref.watch(availableColorSchemesProvider);
    final fontSizeOptions = ref.watch(fontSizeOptionsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Settings'),
        actions: [
          IconButton(
            onPressed: themeOperations.isLoading
                ? null
                : () => ref.read(themeOperationsProvider.notifier).resetTheme(),
            icon: const Icon(LucideIcons.rotateCcw),
            tooltip: 'Reset to defaults',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Mode Section
          _ThemeModeSection(
            currentMode: themeSettings.themeMode,
            onModeChanged: (mode) {
              ref.read(themeSettingsProvider.notifier).updateThemeMode(mode);
            },
          ),
          const SizedBox(height: 24),
          
          // Color Scheme Section
          _ColorSchemeSection(
            currentScheme: themeSettings.colorScheme,
            availableSchemes: availableColorSchemes,
            onSchemeChanged: (scheme) {
              ref.read(themeSettingsProvider.notifier).updateColorScheme(scheme);
            },
          ),
          const SizedBox(height: 24),
          
          // Font Size Section
          _FontSizeSection(
            currentSize: themeSettings.fontSize,
            options: fontSizeOptions,
            onSizeChanged: (size) {
              ref.read(themeSettingsProvider.notifier).updateFontSize(size);
            },
          ),
          const SizedBox(height: 24),
          
          // Advanced Settings Section
          _AdvancedSettingsSection(
            settings: themeSettings,
            onSettingsChanged: (settings) {
              final notifier = ref.read(themeSettingsProvider.notifier);
              notifier.updateUseDynamicColor(settings.useDynamicColor);
              notifier.updateUseSystemAccentColor(settings.useSystemAccentColor);
            },
          ),
          const SizedBox(height: 24),
          
          // Preview Section
          const _ThemePreviewSection(),
        ],
      ),
    );
  }
}

class _ThemeModeSection extends StatelessWidget {
  final AppThemeMode currentMode;
  final ValueChanged<AppThemeMode> onModeChanged;
  
  const _ThemeModeSection({
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.palette,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Theme Mode',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...AppThemeMode.values.map((mode) {
              final isSelected = currentMode == mode;
              return RadioListTile<AppThemeMode>(
                value: mode,
                groupValue: currentMode,
                onChanged: (value) => value != null ? onModeChanged(value) : null,
                title: Text(_getThemeModeTitle(mode)),
                subtitle: Text(_getThemeModeDescription(mode)),
                secondary: Icon(_getThemeModeIcon(mode)),
                selected: isSelected,
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        ),
      ),
    );
  }
  
  String _getThemeModeTitle(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System';
    }
  }
  
  String _getThemeModeDescription(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Always use light theme';
      case AppThemeMode.dark:
        return 'Always use dark theme';
      case AppThemeMode.system:
        return 'Follow system settings';
    }
  }
  
  IconData _getThemeModeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return LucideIcons.sun;
      case AppThemeMode.dark:
        return LucideIcons.moon;
      case AppThemeMode.system:
        return LucideIcons.monitor;
    }
  }
}

class _ColorSchemeSection extends StatelessWidget {
  final ColorSchemeType currentScheme;
  final List<ColorSchemeInfo> availableSchemes;
  final ValueChanged<ColorSchemeType> onSchemeChanged;
  
  const _ColorSchemeSection({
    required this.currentScheme,
    required this.availableSchemes,
    required this.onSchemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.droplet,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Color Scheme',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: availableSchemes.length,
              itemBuilder: (context, index) {
                final scheme = availableSchemes[index];
                final isSelected = currentScheme == scheme.type;
                
                return GestureDetector(
                  onTap: () => onSchemeChanged(scheme.type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: scheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 3,
                            )
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: scheme.color.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            LucideIcons.check,
                            color: Colors.white,
                            size: 24,
                          )
                        : null,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              availableSchemes
                  .firstWhere((s) => s.type == currentScheme)
                  .description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FontSizeSection extends StatelessWidget {
  final double currentSize;
  final List<FontSizeOption> options;
  final ValueChanged<double> onSizeChanged;
  
  const _FontSizeSection({
    required this.currentSize,
    required this.options,
    required this.onSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.type,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Font Size',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Slider(
              value: currentSize,
              min: 0.8,
              max: 1.4,
              divisions: 3,
              label: options
                  .firstWhere((o) => o.value == currentSize,
                      orElse: () => const FontSizeOption(value: 1.0, label: 'Custom'))
                  .label,
              onChanged: onSizeChanged,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: options.map((option) {
                final isSelected = (currentSize - option.value).abs() < 0.01;
                return GestureDetector(
                  onTap: () => onSizeChanged(option.value),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: Text(
                      option.label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'Preview: This is how text will look with the selected font size.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdvancedSettingsSection extends StatelessWidget {
  final ThemeSettings settings;
  final ValueChanged<ThemeSettings> onSettingsChanged;
  
  const _AdvancedSettingsSection({
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.settings,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Advanced Settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: settings.useDynamicColor,
              onChanged: (value) {
                onSettingsChanged(settings.copyWith(useDynamicColor: value));
              },
              title: const Text('Dynamic Colors'),
              subtitle: const Text('Use Material You dynamic colors when available'),
              secondary: const Icon(LucideIcons.sparkles),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: settings.useSystemAccentColor,
              onChanged: (value) {
                onSettingsChanged(settings.copyWith(useSystemAccentColor: value));
              },
              title: const Text('System Accent Color'),
              subtitle: const Text('Use system accent color instead of custom scheme'),
              secondary: const Icon(LucideIcons.eyeDropper),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemePreviewSection extends StatelessWidget {
  const _ThemePreviewSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.eye,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Preview',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Sample UI elements
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Elevated'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () {},
                    child: const Text('Filled'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Outlined'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            TextField(
              decoration: const InputDecoration(
                labelText: 'Sample Input',
                hintText: 'Enter some text...',
                prefixIcon: Icon(LucideIcons.search),
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Chip(
                  label: const Text('Sample Chip'),
                  avatar: const Icon(LucideIcons.tag, size: 16),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: const Text('Another Chip'),
                  backgroundColor: theme.colorScheme.primaryContainer,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary,
                child: Icon(
                  LucideIcons.user,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              title: const Text('Sample List Item'),
              subtitle: const Text('This is a subtitle'),
              trailing: const Icon(LucideIcons.chevronRight),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}