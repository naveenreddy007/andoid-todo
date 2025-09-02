import 'dart:io';
import 'dart:convert';
import 'package:uuid/uuid.dart';

void main() async {
  print('🧪 Testing Tag Creation via ADB Command');
  
  // Create a tag creation command
  final tagCommand = {
    'action': 'create_tag',
    'name': 'urgent',
    'color': '#FF5722'
  };
  
  // Write to external storage (where we placed the file)
  final commandFile = File('/sdcard/adb_command.json');
  
  try {
    // Write the command
    await commandFile.writeAsString(json.encode(tagCommand));
    print('✅ Created tag command file at /sdcard/adb_command.json');
    print('📝 Command: ${json.encode(tagCommand)}');
    
    // Wait a moment
    await Future.delayed(Duration(seconds: 2));
    
    // Check if response file was created
    final responseFile = File('/sdcard/adb_response.json');
    if (await responseFile.exists()) {
      final response = await responseFile.readAsString();
      print('📥 Response received: $response');
      
      // Clean up
      await responseFile.delete();
      print('🧹 Cleaned up response file');
    } else {
      print('❌ No response file found');
    }
    
    // Clean up command file
    if (await commandFile.exists()) {
      await commandFile.delete();
      print('🧹 Cleaned up command file');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  }
  
  print('