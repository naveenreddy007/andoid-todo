import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/local_tag_repository.dart';
import '../domain/entities/tag.dart';
import '../domain/repositories/tag_repository.dart';
import 'note_provider.dart';

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

// Individual tag provider
final tagProvider = FutureProvider.family<Tag?, String>((ref, id) async {
  final repository = ref.watch(tagRepositoryProvider);
  return repository.getTagById(id);
});

// Tags for note provider
final tagsForNoteProvider = FutureProvider.family<List<Tag>, String>((
  ref,
  noteId,
) async {
  final repository = ref.watch(tagRepositoryProvider);
  return repository.getTagsForNote(noteId);
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
    state = const AsyncValue.loading();
    try {
      await _repository.saveTag(tag);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
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

  Future<void> addTagToNote(String noteId, String tagId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addTagToNote(noteId, tagId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> removeTagFromNote(String noteId, String tagId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.removeTagFromNote(noteId, tagId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final tagOperationsProvider =
    StateNotifierProvider<TagOperationsNotifier, AsyncValue<void>>((ref) {
      final repository = ref.watch(tagRepositoryProvider);
      return TagOperationsNotifier(repository);
    });
