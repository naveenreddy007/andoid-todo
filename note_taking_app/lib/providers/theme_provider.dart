import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ui/theme/app_theme.dart';

/// Enum for theme modes
enum AppThemeMode {
  light,
  dark,
  system,
}

/// Enum for predefined color schemes
enum ColorSchemeType {
  blue,
  green,
  purple,
  orange,
  pink,
  teal,
  indigo,
  red,
}

/// Theme settings model
class ThemeSettings {
  final AppThemeMode themeMode;
  final ColorSchemeType colorScheme;
  final bool useSystemAccentColor;
  final double fontSize;
  final bool useDynamicColor;
  
  const ThemeSettings({
    this.themeMode = AppThemeMode.system,
    this.colorScheme = ColorSchemeType.blue,
    this.useSystemAccentColor = false,
    this.fontSize = 1.0,
    this.useDynamicColor = true,
  });
  
  ThemeSettings copyWith({
    AppThemeMode? themeMode,
    ColorSchemeType? colorScheme,
    bool? useSystemAccentColor,
    double? fontSize,
    bool? useDynamicColor,
  }) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      colorScheme: colorScheme ?? this.colorScheme,
      useSystemAccentColor: useSystemAccentColor ?? this.useSystemAccentColor,
      fontSize: fontSize ?? this.fontSize,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.index,
      'colorScheme': colorScheme.index,
      'useSystemAccentColor': useSystemAccentColor,
      'fontSize': fontSize,
      'useDynamicColor': useDynamicColor,
    };
  }
  
  factory ThemeSettings.fromJson(Map<String, dynamic> json) {
    return ThemeSettings(
      themeMode: AppThemeMode.values[json['themeMode'] ?? 2],
      colorScheme: ColorSchemeType.values[json['colorScheme'] ?? 0],
      useSystemAccentColor: json['useSystemAccentColor'] ?? false,
      fontSize: (json['fontSize'] ?? 1.0).toDouble(),
      useDynamicColor: json['useDynamicColor'] ?? true,
    );
  }
}

/// Theme settings notifier
class ThemeSettingsNotifier extends StateNotifier<ThemeSettings> {
  static const String _storageKey = 'theme_settings';
  
  ThemeSettingsNotifier() : super(const ThemeSettings()) {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null) {
        final json = Map<String, dynamic>.from(
          Uri.splitQueryString(jsonString),
        );
        state = ThemeSettings.fromJson(json);
      }
    } catch (e) {
      // If loading fails, keep default settings
    }
  }
  
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = state.toJson();
      final jsonString = Uri(queryParameters: json.map(
        (key, value) => MapEntry(key, value.toString()),
      )).query;
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      // Handle save error silently
    }
  }
  
  Future<void> updateThemeMode(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _saveSettings();
  }
  
  Future<void> updateColorScheme(ColorSchemeType scheme) async {
    state = state.copyWith(colorScheme: scheme);
    await _saveSettings();
  }
  
  Future<void> updateUseSystemAccentColor(bool use) async {
    state = state.copyWith(useSystemAccentColor: use);
    await _saveSettings();
  }
  
  Future<void> updateFontSize(double size) async {
    state = state.copyWith(fontSize: size);
    await _saveSettings();
  }
  
  Future<void> updateUseDynamicColor(bool use) async {
    state = state.copyWith(useDynamicColor: use);
    await _saveSettings();
  }
  
  Future<void> resetToDefaults() async {
    state = const ThemeSettings();
    await _saveSettings();
  }
}

/// Theme settings provider
final themeSettingsProvider = StateNotifierProvider<ThemeSettingsNotifier, ThemeSettings>(
  (ref) => ThemeSettingsNotifier(),
);

/// Current theme mode provider
final currentThemeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(themeSettingsProvider);
  switch (settings.themeMode) {
    case AppThemeMode.light:
      return ThemeMode.light;
    case AppThemeMode.dark:
      return ThemeMode.dark;
    case AppThemeMode.system:
      return ThemeMode.system;
  }
});

/// Light theme provider
final lightThemeProvider = Provider<ThemeData>((ref) {
  final settings = ref.watch(themeSettingsProvider);
  return AppTheme.createLightTheme(
    colorScheme: settings.colorScheme,
    fontSize: settings.fontSize,
    useDynamicColor: settings.useDynamicColor,
  );
});

/// Dark theme provider
final darkThemeProvider = Provider<ThemeData>((ref) {
  final settings = ref.watch(themeSettingsProvider);
  return AppTheme.createDarkTheme(
    colorScheme: settings.colorScheme,
    fontSize: settings.fontSize,
    useDynamicColor: settings.useDynamicColor,
  );
});

