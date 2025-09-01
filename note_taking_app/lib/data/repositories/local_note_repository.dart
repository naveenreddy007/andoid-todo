import 'dart:async';

import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../../core/constants/database_constants.dart';
import '../../core/errors/app_exceptions.dart' as app_exceptions;
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../services/local/database_helper.dart';
import '../models/note_model.dart';

class LocalNoteRepository implements NoteRepository {
  final DatabaseHelper _databaseHelper;
  final _notesStreamController = StreamController<List<Note>>.broadcast();

  LocalNoteRepository(this._databaseHelper) {
    _databaseHelper.databaseStream.listen((_) {
      getAllNotes().then((notes) => _notesStreamController.add(notes));
    });
  }

  @override
  Stream<List<Note>> watchNotes() {
    getAllNotes().then((notes) => _notesStreamController.add(notes));
    return _notesStreamController.stream;
  }

  @override
  Future<List<Note>> getAllNotes() async {
    try {
      final maps = await _databaseHelper.query(
        DatabaseConstants.notesTable,
        where: '${DatabaseConstants.noteIsDeleted} = ?',
        whereArgs: [0],
        orderBy: '${DatabaseConstants.noteUpdatedAt} DESC',
      );

      final notes = <Note>[];
      for (final map in maps) {
        final noteModel = NoteModel.fromJson(map);
        final tagIds = await _getTagIdsForNote(noteModel.id);
        final attachmentIds = await _getAttachmentIdsForNote(noteModel.id);
        notes.add(
          noteModel.toEntity(tagIds: tagIds, attachmentIds: attachmentIds),
        );
      }

      return notes;
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get all notes: $e');
    }
  }

