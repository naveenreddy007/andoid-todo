import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/database/database_helper.dart';
import 'providers/theme_provider.dart';
import 'providers/reminder_provider.dart';
import 'ui/widgets/main_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  await DatabaseHelper.instance.database;
  
  // Initialize shared preferences
  await SharedPreferences.getInstance();
  
  runApp(
    const ProviderScope(
      child: NoteTakingApp(),
    ),
  );
}

class NoteTakingApp extends ConsumerWidget {
  const NoteTakingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(currentThemeModeProvider);
    final lightTheme = ref.watch(lightThemeProvider);
    final darkTheme = ref.watch(darkThemeProvider);
    final animationDuration = ref.watch(themeAnimationDurationProvider);
    
    // Initialize reminder service
    ref.watch(reminderServiceInitProvider);
    
    return AnimatedTheme(
      duration: animationDuration,
      data: themeMode == ThemeMode.dark ? darkTheme : lightTheme,
      child: MaterialApp(
        title: 'Note Taking App',
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        home: const MainNavigation(),
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return AnimatedSwitcher(
            duration: animationDuration,
            child: child,
          );
        },
      ),
    );
  }
}