/// Current brightness provider
final currentBrightnessProvider = Provider<Brightness>((ref) {
  final settings = ref.watch(themeSettingsProvider);
  switch (settings.themeMode) {
    case AppThemeMode.light:
      return Brightness.light;
    case AppThemeMode.dark:
      return Brightness.dark;
    case AppThemeMode.system:
      // This would need to be updated based on system brightness
      return Brightness.light;
  }
});

/// Is dark mode provider
final isDarkModeProvider = Provider<bool>((ref) {
  final brightness = ref.watch(currentBrightnessProvider);
  return brightness == Brightness.dark;
});

/// Color scheme seed color provider
final colorSchemeSeedProvider = Provider<Color>((ref) {
  final settings = ref.watch(themeSettingsProvider);
  return AppTheme.getColorSchemeSeed(settings.colorScheme);
});

/// Theme animation duration provider
final themeAnimationDurationProvider = Provider<Duration>((ref) {
  return const Duration(milliseconds: 300);
});

/// Available color schemes provider
final availableColorSchemesProvider = Provider<List<ColorSchemeInfo>>((ref) {
  return [
    ColorSchemeInfo(
      type: ColorSchemeType.blue,
      name: 'Blue',
      color: const Color(0xFF2196F3),
      description: 'Classic blue theme',
    ),
    ColorSchemeInfo(
      type: ColorSchemeType.green,
      name: 'Green',
      color: const Color(0xFF4CAF50),
      description: 'Nature-inspired green',
    ),
    ColorSchemeInfo(
      type: ColorSchemeType.purple,
      name: 'Purple',
      color: const Color(0xFF9C27B0),
      description: 'Creative purple theme',
    ),
    ColorSchemeInfo(
      type: ColorSchemeType.orange,
      name: 'Orange',
      color: const Color(0xFFFF9800),
      description: 'Energetic orange',
    ),
    ColorSchemeInfo(
      type: ColorSchemeType.pink,
      name: 'Pink',
      color: const Color(0xFFE91E63),
      description: 'Playful pink theme',
    ),
    ColorSchemeInfo(
      type: ColorSchemeType.teal,
      name: 'Teal',
      color: const Color(0xFF009688),
      description: 'Calming teal',
    ),
    ColorSchemeInfo(
      type: ColorSchemeType.indigo,
      name: 'Indigo',
      color: const Color(0xFF3F51B5),
      description: 'Deep indigo theme',
    ),
    ColorSchemeInfo(
      type: ColorSchemeType.red,
      name: 'Red',
      color: const Color(0xFFF44336),
      description: 'Bold red theme',
    ),
  ];
});

/// Color scheme info model
class ColorSchemeInfo {
  final ColorSchemeType type;
  final String name;
  final Color color;
  final String description;
  
  const ColorSchemeInfo({
    required this.type,
    required this.name,
    required this.color,
    required this.description,
  });
}

/// Font size options provider
final fontSizeOptionsProvider = Provider<List<FontSizeOption>>((ref) {
  return [
    const FontSizeOption(value: 0.8, label: 'Small'),
    const FontSizeOption(value: 1.0, label: 'Default'),
    const FontSizeOption(value: 1.2, label: 'Large'),
    const FontSizeOption(value: 1.4, label: 'Extra Large'),
  ];
});

/// Font size option model
class FontSizeOption {
  final double value;
  final String label;
  
  const FontSizeOption({
    required this.value,
    required this.label,
  });
}

/// Theme operations notifier for complex theme operations
class ThemeOperationsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  
  ThemeOperationsNotifier(this.ref) : super(const AsyncValue.data(null));
  
  Future<void> toggleThemeMode() async {
    state = const AsyncValue.loading();
    try {
      final currentSettings = ref.read(themeSettingsProvider);
      final newMode = switch (currentSettings.themeMode) {
        AppThemeMode.light => AppThemeMode.dark,
        AppThemeMode.dark => AppThemeMode.system,
        AppThemeMode.system => AppThemeMode.light,
      };
      
      await ref.read(themeSettingsProvider.notifier).updateThemeMode(newMode);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  Future<void> applyColorScheme(ColorSchemeType scheme) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(themeSettingsProvider.notifier).updateColorScheme(scheme);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  Future<void> resetTheme() async {
    state = const AsyncValue.loading();
    try {
      await ref.read(themeSettingsProvider.notifier).resetToDefaults();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Theme operations provider
final themeOperationsProvider = StateNotifierProvider<ThemeOperationsNotifier, AsyncValue<void>>(
  (ref) => ThemeOperationsNotifier(ref),
);