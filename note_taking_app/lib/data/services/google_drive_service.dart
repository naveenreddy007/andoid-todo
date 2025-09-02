import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;

import 'google_drive_auth_service.dart';
import '../../domain/entities/todo.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/tag.dart';

class GoogleDriveService {
  static const String _appFolderName = 'TodoApp_Data';
  static const String _todosFileName = 'todos.json';
  static const String _categoriesFileName = 'categories.json';
  static const String _tagsFileName = 'tags.json';
  static const String _syncMetadataFileName = 'sync_metadata.json';
  
  final GoogleDriveAuthService _authService;
  final Logger _logger = Logger();
  
  drive.DriveApi? _driveApi;
  String? _appFolderId;
  
  GoogleDriveService(this._authService);
  
  /// Initialize the Google Drive service
  Future<bool> initialize() async {
    try {
      if (!_authService.isAuthenticated) {
        _logger.w('Cannot initialize Google Drive service: not authenticated');
        return false;
      }
      
      final client = await _authService.getAuthenticatedClient();
      if (client == null) {
        _logger.e('Failed to get authenticated client');
        return false;
      }
      
      _driveApi = drive.DriveApi(client);
      await _ensureAppFolder();
      
      _logger.i('Google Drive service initialized successfully');
      return true;
    } catch (e) {
      _logger.e('Failed to initialize Google Drive service: $e');
      return false;
    }
  }
  
  /// Check if the service is ready for operations
  bool get isReady => _driveApi != null && _appFolderId != null;
  
  /// Upload todos to Google Drive
  Future<bool> uploadTodos(List<Todo> todos) async {
    return await _uploadJsonData(
      _todosFileName,
      todos.map((todo) => todo.toJson()).toList(),
    );
  }
  
