import '../services/local/database_helper.dart';
import '../services/db_push.dart';

/// Utility class to easily push test data to the database
class DbPushUtility {
  /// Push comprehensive test data to the database
  /// This will clear existing data and populate with fresh test data
  static Future<void> pushTestData() async {
    try {
      print('🚀 Initializing database push utility...');
      
      final databaseHelper = DatabaseHelper();
      final dbPush = DatabasePush(databaseHelper);
      
      await dbPush.pushTestData();
      
      print('✅ Database push utility completed successfully!');
    } catch (e) {
      print('❌ Database push utility failed: $e');
      rethrow;
    }
  }
  
  /// Quick method to check if database has data
  static Future<Map<String, int>> getDatabaseStats() async {
    try {
      final databaseHelper = DatabaseHelper();
      final db = await databaseHelper.database;
      
      final categoriesCount = await db.rawQuery('SELECT COUNT(*) as count FROM categories');
      final tagsCount = await db.rawQuery('SELECT COUNT(*) as count FROM tags');
      final todosCount = await db.rawQuery('SELECT COUNT(*) as count FROM todos');
      final remindersCount = await db.rawQuery('SELECT COUNT(*) as count FROM reminders');
      
      return {
        'categories': categoriesCount.first['count'] as int,
        'tags': tagsCount.first['count'] as int,
        'todos': todosCount.first['count'] as int,
        'reminders': remindersCount.first['count'] as int,
      };
    } catch (e) {
      print('❌ Failed to get database stats: $e');
      return {
        'categories': 0,
        'tags': 0,
        'todos': 0,
        'reminders': 0,
      };
    }
  }
}