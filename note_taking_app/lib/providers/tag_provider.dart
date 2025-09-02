import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/local_tag_repository.dart';
import '../domain/entities/tag.dart';
import '../domain/repositories/tag_repository.dart';
import 'todo_provider.dart';

// Tag repository provider
final tagRepositoryProvider = Provider<TagRepository>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return LocalTagRepository(databaseHelper);
});

// Tags list provider
final tagsProvider = FutureProvider<List<Tag>>((ref) async {
  final repository = ref.watch(tagRepositoryProvider);
  return repository.getAllTags();
});

// Tags stream provider
final tagsStreamProvider = StreamProvider<List<Tag>>((ref) {
  final repository = ref.watch(tagRepositoryProvider);
  return repository.watchTags();
});

// Individual tag provider
final tagProvider = FutureProvider.family<Tag?, String>((ref, id) async {
  final repository = ref.watch(tagRepositoryProvider);
  return repository.getTagById(id);
});

// Tags for todo provider
final tagsForTodoProvider = FutureProvider.family<List<Tag>, String>((
  ref,
  todoId,
) async {
  final repository = ref.watch(tagRepositoryProvider);
  return repository.getTagsForTodo(todoId);
});

// Popular tags provider
final popularTagsProvider = FutureProvider.family<List<Tag>, int>((
  ref,
  limit,
) async {
  final repository = ref.watch(tagRepositoryProvider);
  return repository.getPopularTags(limit);
});

// Tag operations notifier
class TagOperationsNotifier extends StateNotifier<AsyncValue<void>> {
  final TagRepository _repository;

  TagOperationsNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> saveTag(Tag tag) async {
    developer.log('🏷️ Provider: Saving tag ${tag.name} (${tag.id})', name: 'TagProvider');
    state = const AsyncValue.loading();
    try {
      await _repository.saveTag(tag);
      developer.log('✅ Provider: Tag saved successfully ${tag.name}', name: 'TagProvider');
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      developer.log('❌ Provider: Failed to save tag: $error', name: 'TagProvider');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateTag(Tag tag) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateTag(tag);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteTag(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteTag(id);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addTagToTodo(String todoId, String tagId) async {
    developer.log('🔗 Provider: Adding tag $tagId to todo $todoId', name: 'TagProvider');
    state = const AsyncValue.loading();
    try {
      await _repository.addTagToTodo(todoId, tagId);
      developer.log('✅ Provider: Tag added to todo successfully', name: 'TagProvider');
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      developer.log('❌ Provider: Failed to add tag to todo: $error', name: 'TagProvider');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> removeTagFromTodo(String todoId, String tagId) async {
    developer.log('🔗 Provider: Removing tag $tagId from todo $todoId', name: 'TagProvider');
    state = const AsyncValue.loading();
    try {
      await _repository.removeTagFromTodo(todoId, tagId);
      developer.log('✅ Provider: Tag removed from todo successfully', name: 'TagProvider');
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      developer.log('❌ Provider: Failed to remove tag from todo: $error', name: 'TagProvider');
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final tagOperationsProvider =
    StateNotifierProvider<TagOperationsNotifier, AsyncValue<void>>((ref) {
      final repository = ref.watch(tagRepositoryProvider);
      return TagOperationsNotifier(repository);
    });
