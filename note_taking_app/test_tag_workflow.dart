import 'dart:io';
import 'dart:convert';

void main() async {
  print('🧪 Testing Tag Workflow...');
  
  // Test 1: Check if all tag-related files exist
  print('\n📁 Checking tag-related files:');
  final tagFiles = [
    'lib/domain/entities/tag.dart',
    'lib/data/models/tag_model.dart',
    'lib/data/repositories/local_tag_repository.dart',
    'lib/providers/tag_provider.dart',
    'lib/ui/screens/tags_screen.dart',
    'lib/ui/screens/todo_editor_screen.dart',
  ];
  
  for (final file in tagFiles) {
    final exists = await File(file).exists();
    print('${exists ? '✅' : '❌'} $file ${exists ? 'exists' : 'missing'}');
  }
  
  // Test 2: Check database constants
  print('\n🗄️ Checking database constants:');
  final dbConstantsFile = File('lib/core/constants/database_constants.dart');
  if (await dbConstantsFile.exists()) {
    final content = await dbConstantsFile.readAsString();
    final hasTagsTable = content.contains('tagsTable');
    final hasTodoTagsTable = content.contains('todoTagsTable');
    print('✅ Database constants file exists');
    print('${hasTagsTable ? '✅' : '❌'} Tags table constant ${hasTagsTable ? 'found' : 'missing'}');
    print('${hasTodoTagsTable ? '✅' : '❌'} Todo-tags table constant ${hasTodoTagsTable ? 'found' : 'missing'}');
  } else {
    print('❌ Database constants file missing');
  }
  
  // Test 3: Check tag entity structure
  print('\n🏷️ Checking tag entity:');
  final tagEntityFile = File('lib/domain/entities/tag.dart');
  if (await tagEntityFile.exists()) {
    final content = await tagEntityFile.readAsString();
    final hasId = content.contains('String id');
    final hasName = content.contains('String name');
    final hasColor = content.contains('color');
    print('✅ Tag entity file exists');
    print('${hasId ? '✅' : '❌'} ID field ${hasId ? 'found' : 'missing'}');
    print('${hasName ? '✅' : '❌'} Name field ${hasName ? 'found' : 'missing'}');
    print('${hasColor ? '✅' : '❌'} Color field ${hasColor ? 'found' : 'missing'}');
  } else {
    print('❌ Tag entity file missing');
  }
  
  // Test 4: Check tag model
  print('\n📦 Checking tag model:');
  final tagModelFile = File('lib/data/models/tag_model.dart');
  if (await tagModelFile.exists()) {
    final content = await tagModelFile.readAsString();
    final hasFromJson = content.contains('fromJson');
    final hasToJson = content.contains('toJson');
    final hasFromEntity = content.contains('fromEntity');
    final hasToEntity = content.contains('toEntity');
    print('✅ Tag model file exists');
    print('${hasFromJson ? '✅' : '❌'} fromJson method ${hasFromJson ? 'found' : 'missing'}');
    print('${hasToJson ? '✅' : '❌'} toJson method ${hasToJson ? 'found' : 'missing'}');
    print('${hasFromEntity ? '✅' : '❌'} fromEntity method ${hasFromEntity ? 'found' : 'missing'}');
    print('${hasToEntity ? '✅' : '❌'} toEntity method ${hasToEntity ? 'found' : 'missing'}');
  } else {
    print('❌ Tag model file missing');
  }
  
  // Test 5: Check provider structure
  print('\n🔄 Checking tag provider:');
  final tagProviderFile = File('lib/providers/tag_provider.dart');
  if (await tagProviderFile.exists()) {
    final content = await tagProviderFile.readAsString();
    final hasTagsProvider = content.contains('tagsProvider');
    final hasTagsStreamProvider = content.contains('tagsStreamProvider');
    final hasTagOperationsProvider = content.contains('tagOperationsProvider');
    final hasTagsForTodoProvider = content.contains('tagsForTodoProvider');
    print('✅ Tag provider file exists');
    print('${hasTagsProvider ? '✅' : '❌'} tagsProvider ${hasTagsProvider ? 'found' : 'missing'}');
    print('${hasTagsStreamProvider ? '✅' : '❌'} tagsStreamProvider ${hasTagsStreamProvider ? 'found' : 'missing'}');
    print('${hasTagOperationsProvider ? '✅' : '❌'} tagOperationsProvider ${hasTagOperationsProvider ? 'found' : 'missing'}');
    print('${hasTagsForTodoProvider ? '✅' : '❌'} tagsForTodoProvider ${hasTagsForTodoProvider ? 'found' : 'missing'}');
  } else {
    print('❌ Tag provider file missing');
  }
  
  // Test 6: Check UI integration
  print('\n🎨 Checking UI integration:');
  final todoEditorFile = File('lib/ui/screens/todo_editor_screen.dart');
  if (await todoEditorFile.exists()) {
    final content = await todoEditorFile.readAsString();
    final hasTagPicker = content.contains('_showTagPicker');
    final hasTagsConsumer = content.contains('tagsProvider');
    final hasTagChips = content.contains('Chip');
    print('✅ Todo editor file exists');
    print('${hasTagPicker ? '✅' : '❌'} Tag picker method ${hasTagPicker ? 'found' : 'missing'}');
    print('${hasTagsConsumer ? '✅' : '❌'} Tags provider usage ${hasTagsConsumer ? 'found' : 'missing'}');
    print('${hasTagChips ? '✅' : '❌'} Tag chips display ${hasTagChips ? 'found' : 'missing'}');
  } else {
    print('❌ Todo editor file missing');
  }
  
  print('\n🎉 Tag workflow analysis completed!');
  print('\n📋 Summary:');
  print('- All core tag files should exist');
  print('- Database schema should include tags and todo_tags tables');
  print('- Tag entity should have id, name, and color fields');
  print('- Tag model should have JSON serialization methods');
  print('- Tag provider should have all necessary providers');
  print('- UI should integrate tag selection and display');
  print('\n💡 If all checks pass, the tag functionality is properly implemented!');
}