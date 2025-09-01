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
  const DatabaseException(super.message, {super.code, super.details});
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.details});
}

/// Google Drive API related exceptions
class GoogleDriveException extends AppException {
  const GoogleDriveException(super.message, {super.code, super.details});
}

/// Authentication exceptions
class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.details});
}

/// Sync-related exceptions
class SyncException extends AppException {
  const SyncException(super.message, {super.code, super.details});
}

/// File operation exceptions
class FileException extends AppException {
  const FileException(super.message, {super.code, super.details});
}

/// Validation exceptions
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.details});
}

/// Permission exceptions
class PermissionException extends AppException {
  const PermissionException(super.message, {super.code, super.details});
}

/// Notification exceptions
class NotificationException extends AppException {
  const NotificationException(super.message, {super.code, super.details});
}

/// Cache exceptions
class CacheException extends AppException {
  const CacheException(super.message, {super.code, super.details});
}