  /// Download todos from Google Drive
  Future<List<Todo>?> downloadTodos() async {
    final data = await _downloadJsonData(_todosFileName);
    if (data == null) return null;
    
    try {
      final List<dynamic> todosList = data as List<dynamic>;
      return todosList.map((json) => Todo.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      _logger.e('Failed to parse todos from Google Drive: $e');
      return null;
    }
  }
  
  /// Upload categories to Google Drive
  Future<bool> uploadCategories(List<Category> categories) async {
    return await _uploadJsonData(
      _categoriesFileName,
      categories.map((category) => category.toJson()).toList(),
    );
  }
  
  /// Download categories from Google Drive
  Future<List<Category>?> downloadCategories() async {
    final data = await _downloadJsonData(_categoriesFileName);
    if (data == null) return null;
    
    try {
      final List<dynamic> categoriesList = data as List<dynamic>;
      return categoriesList.map((json) => Category.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      _logger.e('Failed to parse categories from Google Drive: $e');
      return null;
    }
  }
  
  /// Upload tags to Google Drive
  Future<bool> uploadTags(List<Tag> tags) async {
    return await _uploadJsonData(
      _tagsFileName,
      tags.map((tag) => tag.toJson()).toList(),
    );
  }
  
  /// Download tags from Google Drive
  Future<List<Tag>?> downloadTags() async {
    final data = await _downloadJsonData(_tagsFileName);
    if (data == null) return null;
    
    try {
      final List<dynamic> tagsList = data as List<dynamic>;
      return tagsList.map((json) => Tag.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      _logger.e('Failed to parse tags from Google Drive: $e');
      return null;
    }
  }
  
  /// Upload sync metadata to Google Drive
  Future<bool> uploadSyncMetadata(Map<String, dynamic> metadata) async {
    return await _uploadJsonData(_syncMetadataFileName, metadata);
  }
  
  /// Download sync metadata from Google Drive
  Future<Map<String, dynamic>?> downloadSyncMetadata() async {
    final data = await _downloadJsonData(_syncMetadataFileName);
    if (data == null) return null;
    
    try {
      return data as Map<String, dynamic>;
    } catch (e) {
      _logger.e('Failed to parse sync metadata from Google Drive: $e');
      return null;
    }
  }
  
  /// Get the last modified time of a file
  Future<DateTime?> getFileLastModified(String fileName) async {
    try {
      if (!isReady) {
        await initialize();
        if (!isReady) return null;
      }
      
      final fileId = await _getFileId(fileName);
      if (fileId == null) return null;
      
      final file = await _driveApi!.files.get(
        fileId,
        $fields: 'modifiedTime',
      ) as drive.File;
      
      return file.modifiedTime;
    } catch (e) {
      _logger.e('Failed to get file last modified time: $e');
      return null;
    }
  }
  
  /// Check if a file exists in Google Drive
  Future<bool> fileExists(String fileName) async {
    final fileId = await _getFileId(fileName);
    return fileId != null;
  }
  
  /// Delete a file from Google Drive
  Future<bool> deleteFile(String fileName) async {
    try {
      if (!isReady) {
        await initialize();
        if (!isReady) return false;
      }
      
      final fileId = await _getFileId(fileName);
      if (fileId == null) {
        _logger.w('File $fileName not found for deletion');
        return true; // File doesn't exist, consider it deleted
      }
      
      await _driveApi!.files.delete(fileId);
      _logger.i('Successfully deleted file: $fileName');
      return true;
    } catch (e) {
      _logger.e('Failed to delete file $fileName: $e');
      return false;
    }
  }
  
  /// Get storage usage information
  Future<Map<String, dynamic>?> getStorageInfo() async {
    try {
      if (!isReady) {
        await initialize();
        if (!isReady) return null;
      }
      
      final about = await _driveApi!.about.get($fields: 'storageQuota,user');
      
      return {
        'totalSpace': about.storageQuota?.limit,
        'usedSpace': about.storageQuota?.usage,
        'userEmail': about.user?.emailAddress,
      };
    } catch (e) {
      _logger.e('Failed to get storage info: $e');
      return null;
    }
  }
  
  /// Ensure the app folder exists in Google Drive
  Future<void> _ensureAppFolder() async {
    try {
      // Search for existing app folder
      final query = "name='$_appFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false";
      final fileList = await _driveApi!.files.list(
        q: query,
        spaces: 'drive',
      );
      
      if (fileList.files != null && fileList.files!.isNotEmpty) {
        _appFolderId = fileList.files!.first.id;
        _logger.i('Found existing app folder: $_appFolderId');
      } else {
        // Create new app folder
        final folder = drive.File()
          ..name = _appFolderName
          ..mimeType = 'application/vnd.google-apps.folder';
        
        final createdFolder = await _driveApi!.files.create(folder);
        _appFolderId = createdFolder.id;
        _logger.i('Created new app folder: $_appFolderId');
      }
    } catch (e) {
      _logger.e('Failed to ensure app folder: $e');
      throw e;
    }
  }
  
  /// Upload JSON data to Google Drive
  Future<bool> _uploadJsonData(String fileName, dynamic data) async {
    try {
      if (!isReady) {
        await initialize();
        if (!isReady) return false;
      }
      
      final jsonString = jsonEncode(data);
      final bytes = utf8.encode(jsonString);
      
      // Check if file already exists
      final existingFileId = await _getFileId(fileName);
      
      final media = drive.Media(
        Stream.fromIterable([bytes]),
        bytes.length,
        contentType: 'application/json',
      );
      
      if (existingFileId != null) {
        // Update existing file
        await _driveApi!.files.update(
          drive.File(),
          existingFileId,
          uploadMedia: media,
        );
        _logger.i('Updated existing file: $fileName');
      } else {
        // Create new file
        final file = drive.File()
          ..name = fileName
          ..parents = [_appFolderId!];
        
        await _driveApi!.files.create(
          file,
          uploadMedia: media,
        );
        _logger.i('Created new file: $fileName');
      }
      
      return true;
    } catch (e) {
      _logger.e('Failed to upload $fileName: $e');
      return false;
    }
  }
  
  /// Download JSON data from Google Drive
  Future<dynamic> _downloadJsonData(String fileName) async {
    try {
      if (!isReady) {
        await initialize();
        if (!isReady) return null;
      }
      
      final fileId = await _getFileId(fileName);
      if (fileId == null) {
        _logger.w('File $fileName not found in Google Drive');
        return null;
      }
      
      final media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;
      
      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }
      
      final jsonString = utf8.decode(bytes);
      final data = jsonDecode(jsonString);
      
      _logger.i('Successfully downloaded $fileName');
      return data;
    } catch (e) {
      _logger.e('Failed to download $fileName: $e');
      return null;
    }
  }
  
  /// Get file ID by name in the app folder
  Future<String?> _getFileId(String fileName) async {
    try {
      if (_appFolderId == null) {
        await _ensureAppFolder();
      }
      
      final query = "name='$fileName' and parents in '$_appFolderId' and trashed=false";
      final fileList = await _driveApi!.files.list(
        q: query,
        spaces: 'drive',
      );
      
      if (fileList.files != null && fileList.files!.isNotEmpty) {
        return fileList.files!.first.id;
      }
      
      return null;
    } catch (e) {
      _logger.e('Failed to get file ID for $fileName: $e');
      return null;
    }
  }
}