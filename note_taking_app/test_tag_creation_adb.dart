import 'dart:io';
import 'dart:convert';

void main() async {
  print('🧪 Testing tag creation and association with todos via ADB...');
  
  // First, create a tag
  final createTagCommand = {
    'action': 'create_tag',
    'name': 'Test Tag',
    'color': '#FF5722',
    'description': 'A test tag created via ADB'
  };
  
  print('📝 Creating tag command file...');
  final commandFile = File('/sdcard/adb_command.json');
  await commandFile.writeAsString(jsonEncode(createTagCommand));
  
  print('⏳ Waiting for tag creation response...');
  final responseFile = File('/sdcard/adb_response.json');
  
  // Wait for response (up to 10 seconds)
  for (int i = 0; i < 20; i++) {
    await Future.delayed(Duration(milliseconds: 500));
    if (await responseFile.exists()) {
      final responseContent = await responseFile.readAsString();
      final response = jsonDecode(responseContent);
      print('✅ Tag creation response: $response');
      
      if (response['success'] == true) {
        final tagId = response['tagId'];
        print('🏷️ Tag created successfully with ID: $tagId');
        
        // Now create a todo with this tag
        final createTodoCommand = {
          'action': 'create_todo',
          'title': 'Todo with Test Tag',
          'description': 'This todo has a tag attached',
          'priority': 'medium',
          'tagIds': [tagId]
        };
        
        print('📝 Creating todo with tag...');
        await commandFile.writeAsString(jsonEncode(createTodoCommand));
        await responseFile.delete();
        
        // Wait for todo creation response
        for (int j = 0; j < 20; j++) {
          await Future.delayed(Duration(milliseconds: 500));
          if (await responseFile.exists()) {
            final todoResponseContent = await responseFile.readAsString();
            final todoResponse = jsonDecode(todoResponseContent);
            print('✅ Todo creation response: $todoResponse');
            
            if (todoResponse['success'] == true) {
              print('🎉 Successfully created todo with tag!');
              print('📋 Todo ID: ${todoResponse['todoId']}');
              print('🏷️ Tag ID: $tagId');
            } else {
              print('❌ Failed to create todo: ${todoResponse['error']}');
            }
            break;
          }
        }
        
        if (!await responseFile.exists()) {
          print('⏰ Timeout waiting for todo creation response');
        }
      } else {
        print('❌ Failed to create tag: ${response['error']}');
      }
      break;
    }
  }
  
  if (!await responseFile.exists()) {
    print('⏰ Timeout waiting for tag creation response');
  }
  
  // Clean up
  try {
    if (await commandFile.exists()) await commandFile.delete();
    if (await responseFile.exists()) await responseFile.delete();
    print('🧹 Cleaned up test files');
  } catch (e) {
    print('⚠️ Error cleaning up: $e');
  }
  
  print('🏁 Tag test completed!');
}