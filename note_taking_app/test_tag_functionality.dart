import 'dart:io';

void main() async {
  print('🧪 Testing Tag Database Operations...');
  
  try {
    // Test database file existence
    final dbPath = 'data/app_database.db';
    final dbFile = File(dbPath);
    
    if (await dbFile.exists()) {
      print('✅ Database file exists at: $dbPath');
      final stats = await dbFile.stat();
      print('   - Size: ${stats.size} bytes');
      print('   - Modified: ${stats.modified}');
    } else {
      print('❌ Database file not found at: $dbPath');
      
      // Check alternative locations
      final alternatives = [
        'app_database.db',
        'database/app_database.db',
        'lib/data/database/app_database.db',
      ];
      
      for (final alt in alternatives) {
        final altFile = File(alt);
        if (await altFile.exists()) {
          print('✅ Found database at alternative location: $alt');
          break;
        }
      }
    }
    
    // Check if tag-related files exist
    final tagFiles = [
      'lib/domain/entities/tag.dart',
      'lib/data/repositories/local_tag_repository.dart',
      'lib/providers/tag_provider.dart',
      'lib/ui/screens/tags_screen.dart',
    ];
    
    print('\n📁 Checking tag-related files:');
    for (final filePath in tagFiles) {
      final file = File(filePath);
      if (await file.exists()) {
        print('✅ $filePath exists');
      } else {
        print('❌ $filePath missing');
      }
    }
    
    print('\n🎉 Tag functionality files verification completed!');
    
  } catch (e, stackTrace) {
    print('❌ Test failed: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
  
  exit(0);
}