  @override
  Future<Note?> getNoteById(String id) async {
    try {
      final maps = await _databaseHelper.query(
        DatabaseConstants.notesTable,
        where: '${DatabaseConstants.noteId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) return null;

      final noteModel = NoteModel.fromJson(maps.first);
      final tagIds = await _getTagIdsForNote(noteModel.id);
      final attachmentIds = await _getAttachmentIdsForNote(noteModel.id);

      return noteModel.toEntity(tagIds: tagIds, attachmentIds: attachmentIds);
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get note by id: $e');
    }
  }

  @override
  Future<void> saveNote(Note note) async {
    try {
      await _databaseHelper.transaction((txn) async {
        final noteModel = NoteModel.fromEntity(note);

        // Insert or update note
        await txn.insert(
          DatabaseConstants.notesTable,
          noteModel.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Handle tags
        await _saveNoteTags(txn, note.id, note.tagIds);

        // Update FTS
        await _updateFtsEntry(txn, note);
      });
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to save note: $e');
    }
  }

  @override
  Future<void> updateNote(Note note) async {
    try {
      await _databaseHelper.transaction((txn) async {
        final noteModel = NoteModel.fromEntity(note);

        // Update note
        final rowsAffected = await txn.update(
          DatabaseConstants.notesTable,
          noteModel.toJson(),
          where: '${DatabaseConstants.noteId} = ?',
          whereArgs: [note.id],
        );

        if (rowsAffected == 0) {
          throw app_exceptions.DatabaseException('Note not found for update');
        }

        // Handle tags
        await _saveNoteTags(txn, note.id, note.tagIds);

        // Update FTS
        await _updateFtsEntry(txn, note);
      });
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to update note: $e');
    }
  }

  @override
  Future<void> deleteNote(String id) async {
    try {
      final rowsAffected = await _databaseHelper.update(
        DatabaseConstants.notesTable,
        {
          DatabaseConstants.noteIsDeleted: 1,
          DatabaseConstants.noteUpdatedAt: DateTime.now().toIso8601String(),
        },
        where: '${DatabaseConstants.noteId} = ?',
        whereArgs: [id],
      );

      if (rowsAffected == 0) {
        throw app_exceptions.DatabaseException('Note not found for deletion');
      }
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to delete note: $e');
    }
  }

  @override
  Future<void> archiveNote(String id) async {
    try {
      final rowsAffected = await _databaseHelper.update(
        DatabaseConstants.notesTable,
        {
          DatabaseConstants.noteIsArchived: 1,
          DatabaseConstants.noteUpdatedAt: DateTime.now().toIso8601String(),
        },
        where: '${DatabaseConstants.noteId} = ?',
        whereArgs: [id],
      );

      if (rowsAffected == 0) {
        throw app_exceptions.DatabaseException('Note not found for archiving');
      }
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to archive note: $e');
    }
  }

  @override
  Future<void> unarchiveNote(String id) async {
    try {
      final rowsAffected = await _databaseHelper.update(
        DatabaseConstants.notesTable,
        {
          DatabaseConstants.noteIsArchived: 0,
          DatabaseConstants.noteUpdatedAt: DateTime.now().toIso8601String(),
        },
        where: '${DatabaseConstants.noteId} = ?',
        whereArgs: [id],
      );

      if (rowsAffected == 0) {
        throw app_exceptions.DatabaseException(
          'Note not found for unarchiving',
        );
      }
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to unarchive note: $e');
    }
  }

  @override
  Stream<List<Note>> watchNotes() {
    // For now, return a simple stream that fetches all notes
    // In a real implementation, you might want to use a more sophisticated approach
    late StreamController<List<Note>> controller;
    Timer? timer;

    controller = StreamController<List<Note>>(
      onListen: () {
        // Initial load
        _loadAndEmitNotes(controller);

        // Poll for changes every 2 seconds
        timer = Timer.periodic(const Duration(seconds: 2), (_) {
          _loadAndEmitNotes(controller);
        });
      },
      onCancel: () {
        timer?.cancel();
      },
    );

    return controller.stream;
  }

  void _loadAndEmitNotes(StreamController<List<Note>> controller) {
    getAllNotes()
        .then((notes) {
          if (!controller.isClosed) {
            controller.add(notes);
          }
        })
        .catchError((error) {
          if (!controller.isClosed) {
            controller.addError(error);
          }
        });
  }

  @override
  Future<List<Note>> getNotesByCategory(String categoryId) async {
    try {
      final maps = await _databaseHelper.query(
        DatabaseConstants.notesTable,
        where:
            '${DatabaseConstants.noteCategoryId} = ? AND ${DatabaseConstants.noteIsDeleted} = ?',
        whereArgs: [categoryId, 0],
        orderBy: '${DatabaseConstants.noteUpdatedAt} DESC',
      );

      final notes = <Note>[];
      for (final map in maps) {
        final noteModel = NoteModel.fromJson(map);
        final tagIds = await _getTagIdsForNote(noteModel.id);
        final attachmentIds = await _getAttachmentIdsForNote(noteModel.id);
        notes.add(
          noteModel.toEntity(tagIds: tagIds, attachmentIds: attachmentIds),
        );
      }

      return notes;
    } catch (e) {
      throw app_exceptions.DatabaseException(
        'Failed to get notes by category: $e',
      );
    }
  }

  @override
  Future<List<Note>> getNotesByTag(String tagId) async {
    try {
      final maps = await _databaseHelper.rawQuery(
        '''
        SELECT n.* FROM ${DatabaseConstants.notesTable} n
        INNER JOIN ${DatabaseConstants.noteTagsTable} nt ON n.${DatabaseConstants.noteId} = nt.${DatabaseConstants.noteTagNoteId}
        WHERE nt.${DatabaseConstants.noteTagTagId} = ? AND n.${DatabaseConstants.noteIsDeleted} = ?
        ORDER BY n.${DatabaseConstants.noteUpdatedAt} DESC
      ''',
        [tagId, 0],
      );

      final notes = <Note>[];
      for (final map in maps) {
        final noteModel = NoteModel.fromJson(map);
        final tagIds = await _getTagIdsForNote(noteModel.id);
        final attachmentIds = await _getAttachmentIdsForNote(noteModel.id);
        notes.add(
          noteModel.toEntity(tagIds: tagIds, attachmentIds: attachmentIds),
        );
      }

      return notes;
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get notes by tag: $e');
    }
  }

  @override
  Future<List<Note>> getNotesByPriority(Priority priority) async {
    try {
      final priorityString = _priorityToString(priority);
      final maps = await _databaseHelper.query(
        DatabaseConstants.notesTable,
        where:
            '${DatabaseConstants.notePriority} = ? AND ${DatabaseConstants.noteIsDeleted} = ?',
        whereArgs: [priorityString, 0],
        orderBy: '${DatabaseConstants.noteUpdatedAt} DESC',
      );

      final notes = <Note>[];
      for (final map in maps) {
        final noteModel = NoteModel.fromJson(map);
        final tagIds = await _getTagIdsForNote(noteModel.id);
        final attachmentIds = await _getAttachmentIdsForNote(noteModel.id);
        notes.add(
          noteModel.toEntity(tagIds: tagIds, attachmentIds: attachmentIds),
        );
      }

      return notes;
    } catch (e) {
      throw app_exceptions.DatabaseException(
        'Failed to get notes by priority: $e',
      );
    }
  }

  @override
  Future<List<Note>> getArchivedNotes() async {
    try {
      final maps = await _databaseHelper.query(
        DatabaseConstants.notesTable,
        where:
            '${DatabaseConstants.noteIsArchived} = ? AND ${DatabaseConstants.noteIsDeleted} = ?',
        whereArgs: [1, 0],
        orderBy: '${DatabaseConstants.noteUpdatedAt} DESC',
      );

      final notes = <Note>[];
      for (final map in maps) {
        final noteModel = NoteModel.fromJson(map);
        final tagIds = await _getTagIdsForNote(noteModel.id);
        final attachmentIds = await _getAttachmentIdsForNote(noteModel.id);
        notes.add(
          noteModel.toEntity(tagIds: tagIds, attachmentIds: attachmentIds),
        );
      }

      return notes;
    } catch (e) {
      throw app_exceptions.DatabaseException(
        'Failed to get archived notes: $e',
      );
    }
  }

  @override
  Future<List<Note>> getDeletedNotes() async {
    try {
      final maps = await _databaseHelper.query(
        DatabaseConstants.notesTable,
        where: '${DatabaseConstants.noteIsDeleted} = ?',
        whereArgs: [1],
        orderBy: '${DatabaseConstants.noteUpdatedAt} DESC',
      );

      final notes = <Note>[];
      for (final map in maps) {
        final noteModel = NoteModel.fromJson(map);
        final tagIds = await _getTagIdsForNote(noteModel.id);
        final attachmentIds = await _getAttachmentIdsForNote(noteModel.id);
        notes.add(
          noteModel.toEntity(tagIds: tagIds, attachmentIds: attachmentIds),
        );
      }

      return notes;
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get deleted notes: $e');
    }
  }

  @override
  Future<List<Note>> searchNotes(String query) async {
    try {
      final maps = await _databaseHelper.searchNotes(query);

      final notes = <Note>[];
      for (final map in maps) {
        final noteModel = NoteModel.fromJson(map);
        final tagIds = await _getTagIdsForNote(noteModel.id);
        final attachmentIds = await _getAttachmentIdsForNote(noteModel.id);
        notes.add(
          noteModel.toEntity(tagIds: tagIds, attachmentIds: attachmentIds),
        );
      }

      return notes;
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to search notes: $e');
    }
  }

  @override
  Future<List<Note>> getNotesWithReminders() async {
    try {
      final maps = await _databaseHelper.query(
        DatabaseConstants.notesTable,
        where:
            '${DatabaseConstants.noteReminderDate} IS NOT NULL AND ${DatabaseConstants.noteIsDeleted} = ?',
        whereArgs: [0],
        orderBy: '${DatabaseConstants.noteReminderDate} ASC',
      );

      final notes = <Note>[];
      for (final map in maps) {
        final noteModel = NoteModel.fromJson(map);
        final tagIds = await _getTagIdsForNote(noteModel.id);
        final attachmentIds = await _getAttachmentIdsForNote(noteModel.id);
        notes.add(
          noteModel.toEntity(tagIds: tagIds, attachmentIds: attachmentIds),
        );
      }

      return notes;
    } catch (e) {
      throw app_exceptions.DatabaseException(
        'Failed to get notes with reminders: $e',
      );
    }
  }

  @override
  Future<List<Note>> getNotesDueForSync() async {
    try {
      final maps = await _databaseHelper.query(
        DatabaseConstants.notesTable,
        where: '${DatabaseConstants.noteSyncStatus} = ?',
        whereArgs: [DatabaseConstants.syncStatusPending],
        orderBy: '${DatabaseConstants.noteUpdatedAt} DESC',
      );

      final notes = <Note>[];
      for (final map in maps) {
        final noteModel = NoteModel.fromJson(map);
        final tagIds = await _getTagIdsForNote(noteModel.id);
        final attachmentIds = await _getAttachmentIdsForNote(noteModel.id);
        notes.add(
          noteModel.toEntity(tagIds: tagIds, attachmentIds: attachmentIds),
        );
      }

      return notes;
    } catch (e) {
      throw app_exceptions.DatabaseException(
        'Failed to get notes due for sync: $e',
      );
    }
  }

  // Private helper methods
  Future<List<String>> _getTagIdsForNote(String noteId) async {
    final maps = await _databaseHelper.query(
      DatabaseConstants.noteTagsTable,
      columns: [DatabaseConstants.noteTagTagId],
      where: '${DatabaseConstants.noteTagNoteId} = ?',
      whereArgs: [noteId],
    );

    return maps
        .map((map) => map[DatabaseConstants.noteTagTagId] as String)
        .toList();
  }

  Future<List<String>> _getAttachmentIdsForNote(String noteId) async {
    final maps = await _databaseHelper.query(
      DatabaseConstants.attachmentsTable,
      columns: [DatabaseConstants.attachmentId],
      where: '${DatabaseConstants.attachmentNoteId} = ?',
      whereArgs: [noteId],
    );

    return maps
        .map((map) => map[DatabaseConstants.attachmentId] as String)
        .toList();
  }

  Future<void> _saveNoteTags(
    Transaction txn,
    String noteId,
    List<String> tagIds,
  ) async {
    // Delete existing tags for this note
    await txn.delete(
      DatabaseConstants.noteTagsTable,
      where: '${DatabaseConstants.noteTagNoteId} = ?',
      whereArgs: [noteId],
    );

    // Insert new tags
    for (final tagId in tagIds) {
      await txn.insert(DatabaseConstants.noteTagsTable, {
        DatabaseConstants.noteTagNoteId: noteId,
        DatabaseConstants.noteTagTagId: tagId,
      });
    }
  }

  Future<void> _updateFtsEntry(Transaction txn, Note note) async {
    await txn.rawUpdate(
      '''
      UPDATE ${DatabaseConstants.notesFtsTable} 
      SET title = ?, plain_text = ? 
      WHERE rowid = (
        SELECT rowid FROM ${DatabaseConstants.notesTable} 
        WHERE ${DatabaseConstants.noteId} = ?
      )
    ''',
      [note.title, note.plainText, note.id],
    );
  }

  String _priorityToString(Priority priority) {
    switch (priority) {
      case Priority.low:
        return DatabaseConstants.priorityLow;
      case Priority.medium:
        return DatabaseConstants.priorityMedium;
      case Priority.high:
        return DatabaseConstants.priorityHigh;
    }
  }
}
