import '../entities/note.dart';

abstract class NoteRepository {
  Future<List<Note>> getAllNotes();
  Future<Note?> getNoteById(String id);
  Future<void> saveNote(Note note);
  Future<void> updateNote(Note note);
  Future<void> deleteNote(String id);
  Future<void> archiveNote(String id);
  Future<void> unarchiveNote(String id);
  Stream<List<Note>> watchNotes();
  Future<List<Note>> getNotesByCategory(String categoryId);
  Future<List<Note>> getNotesByTag(String tagId);
  Future<List<Note>> getNotesByPriority(Priority priority);
  Future<List<Note>> getArchivedNotes();
  Future<List<Note>> getDeletedNotes();
  Future<List<Note>> searchNotes(String query);
  Future<List<Note>> getNotesWithReminders();
  Future<List<Note>> getNotesDueForSync();
}