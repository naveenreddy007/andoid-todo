class AppConstants {
  // App information
  static const String appName = 'Note Taking App';
  static const String appVersion = '1.0.0';

  // Google Drive configuration
  static const String googleDriveAppFolderName = 'NoteTakingApp';
  static const String notesBackupFileName = 'notes_backup.json';
  static const String configBackupFileName = 'config_backup.json';

  // Notification configuration
  static const String notificationChannelId = 'note_reminders';
  static const String notificationChannelName = 'Note Reminders';
  static const String notificationChannelDescription = 'Notifications for note reminders';

  // Default values
  static const String defaultCategoryColor = '#2196F3';
  static const String defaultTagColor = '#FF9800';
  static const String defaultPriority = 'medium';

  // Limits
  static const int maxNoteTitleLength = 200;
  static const int maxNoteContentLength = 50000;
  static const int maxTagNameLength = 50;
  static const int maxCategoryNameLength = 50;
  static const int maxAttachmentSize = 10 * 1024 * 1024; // 10MB

  // Sync configuration
  static const int syncRetryAttempts = 3;
  static const int syncTimeoutSeconds = 30;
  static const int backgroundSyncIntervalMinutes = 15;

  // Search configuration
  static const int searchResultsLimit = 100;
  static const int recentSearchesLimit = 10;

  // UI configuration
  static const int notesPerPage = 20;
  static const int maxTagsPerNote = 10;
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;

  // File paths
  static const String attachmentsFolderName = 'attachments';
  static const String thumbnailsFolderName = 'thumbnails';

  // Preferences keys
  static const String prefThemeMode = 'theme_mode';
  static const String prefIsFirstLaunch = 'is_first_launch';
  static const String prefGoogleSignedIn = 'google_signed_in';
  static const String prefAutoSync = 'auto_sync';
  static const String prefNotificationsEnabled = 'notifications_enabled';
  static const String prefLastSyncTime = 'last_sync_time';
  static const String prefSyncOnWifiOnly = 'sync_on_wifi_only';
  static const String prefDefaultCategory = 'default_category';
  static const String prefSortOrder = 'sort_order';
  static const String prefViewMode = 'view_mode';

  // Sort orders
  static const String sortByDateCreated = 'date_created';
  static const String sortByDateUpdated = 'date_updated';
  static const String sortByTitle = 'title';
  static const String sortByPriority = 'priority';

  // View modes
  static const String viewModeList = 'list';
  static const String viewModeGrid = 'grid';

  // Error messages
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'Network error. Please check your connection.';
  static const String errorSync = 'Sync failed. Please try again later.';
  static const String errorGoogleSignIn = 'Google Sign-In failed. Please try again.';
  static const String errorPermissionDenied = 'Permission denied. Please grant the required permissions.';
  static const String errorFileNotFound = 'File not found.';
  static const String errorFileTooLarge = 'File size exceeds the maximum limit.';

  // Success messages
  static const String successNoteSaved = 'Note saved successfully';
  static const String successNoteDeleted = 'Note deleted successfully';
  static const String successSyncCompleted = 'Sync completed successfully';
  static const String successGoogleSignIn = 'Signed in to Google Drive successfully';
}