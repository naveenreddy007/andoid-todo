import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

class GoogleDriveAuthService {
  static const String _accessTokenKey = 'google_drive_access_token';
  static const String _refreshTokenKey = 'google_drive_refresh_token';
  static const String _tokenExpiryKey = 'google_drive_token_expiry';
  static const String _userEmailKey = 'google_drive_user_email';
  
  static const List<String> _scopes = [
    drive.DriveApi.driveFileScope,
    'https://www.googleapis.com/auth/userinfo.email',
  ];
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: _scopes,
  );
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  final Logger _logger = Logger();
  
  GoogleSignInAccount? _currentUser;
  AccessCredentials? _credentials;
  
  // Stream controller for authentication state changes
  final StreamController<bool> _authStateController = StreamController<bool>.broadcast();
  Stream<bool> get authStateStream => _authStateController.stream;
  
  GoogleDriveAuthService() {
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      _currentUser = account;
      _authStateController.add(account != null);
    });
  }
  
  /// Initialize the authentication service
  Future<void> initialize() async {
    try {
      // Try to restore previous session
      await _restoreSession();
      
      // Check if user is already signed in
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        _currentUser = account;
        await _refreshCredentials();
      }
    } catch (e) {
      _logger.e('Failed to initialize Google Drive auth: $e');
    }
  }
  
  /// Sign in with Google
  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return false; // User cancelled
      }
      
      _currentUser = account;
      await _refreshCredentials();
      await _saveSession();
      
      _logger.i('Successfully signed in to Google Drive: ${account.email}');
      return true;
    } catch (e) {
      _logger.e('Failed to sign in to Google Drive: $e');
      return false;
    }
  }
  
  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _clearSession();
      _currentUser = null;
      _credentials = null;
      
      _logger.i('Successfully signed out from Google Drive');
    } catch (e) {
      _logger.e('Failed to sign out from Google Drive: $e');
    }
  }
  
  /// Check if user is currently authenticated
  bool get isAuthenticated => _currentUser != null && _credentials != null;
  
  /// Get current user email
  String? get userEmail => _currentUser?.email;
  
  /// Get current access credentials
  AccessCredentials? get credentials => _credentials;
  
  /// Refresh access token if needed
  Future<bool> refreshTokenIfNeeded() async {
    if (_credentials == null) {
      return false;
    }
    
    // Check if token is expired or will expire in the next 5 minutes
    final now = DateTime.now();
    final expiryTime = _credentials!.accessToken.expiry;
    
    if (expiryTime.isBefore(now.add(const Duration(minutes: 5)))) {
      return await _refreshCredentials();
    }
    
    return true;
  }
  
  /// Get authenticated HTTP client for Google APIs
  Future<AuthClient?> getAuthenticatedClient() async {
    if (!isAuthenticated) {
      return null;
    }
    
    await refreshTokenIfNeeded();
    
    if (_credentials == null) {
      return null;
    }
    
    return authenticatedClient(
      HttpClient(),
      _credentials!,
    );
  }
  
  /// Refresh credentials using the current Google Sign-In account
  Future<bool> _refreshCredentials() async {
    try {
      if (_currentUser == null) {
        return false;
      }
      
      final authentication = await _currentUser!.authentication;
      
      _credentials = AccessCredentials(
        AccessToken(
          'Bearer',
          authentication.accessToken!,
          DateTime.now().add(const Duration(hours: 1)), // Google tokens typically expire in 1 hour
        ),
        authentication.idToken,
        _scopes,
      );
      
      await _saveSession();
      return true;
    } catch (e) {
      _logger.e('Failed to refresh credentials: $e');
      return false;
    }
  }
  
  /// Save authentication session to secure storage
  Future<void> _saveSession() async {
    try {
      if (_credentials != null && _currentUser != null) {
        await _secureStorage.write(
          key: _accessTokenKey,
          value: _credentials!.accessToken.data,
        );
        
        await _secureStorage.write(
          key: _tokenExpiryKey,
          value: _credentials!.accessToken.expiry.toIso8601String(),
        );
        
        await _secureStorage.write(
          key: _userEmailKey,
          value: _currentUser!.email,
        );
        
        if (_credentials!.refreshToken != null) {
          await _secureStorage.write(
            key: _refreshTokenKey,
            value: _credentials!.refreshToken!,
          );
        }
      }
    } catch (e) {
      _logger.e('Failed to save session: $e');
    }
  }
  
  /// Restore authentication session from secure storage
  Future<void> _restoreSession() async {
    try {
      final accessToken = await _secureStorage.read(key: _accessTokenKey);
      final expiryString = await _secureStorage.read(key: _tokenExpiryKey);
      final userEmail = await _secureStorage.read(key: _userEmailKey);
      
      if (accessToken != null && expiryString != null && userEmail != null) {
        final expiry = DateTime.parse(expiryString);
        final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
        
        _credentials = AccessCredentials(
          AccessToken('Bearer', accessToken, expiry),
          refreshToken,
          _scopes,
        );
        
        _logger.i('Restored Google Drive session for: $userEmail');
      }
    } catch (e) {
      _logger.e('Failed to restore session: $e');
    }
  }
  
  /// Clear authentication session from secure storage
  Future<void> _clearSession() async {
    try {
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _tokenExpiryKey);
      await _secureStorage.delete(key: _userEmailKey);
    } catch (e) {
      _logger.e('Failed to clear session: $e');
    }
  }
  
  /// Dispose resources
  void dispose() {
    _authStateController.close();
  }
}