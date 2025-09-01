import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/local_note_repository.dart';
import '../domain/entities/note.dart';
import '../domain/repositories/note_repository.dart';
import '../services/local/database_helper.dart';

// Database helper provider
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

// Note repository provider
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return LocalNoteRepository(databaseHelper);
});

// Notes list provider
final notesProvider = StreamProvider<List<Note>>((ref) {
  final repository = ref.watch(noteRepositoryProvider);
  return repository.watchNotes();
});

// Individual note provider
final noteProvider = FutureProvider.family<Note?, String>((ref, id) async {
  final repository = ref.watch(noteRepositoryProvider);
  return repository.getNoteById(id);
});

// Search results provider
final searchNotesProvider = FutureProvider.family<List<Note>, String>((
  ref,
  query,
) async {
  final repository = ref.watch(noteRepositoryProvider);
  if (query.isEmpty) {
    return repository.getAllNotes();
  }
  // Implement search in repository
  return repository.searchNotes(query);
});

// Note operations notifier
class NoteOperationsNotifier extends StateNotifier<AsyncValue<void>> {
  final NoteRepository _repository;

  NoteOperationsNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> saveNote(Note note) async {
    state = const AsyncValue.loading();
    try {
      await _repository.saveNote(note);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateNote(Note note) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateNote(note);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteNote(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteNote(id);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> archiveNote(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.archiveNote(id);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> unarchiveNote(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.unarchiveNote(id);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final noteOperationsProvider =
    StateNotifierProvider<NoteOperationsNotifier, AsyncValue<void>>((ref) {
      final repository = ref.watch(noteRepositoryProvider);
      return NoteOperationsNotifier(repository);
    });
