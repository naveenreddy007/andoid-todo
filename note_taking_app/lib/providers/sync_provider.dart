import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../data/services/google_drive_auth_service.dart';
import '../data/services/google_drive_service.dart';
import '../data/services/sync_manager.dart';
import 'todo_provider.dart';
import 'category_provider.dart';
import 'tag_provider.dart';

// Google Drive Auth Service Provider
final googleDriveAuthServiceProvider = Provider<GoogleDriveAuthService>((ref) {
  return GoogleDriveAuthService();
});

// Google Drive Service Provider
final googleDriveServiceProvider = Provider<GoogleDriveService>((ref) {
  final authService = ref.watch(googleDriveAuthServiceProvider);
  return GoogleDriveService(authService);
});

// Sync Manager Provider
final syncManagerProvider = Provider<SyncManager>((ref) {
  final authService = ref.watch(googleDriveAuthServiceProvider);
  final driveService = ref.watch(googleDriveServiceProvider);
  final todoRepository = ref.watch(todoRepositoryProvider);
  final categoryRepository = ref.watch(categoryRepositoryProvider);
  final tagRepository = ref.watch(tagRepositoryProvider);
  
  return SyncManager(
    authService: authService,
    driveService: driveService,
    todoRepository: todoRepository,
    categoryRepository: categoryRepository,
    tagRepository: tagRepository,
  );
});

// Sync Status Stream Provider
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  return syncManager.statusStream;
});

// Sync Progress Stream Provider
final syncProgressProvider = StreamProvider<SyncProgress>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  return syncManager.progressStream;
});

// Sync Conflicts Stream Provider
final syncConflictsProvider = StreamProvider<List<SyncConflict>>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  return syncManager.conflictsStream;
});

// Current Sync Status Provider
final currentSyncStatusProvider = Provider<SyncStatus>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  return syncManager.currentStatus;
});

// Pending Conflicts Provider
final pendingConflictsProvider = Provider<List<SyncConflict>>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  return syncManager.pendingConflicts;
});

// Has Conflicts Provider
final hasConflictsProvider = Provider<bool>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  return syncManager.hasConflicts;
});

// Authentication Status Provider
final authStatusProvider = Provider<bool>((ref) {
  final authService = ref.watch(googleDriveAuthServiceProvider);
  return authService.isAuthenticated;
});

// Connectivity Status Provider
final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged;
});

// Is Online Provider
final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.when(
    data: (result) => result != ConnectivityResult.none,
    loading: () => true, // Assume online while loading
    error: (_, __) => false,
  );
});

// Sync Stats Provider
final syncStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final syncManager = ref.watch(syncManagerProvider);
  return await syncManager.getSyncStats();
});

// Sync Operations Notifier
class SyncOperationsNotifier extends StateNotifier<AsyncValue<void>> {
  final SyncManager _syncManager;
  final GoogleDriveAuthService _authService;
  
  SyncOperationsNotifier(this._syncManager, this._authService) 
      : super(const AsyncValue.data(null));
  
