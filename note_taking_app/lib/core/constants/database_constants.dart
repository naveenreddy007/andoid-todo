class DatabaseConstants {
  // Database info
  static const String dbName = 'todo_app.db';
  static const int dbVersion = 1;

  // Table names
  static const String todosTable = 'todos';
  static const String categoriesTable = 'categories';
  static const String tagsTable = 'tags';
  static const String todoTagsTable = 'todo_tags';
  static const String remindersTable = 'reminders';
  static const String attachmentsTable = 'attachments';
  static const String syncMetadataTable = 'sync_metadata';
  static const String googleDriveFilesTable = 'google_drive_files';

  // Indexes
  static const String idxTodosPriority =
      'CREATE INDEX idx_todos_priority ON $todosTable($todoPriority)';
  static const String idxTodosStatus =
      'CREATE INDEX idx_todos_status ON $todosTable($todoStatus)';
  static const String idxTodosDueDate =
      'CREATE INDEX idx_todos_due_date ON $todosTable($todoDueDate)';
  static const String idxTodosIsDeleted =
      'CREATE INDEX idx_todos_is_deleted ON $todosTable($todoIsDeleted)';
  static const String idxRemindersDateTime =
      'CREATE INDEX idx_reminders_datetime ON $remindersTable($reminderDateTime)';
  static const String idxRemindersTodoId =
      'CREATE INDEX idx_reminders_todo_id ON $remindersTable($reminderTodoId)';

  // Todo columns
  static const String todoId = 'id';
  static const String todoTitle = 'title';
  static const String todoDescription = 'description';
  static const String todoStatus = 'status';
  static const String todoPriority = 'priority';
  static const String todoDueDate = 'due_date';
  static const String todoCompletedAt = 'completed_at';
  static const String todoCreatedAt = 'created_at';
  static const String todoUpdatedAt = 'updated_at';
  static const String todoCategoryId = 'category_id';
  static const String todoIsDeleted = 'is_deleted';
  static const String todoSyncStatus = 'sync_status';
  static const String todoLastSynced = 'last_synced';
  static const String todoCloudFileId = 'cloud_file_id';

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

  // Todo-Tag junction columns
  static const String todoTagTodoId = 'todo_id';
  static const String todoTagTagId = 'tag_id';

  // Reminder columns
  static const String reminderId = 'id';
  static const String reminderTodoId = 'todo_id';
  static const String reminderDateTime = 'reminder_datetime';
  static const String reminderType = 'type';
  static const String reminderIsActive = 'is_active';
  static const String reminderCreatedAt = 'created_at';

  // Attachment columns
  static const String attachmentId = 'id';
  static const String attachmentTodoId = 'todo_id';
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

  // Google Drive Files columns
  static const String googleDriveFileId = 'id';
  static const String googleDriveFileEntityType = 'entity_type';
  static const String googleDriveFileEntityId = 'entity_id';
  static const String googleDriveFileGoogleFileId = 'google_file_id';
  static const String googleDriveFileName = 'file_name';
  static const String googleDriveFileModifiedTime = 'modified_time';
  static const String googleDriveFileCreatedAt = 'created_at';

  // Query limits
  static const int defaultLimit = 50;
  static const int maxLimit = 1000;

  // Priority values
  static const String priorityLow = 'low';
  static const String priorityMedium = 'medium';
  static const String priorityHigh = 'high';

  // Todo status values
  static const String statusPending = 'pending';
  static const String statusInProgress = 'in_progress';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  // Reminder types
  static const String reminderTypeOneTime = 'one_time';
  static const String reminderTypeRecurring = 'recurring';

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
  static const String entityTypeTodo = 'todo';
  static const String entityTypeTag = 'tag';
  static const String entityTypeCategory = 'category';
  static const String entityTypeReminder = 'reminder';
  static const String entityTypeAttachment = 'attachment';

  // Table creation SQL
  static const String createTodosTable = '''
    CREATE TABLE $todosTable (
      $todoId TEXT PRIMARY KEY,
      $todoTitle TEXT NOT NULL,
      $todoDescription TEXT,
      $todoStatus TEXT NOT NULL DEFAULT '$statusPending',
      $todoPriority TEXT NOT NULL DEFAULT '$priorityMedium',
      $todoDueDate TEXT,
      $todoCompletedAt TEXT,
      $todoCreatedAt TEXT NOT NULL,
      $todoUpdatedAt TEXT NOT NULL,
      $todoCategoryId TEXT,
      $todoIsDeleted INTEGER NOT NULL DEFAULT 0,
      $todoSyncStatus TEXT NOT NULL DEFAULT '$syncStatusPending',
      $todoLastSynced TEXT,
      $todoCloudFileId TEXT,
      FOREIGN KEY ($todoCategoryId) REFERENCES $categoriesTable($categoryId)
    )
  ''';

  static const String createCategoriesTable = '''
    CREATE TABLE $categoriesTable (
      $categoryId TEXT PRIMARY KEY,
      $categoryName TEXT NOT NULL,
      $categoryIcon TEXT,
      $categoryColor TEXT NOT NULL,
      $categoryCreatedAt TEXT NOT NULL
    )
  ''';

  static const String createTagsTable = '''
    CREATE TABLE $tagsTable (
      $tagId TEXT PRIMARY KEY,
      $tagName TEXT NOT NULL UNIQUE,
      $tagColor TEXT NOT NULL,
      $tagCreatedAt TEXT NOT NULL
    )
  ''';

  static const String createTodoTagsTable = '''
    CREATE TABLE $todoTagsTable (
      $todoTagTodoId TEXT NOT NULL,
      $todoTagTagId TEXT NOT NULL,
      PRIMARY KEY ($todoTagTodoId, $todoTagTagId),
      FOREIGN KEY ($todoTagTodoId) REFERENCES $todosTable($todoId) ON DELETE CASCADE,
      FOREIGN KEY ($todoTagTagId) REFERENCES $tagsTable($tagId) ON DELETE CASCADE
    )
  ''';

  static const String createRemindersTable = '''
    CREATE TABLE $remindersTable (
      $reminderId TEXT PRIMARY KEY,
      $reminderTodoId TEXT NOT NULL,
      $reminderDateTime TEXT NOT NULL,
      $reminderType TEXT NOT NULL DEFAULT '$reminderTypeOneTime',
      $reminderIsActive INTEGER NOT NULL DEFAULT 1,
      $reminderCreatedAt TEXT NOT NULL,
      FOREIGN KEY ($reminderTodoId) REFERENCES $todosTable($todoId) ON DELETE CASCADE
    )
  ''';

  static const String createAttachmentsTable = '''
    CREATE TABLE $attachmentsTable (
      $attachmentId TEXT PRIMARY KEY,
      $attachmentTodoId TEXT NOT NULL,
      $attachmentFileName TEXT NOT NULL,
      $attachmentFilePath TEXT NOT NULL,
      $attachmentMimeType TEXT,
      $attachmentFileSize INTEGER,
      $attachmentCreatedAt TEXT NOT NULL,
      FOREIGN KEY ($attachmentTodoId) REFERENCES $todosTable($todoId) ON DELETE CASCADE
    )
  ''';

  static const String createSyncMetadataTable = '''
    CREATE TABLE $syncMetadataTable (
      $syncMetadataId TEXT PRIMARY KEY,
      $syncMetadataEntityType TEXT NOT NULL,
      $syncMetadataEntityId TEXT NOT NULL,
      $syncMetadataLocalHash TEXT,
      $syncMetadataCloudHash TEXT,
      $syncMetadataLastSync TEXT,
      $syncMetadataConflictStatus TEXT NOT NULL DEFAULT '$conflictStatusNone',
      UNIQUE($syncMetadataEntityType, $syncMetadataEntityId)
    )
  ''';

  static const String createGoogleDriveFilesTable = '''
    CREATE TABLE $googleDriveFilesTable (
      $googleDriveFileId TEXT PRIMARY KEY,
      $googleDriveFileEntityType TEXT NOT NULL,
      $googleDriveFileEntityId TEXT NOT NULL,
      $googleDriveFileGoogleFileId TEXT NOT NULL UNIQUE,
      $googleDriveFileName TEXT NOT NULL,
      $googleDriveFileModifiedTime TEXT,
      $googleDriveFileCreatedAt TEXT NOT NULL,
      UNIQUE($googleDriveFileEntityType, $googleDriveFileEntityId)
    )
  ''';
}
