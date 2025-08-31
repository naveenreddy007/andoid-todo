class DatabaseConstants {
  // Table names
  static const String notesTable = 'notes';
  static const String tagsTable = 'tags';
  static const String categoriesTable = 'categories';
  static const String noteTagsTable = 'note_tags';
  static const String attachmentsTable = 'attachments';
  static const String syncMetadataTable = 'sync_metadata';
  static const String notesFtsTable = 'notes_fts';

  // Note columns
  static const String noteId = 'id';
  static const String noteTitle = 'title';
  static const String noteContent = 'content';
  static const String notePlainText = 'plain_text';
  static const String noteCreatedAt = 'created_at';
  static const String noteUpdatedAt = 'updated_at';
  static const String noteReminderDate = 'reminder_date';
  static const String notePriority = 'priority';
  static const String noteCategoryId = 'category_id';
  static const String noteIsArchived = 'is_archived';
  static const String noteIsDeleted = 'is_deleted';
  static const String noteSyncStatus = 'sync_status';
  static const String noteLastSynced = 'last_synced';
  static const String noteCloudFileId = 'cloud_file_id';

  // Tag columns
  static const String tagId = 'id';
  static const String tagName = 'name';
  static const String tagColor = 'color';
  static const String tagCreatedAt = 'created_at';

  // Category columns
  static const String categoryId = 'id';
  static const String categoryName = 'name';
  static const String categoryIcon = 'icon';
  static const String categoryColor = 'color';
  static const String categoryCreatedAt = 'created_at';

  // Note-Tag junction columns
  static const String noteTagNoteId = 'note_id';
  static const String noteTagTagId = 'tag_id';

  // Attachment columns
  static const String attachmentId = 'id';
  static const String attachmentNoteId = 'note_id';
  static const String attachmentFileName = 'file_name';
  static const String attachmentFilePath = 'file_path';
  static const String attachmentMimeType = 'mime_type';
  static const String attachmentFileSize = 'file_size';
  static const String attachmentCreatedAt = 'created_at';

  // Sync metadata columns
  static const String syncMetadataId = 'id';
  static const String syncMetadataEntityType = 'entity_type';
  static const String syncMetadataEntityId = 'entity_id';
  static const String syncMetadataLocalHash = 'local_hash';
  static const String syncMetadataCloudHash = 'cloud_hash';
  static const String syncMetadataLastSync = 'last_sync';
  static const String syncMetadataConflictStatus = 'conflict_status';

  // Query limits
  static const int defaultLimit = 50;
  static const int maxLimit = 1000;

  // Priority values
  static const String priorityLow = 'low';
  static const String priorityMedium = 'medium';
  static const String priorityHigh = 'high';

  // Sync status values
  static const String syncStatusPending = 'pending';
  static const String syncStatusSynced = 'synced';
  static const String syncStatusFailed = 'failed';
  static const String syncStatusConflict = 'conflict';

  // Conflict status values
  static const String conflictStatusNone = 'none';
  static const String conflictStatusDetected = 'detected';
  static const String conflictStatusResolved = 'resolved';

  // Entity types for sync metadata
  static const String entityTypeNote = 'note';
  static const String entityTypeTag = 'tag';
  static const String entityTypeCategory = 'category';
}