  /// Initialize sync manager
  Future<void> initialize() async {
    state = const AsyncValue.loading();
    try {
      await _syncManager.initialize();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  /// Sign in to Google Drive
  Future<bool> signIn() async {
    state = const AsyncValue.loading();
    try {
      final success = await _authService.signIn();
      if (success) {
        await _syncManager.initialize();
      }
      state = const AsyncValue.data(null);
      return success;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }
  
  /// Sign out from Google Drive
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authService.signOut();
      _syncManager.stopAutoSync();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  /// Perform manual sync
  Future<bool> performSync(SyncDirection direction) async {
    state = const AsyncValue.loading();
    try {
      final success = await _syncManager.performSync(direction);
      state = const AsyncValue.data(null);
      return success;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }
  
  /// Force upload all data
  Future<bool> forceUpload() async {
    state = const AsyncValue.loading();
    try {
      final success = await _syncManager.forceUpload();
      state = const AsyncValue.data(null);
      return success;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }
  
  /// Force download all data
  Future<bool> forceDownload() async {
    state = const AsyncValue.loading();
    try {
      final success = await _syncManager.forceDownload();
      state = const AsyncValue.data(null);
      return success;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }
  
  /// Resolve sync conflicts
  Future<bool> resolveConflicts(Map<String, String> resolutions) async {
    state = const AsyncValue.loading();
    try {
      final success = await _syncManager.resolveConflicts(resolutions);
      state = const AsyncValue.data(null);
      return success;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }
  
  /// Start auto sync
  void startAutoSync({Duration interval = const Duration(minutes: 15)}) {
    _syncManager.startAutoSync(interval: interval);
  }
  
  /// Stop auto sync
  void stopAutoSync() {
    _syncManager.stopAutoSync();
  }
}

// Sync Operations Provider
final syncOperationsProvider = StateNotifierProvider<SyncOperationsNotifier, AsyncValue<void>>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  final authService = ref.watch(googleDriveAuthServiceProvider);
  return SyncOperationsNotifier(syncManager, authService);
});

// Sync Settings Notifier
class SyncSettingsNotifier extends StateNotifier<SyncSettings> {
  SyncSettingsNotifier() : super(SyncSettings.defaultSettings());
  
  void updateAutoSyncEnabled(bool enabled) {
    state = state.copyWith(autoSyncEnabled: enabled);
  }
  
  void updateAutoSyncInterval(Duration interval) {
    state = state.copyWith(autoSyncInterval: interval);
  }
  
  void updateSyncOnWifiOnly(bool wifiOnly) {
    state = state.copyWith(syncOnWifiOnly: wifiOnly);
  }
  
  void updateConflictResolution(ConflictResolutionStrategy strategy) {
    state = state.copyWith(conflictResolution: strategy);
  }
  
  void updateShowSyncNotifications(bool show) {
    state = state.copyWith(showSyncNotifications: show);
  }
}

// Sync Settings Provider
final syncSettingsProvider = StateNotifierProvider<SyncSettingsNotifier, SyncSettings>((ref) {
  return SyncSettingsNotifier();
});

// Sync Settings Model
class SyncSettings {
  final bool autoSyncEnabled;
  final Duration autoSyncInterval;
  final bool syncOnWifiOnly;
  final ConflictResolutionStrategy conflictResolution;
  final bool showSyncNotifications;
  
  const SyncSettings({
    required this.autoSyncEnabled,
    required this.autoSyncInterval,
    required this.syncOnWifiOnly,
    required this.conflictResolution,
    required this.showSyncNotifications,
  });
  
  factory SyncSettings.defaultSettings() {
    return const SyncSettings(
      autoSyncEnabled: true,
      autoSyncInterval: Duration(minutes: 15),
      syncOnWifiOnly: false,
      conflictResolution: ConflictResolutionStrategy.askUser,
      showSyncNotifications: true,
    );
  }
  
  SyncSettings copyWith({
    bool? autoSyncEnabled,
    Duration? autoSyncInterval,
    bool? syncOnWifiOnly,
    ConflictResolutionStrategy? conflictResolution,
    bool? showSyncNotifications,
  }) {
    return SyncSettings(
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      autoSyncInterval: autoSyncInterval ?? this.autoSyncInterval,
      syncOnWifiOnly: syncOnWifiOnly ?? this.syncOnWifiOnly,
      conflictResolution: conflictResolution ?? this.conflictResolution,
      showSyncNotifications: showSyncNotifications ?? this.showSyncNotifications,
    );
  }
}

// Conflict Resolution Strategy
enum ConflictResolutionStrategy {
  askUser,
  useLocal,
  useRemote,
  useMostRecent,
}

// Can Sync Provider (checks all conditions)
final canSyncProvider = Provider<bool>((ref) {
  final isAuthenticated = ref.watch(authStatusProvider);
  final isOnline = ref.watch(isOnlineProvider);
  final syncStatus = ref.watch(currentSyncStatusProvider);
  final settings = ref.watch(syncSettingsProvider);
  
  if (!isAuthenticated || !isOnline) return false;
  if (syncStatus == SyncStatus.syncing) return false;
  
  // Check WiFi-only setting
  if (settings.syncOnWifiOnly) {
    final connectivity = ref.watch(connectivityProvider);
    return connectivity.when(
      data: (result) => result == ConnectivityResult.wifi,
      loading: () => false,
      error: (_, __) => false,
    );
  }
  
  return true;
});

// Sync Status Message Provider
final syncStatusMessageProvider = Provider<String>((ref) {
  final status = ref.watch(currentSyncStatusProvider);
  final isAuthenticated = ref.watch(authStatusProvider);
  final isOnline = ref.watch(isOnlineProvider);
  
  if (!isAuthenticated) return 'Not signed in to Google Drive';
  if (!isOnline) return 'No internet connection';
  
  switch (status) {
    case SyncStatus.idle:
      return 'Ready to sync';
    case SyncStatus.syncing:
      return 'Syncing...';
    case SyncStatus.success:
      return 'Sync completed successfully';
    case SyncStatus.error:
      return 'Sync failed';
    case SyncStatus.conflict:
      return 'Conflicts need resolution';
    case SyncStatus.noInternet:
      return 'No internet connection';
    case SyncStatus.notAuthenticated:
      return 'Not signed in to Google Drive';
  }
});

// Last Sync Time Provider
final lastSyncTimeProvider = FutureProvider<DateTime?>((ref) async {
  final stats = await ref.watch(syncStatsProvider.future);
  final lastSyncString = stats['lastSyncTime'] as String?;
  if (lastSyncString != null) {
    return DateTime.parse(lastSyncString);
  }
  return null;
});