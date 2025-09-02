import 'dart:async';
import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'google_drive_auth_service.dart';
import 'google_drive_service.dart';
import '../repositories/local_todo_repository.dart';
import '../repositories/local_category_repository.dart';
import '../repositories/local_tag_repository.dart';
import '../../domain/entities/todo.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/tag.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  conflict,
  noInternet,
  notAuthenticated,
}

enum SyncDirection {
  upload,
  download,
  bidirectional,
}

class SyncConflict {
  final String type; // 'todo', 'category', 'tag'
  final String id;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final DateTime localModified;
  final DateTime remoteModified;
  
  SyncConflict({
    required this.type,
    required this.id,
    required this.localData,
    required this.remoteData,
    required this.localModified,
    required this.remoteModified,
  });
}

class SyncProgress {
  final int totalItems;
  final int completedItems;
  final String currentOperation;
  final SyncStatus status;
  
  SyncProgress({
    required this.totalItems,
    required this.completedItems,
    required this.currentOperation,
    required this.status,
  });
  
  double get percentage => totalItems > 0 ? completedItems / totalItems : 0.0;
}

class SyncManager {
  final GoogleDriveAuthService _authService;
  final GoogleDriveService _driveService;
  final LocalTodoRepository _todoRepository;
  final LocalCategoryRepository _categoryRepository;
  final LocalTagRepository _tagRepository;
  final Logger _logger = Logger();
  
  final StreamController<SyncStatus> _statusController = StreamController<SyncStatus>.broadcast();
  final StreamController<SyncProgress> _progressController = StreamController<SyncProgress>.broadcast();
  final StreamController<List<SyncConflict>> _conflictsController = StreamController<List<SyncConflict>>.broadcast();
  
  SyncStatus _currentStatus = SyncStatus.idle;
  List<SyncConflict> _pendingConflicts = [];
  Timer? _autoSyncTimer;
  
  SyncManager({
    required GoogleDriveAuthService authService,
    required GoogleDriveService driveService,
    required LocalTodoRepository todoRepository,
    required LocalCategoryRepository categoryRepository,
    required LocalTagRepository tagRepository,
  }) : _authService = authService,
       _driveService = driveService,
       _todoRepository = todoRepository,
       _categoryRepository = categoryRepository,
       _tagRepository = tagRepository;
  
  // Streams
  Stream<SyncStatus> get statusStream => _statusController.stream;
  Stream<SyncProgress> get progressStream => _progressController.stream;
  Stream<List<SyncConflict>> get conflictsStream => _conflictsController.stream;
  
  // Current state
  SyncStatus get currentStatus => _currentStatus;
  List<SyncConflict> get pendingConflicts => List.unmodifiable(_pendingConflicts);
  bool get hasConflicts => _pendingConflicts.isNotEmpty;
  
  /// Initialize the sync manager
  Future<void> initialize() async {
    try {
      _logger.i('Initializing sync manager');
      
      // Check authentication status
      if (!_authService.isAuthenticated) {
        _updateStatus(SyncStatus.notAuthenticated);
        return;
      }
      
      // Initialize Google Drive service
      final initialized = await _driveService.initialize();
      if (!initialized) {
        _updateStatus(SyncStatus.error);
        return;
      }
      
      _updateStatus(SyncStatus.idle);
      _logger.i('Sync manager initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize sync manager: $e');
      _updateStatus(SyncStatus.error);
    }
  }
  
  /// Start automatic sync with specified interval
  void startAutoSync({Duration interval = const Duration(minutes: 15)}) {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(interval, (_) {
      if (_currentStatus == SyncStatus.idle) {
        performSync(SyncDirection.bidirectional, showProgress: false);
      }
    });
    _logger.i('Auto sync started with interval: ${interval.inMinutes} minutes');
  }
  
