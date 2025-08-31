/// Base class for all application-specific exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException(this.message, {this.code, this.details});

  @override
  String toString() {
    return 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

/// Database-related exceptions
class DatabaseException extends AppException {
  const DatabaseException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Google Drive API related exceptions
class GoogleDriveException extends AppException {
  const GoogleDriveException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Authentication exceptions
class AuthException extends AppException {
  const AuthException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Sync-related exceptions
class SyncException extends AppException {
  const SyncException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// File operation exceptions
class FileException extends AppException {
  const FileException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Validation exceptions
class ValidationException extends AppException {
  const ValidationException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Permission exceptions
class PermissionException extends AppException {
  const PermissionException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Notification exceptions
class NotificationException extends AppException {
  const NotificationException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Cache exceptions
class CacheException extends AppException {
  const CacheException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}