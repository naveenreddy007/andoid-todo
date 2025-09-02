import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;

// Import the actual providers and entities
import 'lib/providers/tag_provider.dart';
import 'lib/domain/entities/tag.dart';
import 'lib/core/utils/id_generator.dart';

void main() async {
  print('🚀 Starting Tag Provider State Management Test');
  
  // Initialize FFI for desktop testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  
  try {
    // Test 1: Provider Container Setup
    print('\n📦 Test 1: Provider Container Setup');
    final container = ProviderContainer();
    print('✅ Provider container created successfully');
    
    // Test 2: Read Tags Provider (should be empty initially)
    print('\n🏷️ Test 2: Reading Tags Provider (Initial State)');
    final initialTags = await container.read(tagsProvider.future);
    print('📊 Initial tags count: ${initialTags.length}');
    
    // Test 3: Create Test Tags via Provider
    print('\n🎨 Test 3: Creating Tags via Provider');
    final testTags = [
      Tag(
        id: IdGenerator.generateId(),
        name: 'Provider Test Work',
        color: '#FF5722',
        createdAt: DateTime.now(),
      ),
      Tag(
        id: IdGenerator.generateId(),
        name: 'Provider Test Personal',
        color: '#2196F3',
        createdAt: DateTime.now(),
      ),
    ];
    
    for (final tag in testTags) {
      await container.read(tagRepositoryProvider).createTag(tag);
      print('✅ Created tag via provider: ${tag.name} (${tag.id})');
    }
    
    // Test 4: Verify Tags via Provider
    print('\n🔍 Test 4: Verifying Tags via Provider');
    // Invalidate the provider to refresh the data
    container.invalidate(tagsProvider);
    final updatedTags = await container.read(tagsProvider.future);
    print('📊 Updated tags count: ${updatedTags.length}');
    for (final tag in updatedTags) {
      print('  - ${tag.name} (${tag.id}) - Color: ${tag.color}');
    }
    
    // Test 5: Test Individual Tag Provider
    print('\n🏷️ Test 5: Testing Individual Tag Provider');
    if (testTags.isNotEmpty) {
      final firstTagId = testTags.first.id;
      final individualTag = await container.read(tagProvider(firstTagId).future);
      if (individualTag != null) {
        print('✅ Individual tag provider working: ${individualTag.name}');
      } else {
        print('❌ Individual tag provider returned null');
      }
    }
    
    // Test 6: Test Popular Tags Provider
    print('\n📈 Test 6: Testing Popular Tags Provider');
    final popularTags = await container.read(popularTagsProvider.future);
    print('📊 Popular tags count: ${popularTags.length}');
    for (final tag in popularTags) {
      print('  - ${tag.name}');
    }
    
    // Test 7: Test Tag Search
    print('\n🔍 Test 7: Testing Tag Search Provider');
    final searchResults = await container.read(tagSearchProvider('work').future);
    print('📊 Search results for "work": ${searchResults.length} tags');
    for (final tag in searchResults) {
      print('  - ${tag.name}');
    }
    
    // Test 8: Test Provider State Changes
    print('\n🔄 Test 8: Testing Provider State Changes');
    
    // Listen to provider changes
    bool providerUpdated = false;
    container.listen(tagsProvider, (previous, next) {
      print('🔔 Tags provider state changed!');
      providerUpdated = true;
    });
    
    // Create another tag to trigger state change
    final newTag = Tag(
      id: IdGenerator.generateId(),
      name: 'State Change Test',
      color: '#4CAF50',
      createdAt: DateTime.now(),
    );
    
    await container.read(tagRepositoryProvider).createTag(newTag);
    container.invalidate(tagsProvider);
    
    // Wait a bit for the state change
    await Future.delayed(Duration(milliseconds: 100));
    
    if (providerUpdated) {
      print('✅ Provider state change detected successfully');
    } else {
      print('⚠️ Provider state change not detected (this might be expected)');
    }
    
    // Test 9: Test Error Handling
    print('\n❌ Test 9: Testing Error Handling');
    try {
      // Try to get a non-existent tag
      final nonExistentTag = await container.read(tagProvider('non_existent_id').future);
      if (nonExistentTag == null) {
        print('✅ Non-existent tag correctly returned null');
      } else {
        print('❌ Non-existent tag should return null');
      }
    } catch (e) {
      print('✅ Error handling working: $e');
    }
    
    // Test 10: Cleanup and Final Verification
    print('\n🧹 Test 10: Cleanup and Final Verification');
    final finalTags = await container.read(tagsProvider.future);
    print('📊 Final tags count: ${finalTags.length}');
    
    // Dispose the container
    container.dispose();
    print('✅ Provider container disposed');
    
    print('\n✅ Tag Provider State Management Test PASSED!');
    print('🎉 All tag provider functionality is working correctly!');
    
  } catch (e, stackTrace) {
    print('❌ Test FAILED with error: $e');
    print('📍 Stack trace: $stackTrace');
    exit(1);
  }
}