  /// Stop automatic sync
  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    _logger.i('Auto sync stopped');
  }
  
  /// Perform synchronization
  Future<bool> performSync(
    SyncDirection direction, {
    bool showProgress = true,
    bool resolveConflicts = true,
  }) async {
    if (_currentStatus == SyncStatus.syncing) {
      _logger.w('Sync already in progress');
      return false;
    }
    
    try {
      // Check internet connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _updateStatus(SyncStatus.noInternet);
        return false;
      }
      
      // Check authentication
      if (!_authService.isAuthenticated) {
        _updateStatus(SyncStatus.notAuthenticated);
        return false;
      }
      
      _updateStatus(SyncStatus.syncing);
      _logger.i('Starting sync with direction: $direction');
      
      bool success = false;
      
      switch (direction) {
        case SyncDirection.upload:
          success = await _performUpload(showProgress);
          break;
        case SyncDirection.download:
          success = await _performDownload(showProgress);
          break;
        case SyncDirection.bidirectional:
          success = await _performBidirectionalSync(showProgress, resolveConflicts);
          break;
      }
      
      if (success && _pendingConflicts.isEmpty) {
        _updateStatus(SyncStatus.success);
        await _updateSyncMetadata();
      } else if (_pendingConflicts.isNotEmpty) {
        _updateStatus(SyncStatus.conflict);
        _conflictsController.add(_pendingConflicts);
      } else {
        _updateStatus(SyncStatus.error);
      }
      
      return success;
    } catch (e) {
      _logger.e('Sync failed: $e');
      _updateStatus(SyncStatus.error);
      return false;
    }
  }
  
  /// Resolve conflicts with user choices
  Future<bool> resolveConflicts(Map<String, String> resolutions) async {
    try {
      _logger.i('Resolving ${resolutions.length} conflicts');
      
      for (final conflict in _pendingConflicts) {
        final resolution = resolutions[conflict.id];
        if (resolution == null) continue;
        
        switch (resolution) {
          case 'local':
            await _applyLocalData(conflict);
            break;
          case 'remote':
            await _applyRemoteData(conflict);
            break;
          case 'merge':
            await _mergeData(conflict);
            break;
        }
      }
      
      _pendingConflicts.clear();
      _updateStatus(SyncStatus.success);
      await _updateSyncMetadata();
      
      _logger.i('All conflicts resolved successfully');
      return true;
    } catch (e) {
      _logger.e('Failed to resolve conflicts: $e');
      _updateStatus(SyncStatus.error);
      return false;
    }
  }
  
  /// Force upload all local data
  Future<bool> forceUpload() async {
    return await performSync(SyncDirection.upload);
  }
  
  /// Force download all remote data
  Future<bool> forceDownload() async {
    return await performSync(SyncDirection.download);
  }
  
  /// Get sync statistics
  Future<Map<String, dynamic>> getSyncStats() async {
    try {
      final metadata = await _driveService.downloadSyncMetadata();
      final storageInfo = await _driveService.getStorageInfo();
      
      final localTodos = await _todoRepository.getAllTodos();
      final localCategories = await _categoryRepository.getAllCategories();
      final localTags = await _tagRepository.getAllTags();
      
      return {
        'lastSyncTime': metadata?['lastSyncTime'],
        'totalSyncs': metadata?['totalSyncs'] ?? 0,
        'localTodos': localTodos.length,
        'localCategories': localCategories.length,
        'localTags': localTags.length,
        'storageUsed': storageInfo?['usedSpace'],
        'storageTotal': storageInfo?['totalSpace'],
        'userEmail': storageInfo?['userEmail'],
      };
    } catch (e) {
      _logger.e('Failed to get sync stats: $e');
      return {};
    }
  }
  
  /// Perform upload sync
  Future<bool> _performUpload(bool showProgress) async {
    try {
      final todos = await _todoRepository.getAllTodos();
      final categories = await _categoryRepository.getAllCategories();
      final tags = await _tagRepository.getAllTags();
      
      final totalItems = todos.length + categories.length + tags.length;
      int completedItems = 0;
      
      if (showProgress) {
        _progressController.add(SyncProgress(
          totalItems: totalItems,
          completedItems: completedItems,
          currentOperation: 'Uploading todos...',
          status: SyncStatus.syncing,
        ));
      }
      
      // Upload todos
      final todosSuccess = await _driveService.uploadTodos(todos);
      if (!todosSuccess) return false;
      completedItems += todos.length;
      
      if (showProgress) {
        _progressController.add(SyncProgress(
          totalItems: totalItems,
          completedItems: completedItems,
          currentOperation: 'Uploading categories...',
          status: SyncStatus.syncing,
        ));
      }
      
      // Upload categories
      final categoriesSuccess = await _driveService.uploadCategories(categories);
      if (!categoriesSuccess) return false;
      completedItems += categories.length;
      
      if (showProgress) {
        _progressController.add(SyncProgress(
          totalItems: totalItems,
          completedItems: completedItems,
          currentOperation: 'Uploading tags...',
          status: SyncStatus.syncing,
        ));
      }
      
      // Upload tags
      final tagsSuccess = await _driveService.uploadTags(tags);
      if (!tagsSuccess) return false;
      completedItems += tags.length;
      
      if (showProgress) {
        _progressController.add(SyncProgress(
          totalItems: totalItems,
          completedItems: completedItems,
          currentOperation: 'Upload complete',
          status: SyncStatus.success,
        ));
      }
      
      _logger.i('Upload sync completed successfully');
      return true;
    } catch (e) {
      _logger.e('Upload sync failed: $e');
      return false;
    }
  }
  
  /// Perform download sync
  Future<bool> _performDownload(bool showProgress) async {
    try {
      if (showProgress) {
        _progressController.add(SyncProgress(
          totalItems: 3,
          completedItems: 0,
          currentOperation: 'Downloading todos...',
          status: SyncStatus.syncing,
        ));
      }
      
      // Download todos
      final remoteTodos = await _driveService.downloadTodos();
      if (remoteTodos != null) {
        for (final todo in remoteTodos) {
          await _todoRepository.saveTodo(todo);
        }
      }
      
      if (showProgress) {
        _progressController.add(SyncProgress(
          totalItems: 3,
          completedItems: 1,
          currentOperation: 'Downloading categories...',
          status: SyncStatus.syncing,
        ));
      }
      
      // Download categories
      final remoteCategories = await _driveService.downloadCategories();
      if (remoteCategories != null) {
        for (final category in remoteCategories) {
          await _categoryRepository.saveCategory(category);
        }
      }
      
      if (showProgress) {
        _progressController.add(SyncProgress(
          totalItems: 3,
          completedItems: 2,
          currentOperation: 'Downloading tags...',
          status: SyncStatus.syncing,
        ));
      }
      
      // Download tags
      final remoteTags = await _driveService.downloadTags();
      if (remoteTags != null) {
        for (final tag in remoteTags) {
          await _tagRepository.saveTag(tag);
        }
      }
      
      if (showProgress) {
        _progressController.add(SyncProgress(
          totalItems: 3,
          completedItems: 3,
          currentOperation: 'Download complete',
          status: SyncStatus.success,
        ));
      }
      
      _logger.i('Download sync completed successfully');
      return true;
    } catch (e) {
      _logger.e('Download sync failed: $e');
      return false;
    }
  }
  
  /// Perform bidirectional sync with conflict detection
  Future<bool> _performBidirectionalSync(bool showProgress, bool resolveConflicts) async {
    try {
      _pendingConflicts.clear();
      
      // Get local and remote data
      final localTodos = await _todoRepository.getAllTodos();
      final localCategories = await _categoryRepository.getAllCategories();
      final localTags = await _tagRepository.getAllTags();
      
      final remoteTodos = await _driveService.downloadTodos() ?? [];
      final remoteCategories = await _driveService.downloadCategories() ?? [];
      final remoteTags = await _driveService.downloadTags() ?? [];
      
      // Detect conflicts
      await _detectConflicts('todo', localTodos, remoteTodos);
      await _detectConflicts('category', localCategories, remoteCategories);
      await _detectConflicts('tag', localTags, remoteTags);
      
      if (_pendingConflicts.isNotEmpty && !resolveConflicts) {
        _logger.w('Conflicts detected, manual resolution required');
        return false;
      }
      
      // If no conflicts or auto-resolve enabled, proceed with sync
      if (_pendingConflicts.isEmpty) {
        // Merge data without conflicts
        await _mergeWithoutConflicts(localTodos, remoteTodos, localCategories, remoteCategories, localTags, remoteTags);
        return true;
      }
      
      return false;
    } catch (e) {
      _logger.e('Bidirectional sync failed: $e');
      return false;
    }
  }
  
  /// Detect conflicts between local and remote data
  Future<void> _detectConflicts<T>(String type, List<T> localItems, List<T> remoteItems) async {
    final localMap = <String, T>{};
    final remoteMap = <String, T>{};
    
    // Create maps for easier lookup
    for (final item in localItems) {
      final id = _getId(item);
      localMap[id] = item;
    }
    
    for (final item in remoteItems) {
      final id = _getId(item);
      remoteMap[id] = item;
    }
    
    // Check for conflicts
    for (final id in localMap.keys) {
      if (remoteMap.containsKey(id)) {
        final localItem = localMap[id]!;
        final remoteItem = remoteMap[id]!;
        
        final localModified = _getModifiedTime(localItem);
        final remoteModified = _getModifiedTime(remoteItem);
        
        // Check if items are different
        if (!_areItemsEqual(localItem, remoteItem)) {
          _pendingConflicts.add(SyncConflict(
            type: type,
            id: id,
            localData: _toJson(localItem),
            remoteData: _toJson(remoteItem),
            localModified: localModified,
            remoteModified: remoteModified,
          ));
        }
      }
    }
  }
  
  /// Merge data without conflicts
  Future<void> _mergeWithoutConflicts(
    List<Todo> localTodos,
    List<Todo> remoteTodos,
    List<Category> localCategories,
    List<Category> remoteCategories,
    List<Tag> localTags,
    List<Tag> remoteTags,
  ) async {
    // Merge todos
    final todoMap = <String, Todo>{};
    for (final todo in localTodos) {
      todoMap[todo.id] = todo;
    }
    for (final todo in remoteTodos) {
      if (!todoMap.containsKey(todo.id)) {
        todoMap[todo.id] = todo;
        await _todoRepository.saveTodo(todo);
      }
    }
    
    // Merge categories
    final categoryMap = <String, Category>{};
    for (final category in localCategories) {
      categoryMap[category.id] = category;
    }
    for (final category in remoteCategories) {
      if (!categoryMap.containsKey(category.id)) {
        categoryMap[category.id] = category;
        await _categoryRepository.saveCategory(category);
      }
    }
    
    // Merge tags
    final tagMap = <String, Tag>{};
    for (final tag in localTags) {
      tagMap[tag.id] = tag;
    }
    for (final tag in remoteTags) {
      if (!tagMap.containsKey(tag.id)) {
        tagMap[tag.id] = tag;
        await _tagRepository.saveTag(tag);
      }
    }
    
    // Upload merged data
    await _driveService.uploadTodos(todoMap.values.toList());
    await _driveService.uploadCategories(categoryMap.values.toList());
    await _driveService.uploadTags(tagMap.values.toList());
  }
  
  /// Apply local data for conflict resolution
  Future<void> _applyLocalData(SyncConflict conflict) async {
    // Local data wins, upload to remote
    switch (conflict.type) {
      case 'todo':
        final todo = Todo.fromJson(conflict.localData);
        await _driveService.uploadTodos([todo]);
        break;
      case 'category':
        final category = Category.fromJson(conflict.localData);
        await _driveService.uploadCategories([category]);
        break;
      case 'tag':
        final tag = Tag.fromJson(conflict.localData);
        await _driveService.uploadTags([tag]);
        break;
    }
  }
  
  /// Apply remote data for conflict resolution
  Future<void> _applyRemoteData(SyncConflict conflict) async {
    // Remote data wins, update local
    switch (conflict.type) {
      case 'todo':
        final todo = Todo.fromJson(conflict.remoteData);
        await _todoRepository.saveTodo(todo);
        break;
      case 'category':
        final category = Category.fromJson(conflict.remoteData);
        await _categoryRepository.saveCategory(category);
        break;
      case 'tag':
        final tag = Tag.fromJson(conflict.remoteData);
        await _tagRepository.saveTag(tag);
        break;
    }
  }
  
  /// Merge data for conflict resolution
  Future<void> _mergeData(SyncConflict conflict) async {
    // Simple merge strategy: use most recent modification time
    final useLocal = conflict.localModified.isAfter(conflict.remoteModified);
    
    if (useLocal) {
      await _applyLocalData(conflict);
    } else {
      await _applyRemoteData(conflict);
    }
  }
  
  /// Update sync metadata
  Future<void> _updateSyncMetadata() async {
    final metadata = await _driveService.downloadSyncMetadata() ?? {};
    
    metadata['lastSyncTime'] = DateTime.now().toIso8601String();
    metadata['totalSyncs'] = (metadata['totalSyncs'] ?? 0) + 1;
    
    await _driveService.uploadSyncMetadata(metadata);
  }
  
  /// Update sync status
  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }
  
  /// Helper methods for generic operations
  String _getId(dynamic item) {
    if (item is Todo) return item.id;
    if (item is Category) return item.id;
    if (item is Tag) return item.id;
    throw ArgumentError('Unknown item type');
  }
  
  DateTime _getModifiedTime(dynamic item) {
    if (item is Todo) return item.updatedAt;
    if (item is Category) return item.updatedAt;
    if (item is Tag) return item.updatedAt;
    throw ArgumentError('Unknown item type');
  }
  
  bool _areItemsEqual(dynamic item1, dynamic item2) {
    final json1 = _toJson(item1);
    final json2 = _toJson(item2);
    return jsonEncode(json1) == jsonEncode(json2);
  }
  
  Map<String, dynamic> _toJson(dynamic item) {
    if (item is Todo) return item.toJson();
    if (item is Category) return item.toJson();
    if (item is Tag) return item.toJson();
    throw ArgumentError('Unknown item type');
  }
  
  /// Dispose resources
  void dispose() {
    _autoSyncTimer?.cancel();
    _statusController.close();
    _progressController.close();
    _conflictsController.close();
  }
}