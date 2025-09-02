import 'dart:io';

void main() async {
  print('🔍 Testing Tag Provider Implementation');
  
  // Check if core tag files exist
  final tagFiles = [
    'lib/data/models/tag.dart',
    'lib/data/providers/tag_provider.dart',
    'lib/data/services/tag_service.dart',
    'lib/ui/widgets/tag_chip.dart',
    'lib/ui/widgets/tag_selector.dart',
  ];
  
  print('\n📁 Checking tag implementation files:');
  for (final file in tagFiles) {
    final exists = File(file).existsSync();
    print('${exists ? '✅' : '❌'} $file');
  }
  
  // Check database files
  final dbFiles = [
    'lib/data/database/database_helper.dart',
    'lib/data/database/database_constants.dart',
  ];
  
  print('\n🗄️ Checking database files:');
  for (final file in dbFiles) {
    final exists = File(file).existsSync();
    print('${exists ? '✅' : '❌'} $file');
  }
  
  // Check tag integration in key files
  final integrationFiles = [
    'lib/ui/screens/todo_editor_screen.dart',
    'lib/ui/screens/search_screen.dart',
    'lib/ui/widgets/todo_card.dart',
  ];
  
  print('\n🔗 Checking tag integration:');
  for (final file in integrationFiles) {
    if (File(file).existsSync()) {
      final content = File(file).readAsStringSync();
      final hasTagImport = content.contains('tag') || content.contains('Tag');
      print('${hasTagImport ? '✅' : '❌'} $file - Tag integration');
    } else {
      print('❌ $file - File not found');
    }
  }
  
  // Check database schema
  print('\n🗄️ Checking database schema:');
  final dbConstantsFile = File('lib/data/database/database_constants.dart');
  if (dbConstantsFile.existsSync()) {
    final content = dbConstantsFile.readAsStringSync();
    final hasTagsTable = content.contains('tags') || content.contains('Tags');
    final hasTodoTagsTable = content.contains('todo_tags') || content.contains('TodoTags');
    print('${hasTagsTable ? '✅' : '❌'} Tags table definition');
    print('${hasTodoTagsTable ? '✅' : '❌'} Todo-Tags association table');
  } else {
    print('❌ Database constants file not found');
  }
  
  print('\n✅ Tag implementation check completed!');
}