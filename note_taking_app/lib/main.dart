import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'ui/widgets/main_navigation.dart';
import 'ui/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'debug_helper.dart';
import 'debug_database_dump.dart';
import 'providers/search_provider.dart';
import 'services/search_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Insert test todos for debugging
  await DebugHelper.insertTestTodos();
  await DebugHelper.fetchAndPrintTodos();
  
  // Dump database contents for ADB verification
  await DatabaseDumper.dumpTodosOnly();
  
  // Start ADB command processing timer
  Timer.periodic(const Duration(seconds: 2), (timer) {
    DebugHelper.processAdbCommands();
  });
  
  runApp(
    const ProviderScope(
      child: NoteTakingApp(),
    ),
  );
}

class NoteTakingApp extends StatelessWidget {
  const NoteTakingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainNavigation(),
      debugShowCheckedModeBanner: false,
    );
  }
}
