import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:async' show StreamSubscription;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async' show unawaited;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart' as auth_io;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/profile.dart';
import '../models/music_project.dart';
import '../models/release.dart';
import '../models/release_file.dart';
import '../models/scan_root.dart';
import '../models/todo_item.dart';
import '../models/todo_template.dart';
import '../models/backup_progress.dart';
import '../repository/profile_repository.dart';
import '../repository/project_repository.dart';
import '../utils/app_paths.dart' show ensureHiveInitialized, getPreviewSongsPath;
import '../config/secrets.dart' show desktopClientSecret, desktopClientId, androidWebClientId;

/// Service for synchronizing database data with Google Drive
class GoogleDriveSyncService {
  static const String _appDataFolderName = 'DAW Project Manager';
  static const String _databaseFileName = 'database_backup.json';
  static const String _metadataFileName = 'sync_metadata.json';
  static const String _credentialsBoxName = 'google_drive_credentials';
  static const String _backupTimestampBoxName = 'backup_timestamps';
  
  bool _isInitialized = false;
  bool _isAuthenticated = false; // has granted permissions?
  GoogleSignInAccount? _currentUser; // Current signed-in user
  drive.DriveApi? _driveApi;
  String? _appDataFolderId;
  auth_io.AutoRefreshingAuthClient? _desktopAuthClient; // For desktop OAuth
  Box<String>? _credentialsBox; // For storing desktop credentials
  Box<String>? _backupTimestampBox; // For storing last backup download timestamp
  StreamSubscription? _authEventsSubscription; // Listen to authentication events
  static bool _sessionInitialized = false; // Track if lightweight auth was attempted this session
  
  // Stream controller for backup progress
  final _progressController = StreamController<BackupProgress>.broadcast();
  Stream<BackupProgress> get progressStream => _progressController.stream;
  
  // Cancellation flag for backup uploads
  bool _isCancelled = false;
  
  // Cancel current upload operation
  void cancelUpload() {
    _isCancelled = true;
  }
  
  // Public getters for user state (following official example)
  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null && _isAuthenticated;
  
  // Public getters for desktop flow
  drive.DriveApi? get driveApi => _driveApi;
  set driveApi(drive.DriveApi? api) => _driveApi = api;
  auth_io.AutoRefreshingAuthClient? get desktopAuthClient => _desktopAuthClient;
  set desktopAuthClient(auth_io.AutoRefreshingAuthClient? client) => _desktopAuthClient = client;

  // Desktop Client ID - loaded from secrets.dart (injected during build or from local file)
  // The ID is obfuscated (base64) and decoded at runtime
  static String get _desktopClientId {
    try {
      // Decode obfuscated client ID (base64)
      final decoded = utf8.decode(base64Decode(desktopClientId));
      return decoded;
    } catch (e) {
      // If decoding fails, assume it's not obfuscated (for backward compatibility)
      if (kDebugMode) print('Warning: Could not decode desktop client ID, using as-is: $e');
      return desktopClientId;
    }
  }
  
  // Desktop Client Secret - loaded from secrets.dart (injected during build or from local file)
  // The secret is obfuscated (base64) and decoded at runtime
  static String get _desktopClientSecret {
    try {
      // Decode obfuscated secret (base64)
      final decoded = utf8.decode(base64Decode(desktopClientSecret));
      return decoded;
    } catch (e) {
      // If decoding fails, assume it's not obfuscated (for backward compatibility)
      if (kDebugMode) print('Warning: Could not decode secret, using as-is: $e');
      return desktopClientSecret;
    }
  }
  
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/drive.file',
    // Removed drive.appdata since we're using a shared folder in root Drive instead
    // 'https://www.googleapis.com/auth/drive.appdata',
  ];

  // Android Web Client ID - loaded from secrets.dart (injected during build or from local file)
  // Google automatically detects debug/release by package name, so only one Client ID is needed
  // The ID is obfuscated (base64) and decoded at runtime
  static String get _androidWebClientId {
    try {
      // Decode obfuscated client ID (base64)
      final decoded = utf8.decode(base64Decode(androidWebClientId));
      return decoded;
    } catch (e) {
      // If decoding fails, assume it's not obfuscated (for backward compatibility)
      if (kDebugMode) print('Warning: Could not decode android web client ID, using as-is: $e');
      return androidWebClientId;
    }
  }

  GoogleDriveSyncService({String? serverClientId}) {
    // In 7.x, GoogleSignIn is a singleton accessed via GoogleSignIn.instance
    // Configuration is done via initialize() method
    // For now, we'll store the serverClientId for use in initialize()
    if (Platform.isAndroid) {
      final webClientId = serverClientId ?? _androidWebClientId;
      if (kDebugMode) {
        print('=== GoogleSignIn Configuration (7.x) ===');
        print('Platform: Android');
        print('Build Mode: ${kDebugMode ? "Debug" : "Release"}');
        print('Server Client ID (Web): $webClientId');
        print('Scopes: $_scopes');
        print('Package name should be: com.bandpassrecords.dpm');
        print('SHA-1 (Debug) should be: 54:AD:3C:3C:49:AE:7B:AF:A1:5D:46:D3:01:F3:6A:4E:0E:34:D4:69');
        print('SHA-1 (Release) should be: 43:79:D2:9B:12:D6:19:91:0B:10:BE:A5:72:17:A2:29:5A:11:72:F7');
        print('Note: Call initialize() before using the service');
        print('===================================');
      }
    }
    // Para Desktop: não usa google_sign_in (não tem implementação)
    // Usaremos googleapis_auth diretamente
  }

  /// Initialize GoogleSignIn (following official example pattern)
  /// In 7.x, this is required before any other methods
  /// Only attempts lightweight auth once per app session
  Future<void> initialize({String? serverClientId, bool forceReinitialize = false}) async {
    if (_isInitialized && !forceReinitialize) {
      if (kDebugMode) print('GoogleSignIn already initialized');
      return;
    }

    if (Platform.isAndroid) {
      try {
        final webClientId = serverClientId ?? _androidWebClientId;
        
        if (kDebugMode) {
          print('Initializing GoogleSignIn (following official example)...');
          print('Server Client ID (Web): $webClientId');
        }

        // Initialize following official example pattern
        final GoogleSignIn signIn = GoogleSignIn.instance;
        unawaited(
          signIn.initialize(
            clientId: null, // Not needed for Android
            serverClientId: webClientId,
          ).then((_) {
            // Listen to authentication events (following official example)
            // Only set up listener once
            if (_authEventsSubscription == null) {
              _authEventsSubscription = signIn.authenticationEvents
                  .listen(_handleAuthenticationEvent);
              _authEventsSubscription?.onError(_handleAuthenticationError);
            }

            // Attempt lightweight authentication only once per session
            // This happens automatically on app start, not every time the page is opened
            if (!_sessionInitialized) {
              if (kDebugMode) print('Attempting lightweight authentication (first time this session)...');
              signIn.attemptLightweightAuthentication();
              _sessionInitialized = true;
            } else {
              if (kDebugMode) print('Lightweight auth already attempted this session, skipping...');
            }
          }),
        );

        _isInitialized = true;
        if (kDebugMode) print('GoogleSignIn initialized successfully');
      } catch (e) {
        if (kDebugMode) print('Error initializing GoogleSignIn: $e');
        rethrow;
      }
    } else {
      _isInitialized = true; // Desktop doesn't need GoogleSignIn
    }
  }

  /// Handle authentication events (following official example pattern)
  Future<void> _handleAuthenticationEvent(GoogleSignInAuthenticationEvent event) async {
    // Determine user from event (following official example)
    final GoogleSignInAccount? user = switch (event) {
      GoogleSignInAuthenticationEventSignIn() => event.user,
      GoogleSignInAuthenticationEventSignOut() => null,
    };

    // Check for existing authorization (following official example)
    final GoogleSignInClientAuthorization? authorization = await user
        ?.authorizationClient
        .authorizationForScopes(_scopes);

    _currentUser = user;
    _isAuthenticated = authorization != null;

    if (kDebugMode) {
      if (user != null) {
        print('Authentication event: User signed in - ${user.email}');
        print('  Authorization granted: $_isAuthenticated');
      } else {
        print('Authentication event: User signed out');
      }
    }

    // If user is signed in and authorized, initialize Drive API
    if (user != null && authorization != null) {
      await _initializeDriveApi(user);
    } else {
      _driveApi = null;
    }
  }

  /// Handle authentication errors (following official example pattern)
  Future<void> _handleAuthenticationError(Object e) async {
    if (kDebugMode) {
      if (e is GoogleSignInException) {
        print('Authentication error: ${e.code}: ${e.description}');
      } else {
        print('Authentication error: $e');
      }
    }
    _currentUser = null;
    _isAuthenticated = false;
    _driveApi = null;
  }

  /// Initialize Drive API with user's authorization
  Future<void> _initializeDriveApi(GoogleSignInAccount user) async {
    try {
      // Get authorization headers (following official example pattern)
      final Map<String, String>? headers = await user.authorizationClient
          .authorizationHeaders(_scopes);
      
      if (headers == null) {
        if (kDebugMode) print('Failed to get authorization headers');
        _driveApi = null;
        return;
      }

      // Create authenticated HTTP client
      final baseClient = http.Client();
      final authenticatedClient = _AuthenticatedHttpClient(baseClient, headers);
      _driveApi = drive.DriveApi(authenticatedClient);
      
      // Ensure app data folder exists
      await ensureAppDataFolder();
      
      if (kDebugMode) print('✓ Drive API initialized successfully');
    } catch (e) {
      if (kDebugMode) print('Error initializing Drive API: $e');
      _driveApi = null;
    }
  }

  /// Dispose resources
  void dispose() {
    _authEventsSubscription?.cancel();
    _authEventsSubscription = null;
    _progressController.close();
  }

  /// Initialize credentials storage (call this before using the service)
  /// Uses encrypted storage for desktop platforms
  Future<void> initializeCredentialsStorage() async {
    if (Platform.isAndroid) return;

    try {
      const secureStorage = FlutterSecureStorage();
      
      // 1. Check if we already have an encryption key
      String? encryptionKey = await secureStorage.read(key: 'hive_encryption_key');
      
      if (encryptionKey == null) {
        // 2. Generate a new key if it doesn't exist
        final key = Hive.generateSecureKey();
        await secureStorage.write(
          key: 'hive_encryption_key', 
          value: base64UrlEncode(key)
        );
        encryptionKey = base64UrlEncode(key);
      }

      final decodedKey = base64Url.decode(encryptionKey);

      // Ensure Hive is initialized (only once)
      await ensureHiveInitialized();

      // 3. Open the box with the encryption cipher
      if (!Hive.isBoxOpen(_credentialsBoxName)) {
        _credentialsBox = await Hive.openBox<String>(
          _credentialsBoxName,
          encryptionCipher: HiveAesCipher(decodedKey),
        );
        if (kDebugMode) print('Encrypted credentials storage initialized');
      } else {
        _credentialsBox = Hive.box<String>(_credentialsBoxName);
        if (kDebugMode) print('Encrypted credentials storage already open');
      }
    } catch (e) {
      if (kDebugMode) print('Error initializing encrypted storage: $e');
    }
  }

  /// Initialize backup timestamp storage (local, unencrypted)
  Future<void> _initializeBackupTimestampStorage() async {
    try {
      await ensureHiveInitialized();
      if (!Hive.isBoxOpen(_backupTimestampBoxName)) {
        _backupTimestampBox = await Hive.openBox<String>(_backupTimestampBoxName);
      } else {
        _backupTimestampBox = Hive.box<String>(_backupTimestampBoxName);
      }
    } catch (e) {
      if (kDebugMode) print('Error initializing backup timestamp storage: $e');
    }
  }

  /// Save last backup download timestamp
  Future<void> saveLastBackupDownloadTimestamp(DateTime timestamp) async {
    try {
      await _initializeBackupTimestampStorage();
      if (_backupTimestampBox != null) {
        await _backupTimestampBox!.put('lastDownload', timestamp.toIso8601String());
        if (kDebugMode) print('Saved last backup download timestamp: ${timestamp.toIso8601String()}');
      }
    } catch (e) {
      if (kDebugMode) print('Error saving last backup download timestamp: $e');
    }
  }

  /// Get last backup download timestamp
  Future<DateTime?> getLastBackupDownloadTimestamp() async {
    try {
      await _initializeBackupTimestampStorage();
      if (_backupTimestampBox != null) {
        final timestampString = _backupTimestampBox!.get('lastDownload');
        if (timestampString != null) {
          return DateTime.parse(timestampString);
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error getting last backup download timestamp: $e');
      return null;
    }
  }

  /// Get remote backup timestamp from Drive
  Future<DateTime?> getRemoteBackupTimestamp() async {
    try {
      if (_driveApi == null || _appDataFolderId == null) {
        return null;
      }

      final response = await _driveApi!.files.list(
        q: "name='$_databaseFileName' and parents in '$_appDataFolderId' and trashed=false",
        spaces: 'drive',
      );

      if (response.files == null || response.files!.isEmpty) {
        return null; // No backup file found
      }

      // Get file metadata to check modified time
      // Use modifiedTime from the file in the list response (already available)
      final fileInList = response.files!.first;
      if (fileInList.modifiedTime != null) {
        // modifiedTime is already a DateTime, not a String
        return fileInList.modifiedTime;
      }

      // If modifiedTime not in list response, try to get it explicitly
      try {
        final fileId = fileInList.id!;
        final fileResult = await _driveApi!.files.get(fileId, $fields: 'modifiedTime');
        if (fileResult is drive.File && fileResult.modifiedTime != null) {
          // modifiedTime is already a DateTime, not a String
          return fileResult.modifiedTime;
        }
      } catch (_) {
        // If getting file fails, continue to fallback
      }

      // Fallback: try to download and parse the backup JSON to get timestamp
      try {
        final backupData = await downloadDatabase();
        if (backupData['timestamp'] != null) {
          return DateTime.parse(backupData['timestamp'] as String);
        }
      } catch (_) {
        // If download fails, return null
      }

      return null;
    } catch (e) {
      if (kDebugMode) print('Error getting remote backup timestamp: $e');
      return null;
    }
  }

  /// Check if a newer backup is available on Drive
  /// Returns true if remote backup is newer than last downloaded backup
  Future<bool> isNewerBackupAvailable() async {
    try {
      final lastDownload = await getLastBackupDownloadTimestamp();
      final remoteTimestamp = await getRemoteBackupTimestamp();

      if (remoteTimestamp == null) {
        return false; // No backup available on Drive
      }

      if (lastDownload == null) {
        return true; // Never downloaded, so remote is "newer"
      }

      return remoteTimestamp.isAfter(lastDownload);
    } catch (e) {
      if (kDebugMode) print('Error checking if newer backup is available: $e');
      return false;
    }
  }

  /// Check if user is signed in (async check) - following official example
  /// Use the getter `isSignedIn` for synchronous check
  Future<bool> checkSignedInStatus() async {
    try {
      if (Platform.isAndroid) {
        if (!_isInitialized) {
          await initialize();
        }
        
        // Check if we have a current user and authorization (following official example)
        if (_currentUser != null) {
          try {
            final GoogleSignInClientAuthorization? authorization = await _currentUser!
                .authorizationClient
                .authorizationForScopes(_scopes);
            _isAuthenticated = authorization != null;
            return _isAuthenticated;
          } catch (e) {
            if (kDebugMode) print('Error checking authorization: $e');
            _isAuthenticated = false;
            return false;
          }
        } else {
          _isAuthenticated = false;
          return false;
        }
      } else {
        // Desktop: check if we have a valid auth client
        return _desktopAuthClient != null && _driveApi != null;
      }
    } catch (e) {
      if (kDebugMode) print('Error checking sign in status: $e');
      _isAuthenticated = false;
      _currentUser = null;
      return false;
    }
  }

  /// Sign in to Google (following official example pattern)
  /// This method triggers interactive authentication if needed
  /// Following official example: authenticate() is called explicitly
  Future<bool> signIn() async {
    try {
      if (kDebugMode) {
        print('=== Google Sign-In Attempt (following official example) ===');
        print('Platform: ${Platform.operatingSystem}');
      }
      
      if (Platform.isAndroid) {
        // Ensure GoogleSignIn is initialized
        if (!_isInitialized) {
          await initialize();
        }

        // Following official example: authenticate() is called explicitly
        // The authenticationEvents stream will handle the result
        if (GoogleSignIn.instance.supportsAuthenticate()) {
          if (kDebugMode) print('Attempting interactive authentication...');
          try {
            // Authenticate interactively (following official example)
            await GoogleSignIn.instance.authenticate();
            
            // Wait a bit for authenticationEvents to process
            await Future.delayed(const Duration(milliseconds: 500));
            
            // Check if we have a user and authorization
            if (_currentUser != null) {
              // Check for existing authorization (following official example)
              final GoogleSignInClientAuthorization? authorization = await _currentUser!
                  .authorizationClient
                  .authorizationForScopes(_scopes);
              
              if (authorization != null) {
                // Already authorized, initialize Drive API
                await _initializeDriveApi(_currentUser!);
                await ensureAppDataFolder();
                if (kDebugMode) {
                  print('✓ Sign-in complete with existing authorization');
                }
                return true;
              } else {
                // Need to authorize scopes (following official example)
                if (kDebugMode) print('Requesting scope authorization...');
                try {
                  final GoogleSignInClientAuthorization authorization = await _currentUser!
                      .authorizationClient
                      .authorizeScopes(_scopes);
                  
                  // Initialize Drive API with authorization
                  await _initializeDriveApi(_currentUser!);
                  await ensureAppDataFolder();
                  
                  if (kDebugMode) {
                    print('✓ Sign-in complete with new authorization');
                  }
                  return true;
                } on GoogleSignInException catch (e) {
                  if (e.code == GoogleSignInExceptionCode.canceled) {
                    if (kDebugMode) print('User canceled authorization');
                    return false;
                  }
                  if (kDebugMode) {
                    print('✗ ERROR authorizing scopes: ${e.code}: ${e.description}');
                  }
                  rethrow;
                }
              }
            } else {
              if (kDebugMode) print('User cancelled the Google sign-in flow');
              return false;
            }
          } on GoogleSignInException catch (e) {
            if (e.code == GoogleSignInExceptionCode.canceled) {
              if (kDebugMode) print('User canceled authentication');
              return false;
            }
            // Check for developer console setup errors
            if (e.description?.contains('28444') == true || 
                e.description?.contains('Developer console is not set up correctly') == true) {
              if (kDebugMode) {
                print('✗ DEVELOPER CONSOLE CONFIGURATION ERROR:');
                print('  Error code: 28444');
                print('  This means the Android Client ID is not properly configured in Google Cloud Console');
                print('  Verify:');
                print('    1. Android Client ID exists in Google Cloud Console');
                print('    2. Package name: com.bandpassrecords.dpm (exactly)');
                print('    3. SHA-1: 54:AD:3C:3C:49:AE:7B:AF:A1:5D:46:D3:01:F3:6A:4E:0E:34:D4:69 (exactly)');
                print('    4. OAuth Consent Screen - Test users: Email added');
                print('    5. Wait 15-30 minutes after changes');
              }
            }
            if (kDebugMode) {
              print('✗ ERROR during authenticate():');
              print('  Error code: ${e.code}');
              print('  Error: ${e.description}');
            }
            rethrow;
          } catch (e) {
            if (kDebugMode) {
              print('✗ ERROR during authenticate():');
              print('  Error type: ${e.runtimeType}');
              print('  Error: $e');
            }
            rethrow;
          }
        } else {
          if (kDebugMode) print('Platform does not support authenticate()');
          return false;
        }
      } else {
        // Desktop: OAuth2 flow requires manual code entry
        if (kDebugMode) {
          print('Desktop platform detected.');
          print('Desktop sign-in requires manual code entry. Use getDesktopAuthorizationUrl() and _signInDesktopWithCode() instead.');
        }
        return false;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('✗ ERROR during sign-in:');
        print('  Error type: ${e.runtimeType}');
        print('  Error message: $e');
        print('  Stack trace:');
        print(stackTrace);
      }
      _currentUser = null;
      _isAuthenticated = false;
      rethrow;
    }
  }

  /// Sign in on desktop using OAuth2 flow (manual code entry)
  /// Opens browser and returns the authorization URL
  /// Following the pattern recommended for desktop apps using googleapis_auth
  Future<Uri> getDesktopAuthorizationUrl() async {
    // Use 'urn:ietf:wg:oauth:2.0:oob' for desktop apps - Google will show the code on the page
    final redirectUri = Uri.parse('urn:ietf:wg:oauth:2.0:oob');
    
    // Build authorization URL following OAuth 2.0 spec
    final authUrl = Uri.parse('https://accounts.google.com/o/oauth2/v2/auth').replace(
      queryParameters: {
        'client_id': _desktopClientId,
        'redirect_uri': redirectUri.toString(),
        'response_type': 'code',
        'scope': _scopes.join(' '),
        'access_type': 'offline', // Request refresh token
        'prompt': 'consent', // Force consent screen to ensure refresh token
      },
    );
    
    if (kDebugMode) {
      print('Desktop OAuth2 Authorization URL generated');
      print('Redirect URI: $redirectUri');
      print('Scopes: $_scopes');
    }
    
    return authUrl;
  }

  /// Complete desktop sign-in with authorization code
  /// Uses googleapis_auth to create an authenticated client following best practices
  /// This follows the pattern recommended for desktop apps using googleapis and googleapis_auth
  Future<auth_io.AutoRefreshingAuthClient?> signInDesktopWithCode(String code) async {
    try {
      final redirectUri = Uri.parse('urn:ietf:wg:oauth:2.0:oob');
      final clientId = auth_io.ClientId(
        _desktopClientId, 
        _desktopClientSecret.isEmpty ? null : _desktopClientSecret,
      );
      
      if (kDebugMode) {
        print('Exchanging authorization code for access token...');
        print('Using googleapis_auth to create authenticated client');
        print('Code: ${code.substring(0, 20)}...');
      }
      
      // Exchange authorization code for access token
      // Following OAuth 2.0 specification for desktop apps
      final tokenEndpoint = Uri.parse('https://oauth2.googleapis.com/token');
      final bodyParams = <String, String>{
        'code': code.trim(),
        'client_id': _desktopClientId,
        'redirect_uri': redirectUri.toString(),
        'grant_type': 'authorization_code',
      };
      if (_desktopClientSecret.isNotEmpty) {
        bodyParams['client_secret'] = _desktopClientSecret;
      }
      
      final tokenResponse = await http.post(
        tokenEndpoint,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: bodyParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&'),
      );
      
      if (tokenResponse.statusCode != 200) {
        if (kDebugMode) {
          print('Token exchange failed: ${tokenResponse.statusCode}');
          print('Response: ${tokenResponse.body}');
        }
        throw Exception('Token exchange failed: ${tokenResponse.statusCode} - ${tokenResponse.body}');
      }
      
      final tokenData = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
      final accessTokenString = tokenData['access_token'] as String;
      final refreshToken = tokenData['refresh_token'] as String?;
      final expiresIn = tokenData['expires_in'] as int? ?? 3600;
      
      if (kDebugMode) {
        print('Access token obtained successfully');
        print('Has refresh token: ${refreshToken != null}');
        print('Token expires in: $expiresIn seconds');
      }
      
      // Create AccessToken object using googleapis_auth
      // AccessCredentials requires an AccessToken object, not a string
      // IMPORTANT: Use expires_in directly without manual buffer calculation
      // The autoRefreshingClient will manage token refresh timing internally,
      // which is safer than manually calculating expiry time (avoids clock sync issues)
      final expiryTime = DateTime.now().toUtc().add(Duration(seconds: expiresIn));
      
      final accessToken = auth_io.AccessToken(
        'Bearer',
        accessTokenString,
        expiryTime,
      );
      
      // Create AccessCredentials using googleapis_auth
      // This follows the recommended pattern for using googleapis_auth
      final credentials = auth_io.AccessCredentials(
        accessToken,
        refreshToken,
        _scopes,
      );
      
      // Create auto-refreshing client using googleapis_auth
      // This client will automatically refresh the token when needed
      // This is the recommended way to use googleapis_auth with googleapis
      final baseClient = http.Client();
      final authClient = auth_io.autoRefreshingClient(
        clientId,
        credentials,
        baseClient,
      );
      
      // Save credentials for session persistence
      if (refreshToken != null) {
        await _saveCredentials(refreshToken, accessTokenString, expiryTime);
      }
      
      if (kDebugMode) print('Authenticated client created successfully using googleapis_auth');
      return authClient;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in desktop sign-in: $e');
        print('Stack: $stackTrace');
      }
      return null;
    }
  }

  /// Sign out from Google (following official example pattern)
  /// Disconnect instead of just signing out, to reset the state as much as possible
  Future<void> signOut() async {
    try {
      if (Platform.isAndroid) {
        if (!_isInitialized) {
          await initialize();
        }
        // Disconnect (following official example - resets state more completely)
        await GoogleSignIn.instance.disconnect();
        // State will be cleared by authenticationEvents listener
        // Reset session flag so lightweight auth can be attempted again on next login
        _sessionInitialized = false;
      } else {
        // Desktop: close auth client and clear saved credentials
        _desktopAuthClient?.close();
        _desktopAuthClient = null;
        await _clearCredentials();
        _currentUser = null;
        _isAuthenticated = false;
      }
      _driveApi = null;
      _appDataFolderId = null;
      
      if (kDebugMode) print('✓ Signed out successfully');
    } catch (e) {
      if (kDebugMode) print('Error signing out: $e');
      // Clear user state even if there was an error
      _currentUser = null;
      _isAuthenticated = false;
      _driveApi = null;
    }
  }

  /// Save desktop credentials for session persistence
  Future<void> _saveCredentials(String refreshToken, String accessToken, DateTime expiryTime) async {
    if (Platform.isAndroid || _credentialsBox == null) return;
    
    try {
      final credentialsData = {
        'refresh_token': refreshToken,
        'access_token': accessToken,
        'expiry_time': expiryTime.toIso8601String(),
      };
      
      await _credentialsBox!.put('credentials', jsonEncode(credentialsData));
      if (kDebugMode) print('Credentials saved for session persistence');
    } catch (e) {
      if (kDebugMode) print('Error saving credentials: $e');
    }
  }

  /// Clear saved credentials
  Future<void> _clearCredentials() async {
    if (Platform.isAndroid || _credentialsBox == null) return;
    
    try {
      await _credentialsBox!.delete('credentials');
      if (kDebugMode) print('Credentials cleared');
    } catch (e) {
      if (kDebugMode) print('Error clearing credentials: $e');
    }
  }

  /// Restore session from saved credentials (Desktop only)
  /// Android: authenticationEvents stream handles session restoration automatically
  Future<bool> restoreSession() async {
    if (Platform.isAndroid) {
      // Android: attemptLightweightAuthentication is called in initialize()
      // The authenticationEvents stream will handle the result
      // Just check if we're already signed in
      if (!_isInitialized) {
        await initialize();
      }
      // Wait a bit for authenticationEvents to process
      await Future.delayed(const Duration(milliseconds: 500));
      return _currentUser != null && _isAuthenticated;
    }

    // Desktop: restore from saved credentials
    if (_credentialsBox == null) {
      await initializeCredentialsStorage();
    }

    if (_credentialsBox == null) {
      if (kDebugMode) print('Credentials box not available');
      return false;
    }

    try {
      final credentialsJson = _credentialsBox!.get('credentials');
      if (credentialsJson == null) {
        if (kDebugMode) print('No saved credentials found');
        return false;
      }

      final credentialsData = jsonDecode(credentialsJson) as Map<String, dynamic>;
      final refreshToken = credentialsData['refresh_token'] as String?;
      final savedAccessToken = credentialsData['access_token'] as String?;
      final expiryTimeStr = credentialsData['expiry_time'] as String?;

      if (refreshToken == null) {
        if (kDebugMode) print('No refresh token in saved credentials');
        return false;
      }

      // Check if access token is still valid
      DateTime? expiryTime;
      if (expiryTimeStr != null) {
        expiryTime = DateTime.parse(expiryTimeStr);
        // If token expired, we'll use refresh token to get a new one
        if (expiryTime.isBefore(DateTime.now().toUtc())) {
          if (kDebugMode) print('Saved access token expired, will refresh');
        }
      }

      // Create client ID
      final clientId = auth_io.ClientId(_desktopClientId, _desktopClientSecret.isEmpty ? null : _desktopClientSecret);

      // Create credentials object
      auth_io.AccessCredentials credentials;
      
      if (savedAccessToken != null && expiryTime != null && expiryTime.isAfter(DateTime.now().toUtc())) {
        // Use saved access token if still valid
        final accessToken = auth_io.AccessToken(
          'Bearer',
          savedAccessToken,
          expiryTime,
        );
        credentials = auth_io.AccessCredentials(
          accessToken,
          refreshToken,
          _scopes,
        );
        if (kDebugMode) print('Using saved access token (still valid)');
      } else {
        // Access token expired or missing, create a placeholder - autoRefreshingClient will refresh it
        // We need to get a new access token using the refresh token
        final newAccessToken = await _refreshAccessToken(refreshToken);
        if (newAccessToken == null) {
          if (kDebugMode) print('Failed to refresh access token');
          return false;
        }
        
        credentials = auth_io.AccessCredentials(
          newAccessToken.accessToken,
          refreshToken,
          _scopes,
        );
        if (kDebugMode) print('Refreshed access token successfully');
      }

      // Create auto-refreshing client
      final baseClient = http.Client();
      final authClient = auth_io.autoRefreshingClient(
        clientId,
        credentials,
        baseClient,
      );

      _desktopAuthClient = authClient;
      _driveApi = drive.DriveApi(authClient);
      
      // Ensure app data folder exists (with timeout to avoid blocking)
      try {
        await ensureAppDataFolder().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            if (kDebugMode) print('ensureAppDataFolder timed out, continuing anyway');
          },
        );
      } catch (e) {
        if (kDebugMode) print('Error ensuring app data folder during restore: $e');
        // Continue anyway - folder will be created on next sync
      }
      
      if (kDebugMode) print('Desktop session restored successfully');
      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error restoring session: $e');
        print('Stack: $stackTrace');
      }
      // Clear invalid credentials
      await _clearCredentials();
      return false;
    }
  }

  /// Refresh access token using refresh token
  Future<auth_io.AccessCredentials?> _refreshAccessToken(String refreshToken) async {
    try {
      final clientId = auth_io.ClientId(_desktopClientId, _desktopClientSecret.isEmpty ? null : _desktopClientSecret);
      final tokenEndpoint = Uri.parse('https://oauth2.googleapis.com/token');
      
      final bodyParams = <String, String>{
        'refresh_token': refreshToken,
        'client_id': _desktopClientId,
        'grant_type': 'refresh_token',
      };
      if (_desktopClientSecret.isNotEmpty) {
        bodyParams['client_secret'] = _desktopClientSecret;
      }

      final tokenResponse = await http.post(
        tokenEndpoint,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: bodyParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Token refresh request timed out');
        },
      );

      if (tokenResponse.statusCode != 200) {
        if (kDebugMode) {
          print('Token refresh failed: ${tokenResponse.statusCode}');
          print('Response: ${tokenResponse.body}');
        }
        return null;
      }

      final tokenData = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
      final accessTokenString = tokenData['access_token'] as String;
      final expiresIn = tokenData['expires_in'] as int? ?? 3600;
      // Use expires_in directly - autoRefreshingClient manages refresh timing internally
      final expiryTime = DateTime.now().toUtc().add(Duration(seconds: expiresIn));

      final accessToken = auth_io.AccessToken(
        'Bearer',
        accessTokenString,
        expiryTime,
      );

      // Save updated credentials
      await _saveCredentials(refreshToken, accessTokenString, expiryTime);

      return auth_io.AccessCredentials(
        accessToken,
        refreshToken,
        _scopes,
      );
    } catch (e) {
      if (kDebugMode) print('Error refreshing access token: $e');
      return null;
    }
  }

  /// Get current user email
  /// Uses cached user info if available, otherwise queries Drive API
  Future<String?> getCurrentUserEmail() async {
    try {
      if (Platform.isAndroid) {
        // First try to use cached user info from _currentUser
        if (_currentUser != null) {
          return _currentUser!.email;
        }
        
        // If no cached user, try to get from Drive API
        if (_driveApi == null) {
          // Try to restore session
          final restored = await restoreSession();
          if (!restored) {
            return null;
          }
        }
        
        if (_driveApi != null) {
          final about = await _driveApi!.about.get($fields: 'user');
          return about.user?.emailAddress;
        }
        return null;
      } else {
        // Desktop: get user info from Drive API
        if (_driveApi == null) return null;
        final about = await _driveApi!.about.get($fields: 'user');
        return about.user?.emailAddress;
      }
    } catch (e) {
      if (kDebugMode) print('Error getting user email: $e');
      return null;
    }
  }

  /// Ensure app data folder exists in Google Drive
  Future<void> ensureAppDataFolder() async {
    if (_driveApi == null) {
      throw Exception('Not signed in to Google Drive');
    }

    try {
      if (kDebugMode) {
        print('=== Ensuring Shared Folder ===');
        print('Platform: ${Platform.operatingSystem}');
        print('Folder name: $_appDataFolderName');
        print('Location: Root of Google Drive (shared folder)');
      }
      
      // Search for folder in root of Google Drive (not appDataFolder)
      // Look for folder with the app name - first try in root, then anywhere
      var response = await _driveApi!.files.list(
        q: "name='$_appDataFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false and 'root' in parents",
        spaces: 'drive',
      );

      // If not found in root, search anywhere (in case it was moved)
      if (response.files == null || response.files!.isEmpty) {
        if (kDebugMode) {
          print('Folder not found in root, searching anywhere in Drive...');
        }
        response = await _driveApi!.files.list(
          q: "name='$_appDataFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false",
          spaces: 'drive',
        );
      }
      
      // If still not found, try a broader search to see what folders exist
      if (response.files == null || response.files!.isEmpty) {
        if (kDebugMode) {
          print('Folder not found with exact name, listing all folders to debug...');
          try {
            final allFolders = await _driveApi!.files.list(
              q: "mimeType='application/vnd.google-apps.folder' and trashed=false",
              spaces: 'drive',
              pageSize: 50,
            );
            if (allFolders.files != null && allFolders.files!.isNotEmpty) {
              print('All folders found in Drive (showing first 50):');
              for (final folder in allFolders.files!) {
                print('  - ${folder.name} (ID: ${folder.id})');
                if (folder.name?.toLowerCase().contains('daw') == true || 
                    folder.name?.toLowerCase().contains('project') == true ||
                    folder.name?.toLowerCase().contains('manager') == true) {
                  print('    ⚠️ This might be the folder we\'re looking for!');
                }
              }
            }
          } catch (e) {
            print('Error listing folders: $e');
          }
        }
      }

      if (response.files != null && response.files!.isNotEmpty) {
        _appDataFolderId = response.files!.first.id;
        if (kDebugMode) {
          print('Found existing shared folder: $_appDataFolderId');
          print('This folder is accessible from both desktop and mobile');
        }
        return;
      }

      // Create folder in root of Google Drive if it doesn't exist
      if (kDebugMode) {
        print('Creating new shared folder in root: $_appDataFolderName');
      }
      final folder = drive.File();
      folder.name = _appDataFolderName;
      folder.mimeType = 'application/vnd.google-apps.folder';
      // No parents means root of Drive - this creates a shared folder visible to all Client IDs

      final createdFolder = await _driveApi!.files.create(folder);
      _appDataFolderId = createdFolder.id;
      if (kDebugMode) {
        print('Created shared folder with ID: $_appDataFolderId');
        print('This folder is now accessible from both desktop and mobile');
        print('You can see it in your Google Drive at: https://drive.google.com');
      }
    } catch (e) {
      if (kDebugMode) print('Error ensuring app data folder: $e');
      rethrow;
    }
  }

  /// Ensure preview songs folder exists in Google Drive
  Future<String> _ensurePreviewSongsFolder() async {
    if (_driveApi == null || _appDataFolderId == null) {
      throw Exception('Not signed in to Google Drive');
    }

    const folderName = 'preview_songs';
    
    // Search for folder in app data folder
    var response = await _driveApi!.files.list(
      q: "name='$folderName' and mimeType='application/vnd.google-apps.folder' and parents in '$_appDataFolderId' and trashed=false",
      spaces: 'drive',
    );

    if (response.files != null && response.files!.isNotEmpty) {
      return response.files!.first.id!;
    }

    // Create folder if it doesn't exist
    final folder = drive.File();
    folder.name = folderName;
    folder.mimeType = 'application/vnd.google-apps.folder';
    folder.parents = [_appDataFolderId!];

    final createdFolder = await _driveApi!.files.create(folder);
    if (kDebugMode) print('Created preview_songs folder: ${createdFolder.id}');
    return createdFolder.id!;
  }

  /// Upload a preview song file to Google Drive
  /// Returns the file ID in Google Drive, the file hash, and the original filename
  /// Only uploads if the file hash has changed
  Future<Map<String, String>?> _uploadPreviewSongFile({
    required String projectId,
    required String localFilePath,
    String? existingHash, // Hash from previous backup (if available)
  }) async {
    if (_driveApi == null) {
      throw Exception('Not signed in to Google Drive');
    }

    final file = File(localFilePath);
    if (!await file.exists()) {
      if (kDebugMode) print('Preview song file not found: $localFilePath');
      return null;
    }

    try {
      // Calculate current file hash
      final currentHash = await _calculateFileHash(localFilePath);
      
      // If hash exists and matches, skip upload
      if (existingHash != null && existingHash == currentHash) {
        if (kDebugMode) {
          print('Preview song unchanged for project $projectId (hash: $currentHash), skipping upload');
        }
        // Still return the file ID if it exists in Drive
        final previewSongsFolderId = await _ensurePreviewSongsFolder();
        final fileName = path.basename(localFilePath);
        final fileExtension = path.extension(fileName);
        final driveFileName = '${projectId}_preview$fileExtension';
        
        var response = await _driveApi!.files.list(
          q: "name='$driveFileName' and parents in '$previewSongsFolderId' and trashed=false",
          spaces: 'drive',
        );
        
        if (response.files != null && response.files!.isNotEmpty) {
          return {
            'fileId': response.files!.first.id!,
            'hash': currentHash,
            'fileName': fileName, // Original filename
          };
        }
        // If file doesn't exist in Drive but hash matches, something is wrong
        // Fall through to upload
      }
      
      // Hash changed or file doesn't exist - upload
      if (kDebugMode) {
        if (existingHash != null) {
          print('Preview song changed for project $projectId (old: $existingHash, new: $currentHash), uploading...');
        } else {
          print('Uploading new preview song for project $projectId (hash: $currentHash)');
        }
      }
      
      // Ensure preview songs folder exists
      final previewSongsFolderId = await _ensurePreviewSongsFolder();
      
      // Generate a unique filename based on project ID
      final fileName = path.basename(localFilePath);
      final fileExtension = path.extension(fileName);
      final driveFileName = '${projectId}_preview$fileExtension';
      
      // Check if file already exists
      var response = await _driveApi!.files.list(
        q: "name='$driveFileName' and parents in '$previewSongsFolderId' and trashed=false",
        spaces: 'drive',
      );

      final fileBytes = await file.readAsBytes();
      final media = drive.Media(
        Stream.value(fileBytes),
        fileBytes.length,
        contentType: _getContentTypeForFile(fileExtension),
      );

      String fileId;
      if (response.files != null && response.files!.isNotEmpty) {
        // Update existing file
        fileId = response.files!.first.id!;
        await _driveApi!.files.update(
          drive.File()..name = driveFileName,
          fileId,
          uploadMedia: media,
        );
        if (kDebugMode) print('Updated preview song: $driveFileName (ID: $fileId)');
      } else {
        // Create new file
        final driveFile = drive.File();
        driveFile.name = driveFileName;
        driveFile.parents = [previewSongsFolderId];
        
        final createdFile = await _driveApi!.files.create(driveFile, uploadMedia: media);
        fileId = createdFile.id!;
        if (kDebugMode) print('Uploaded preview song: $driveFileName (ID: $fileId)');
      }
      
      return {
        'fileId': fileId,
        'hash': currentHash,
        'fileName': fileName, // Original filename
      };
    } catch (e) {
      if (kDebugMode) print('Error uploading preview song: $e');
      return null;
    }
  }

  /// Download preview song file from Google Drive to local storage
  /// Returns the local file path, or null if download failed
  /// Uses hash comparison to avoid unnecessary downloads
  Future<String?> downloadPreviewSongFile({
    required String driveFileId,
    required String projectId,
    String? expectedHash, // Hash from project.uploadedPreviewSongHash
    String? fileExtension, // File extension from previewSongFileName or default to .mp3
  }) async {
    if (_driveApi == null) {
      if (kDebugMode) print('Drive API not initialized, attempting to restore session...');
      final restored = await restoreSession();
      if (!restored) {
        if (kDebugMode) print('Failed to restore session for download');
        return null;
      }
    }

    try {
      // Get local preview songs directory
      final previewSongsDir = await getPreviewSongsPath();
      final ext = fileExtension ?? '.mp3';
      final localFilePath = path.join(previewSongsDir, '${projectId}_preview$ext');
      
      // Check if file already exists and hash matches
      final existingFile = File(localFilePath);
      if (await existingFile.exists() && expectedHash != null) {
        try {
          final existingHash = await _calculateFileHash(localFilePath);
          if (existingHash == expectedHash) {
            if (kDebugMode) {
              print('Preview song already downloaded with matching hash, skipping download');
            }
            return localFilePath;
          } else {
            if (kDebugMode) {
              print('Preview song hash mismatch (local: $existingHash, expected: $expectedHash), re-downloading...');
            }
            // Delete old file
            await existingFile.delete();
          }
        } catch (e) {
          if (kDebugMode) print('Error checking existing file hash: $e, will re-download');
          // If hash check fails, delete and re-download
          if (await existingFile.exists()) {
            await existingFile.delete();
          }
        }
      }
      
      if (kDebugMode) {
        print('Downloading preview song from Drive: $driveFileId');
      }
      
      // Download file using Drive API
      final media = await _driveApi!.files.get(
        driveFileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;
      
      // Read the stream and write to file
      final file = File(localFilePath);
      final sink = file.openWrite();
      
      await for (final chunk in media.stream) {
        sink.add(chunk);
      }
      await sink.close();
      
      // Verify hash if expected hash was provided
      if (expectedHash != null) {
        final downloadedHash = await _calculateFileHash(localFilePath);
        if (downloadedHash != expectedHash) {
          if (kDebugMode) {
            print('WARNING: Downloaded file hash mismatch! Expected: $expectedHash, Got: $downloadedHash');
          }
          // Still return the file, but log the warning
        } else {
          if (kDebugMode) {
            print('Downloaded file hash verified: $downloadedHash');
          }
        }
      }
      
      if (kDebugMode) {
        print('Downloaded preview song to: $localFilePath');
      }
      
      return localFilePath;
    } catch (e) {
      if (kDebugMode) print('Error downloading preview song: $e');
      return null;
    }
  }


  /// Check if a preview song path is a Google Drive file reference
  /// Format: "drive://{fileId}"
  bool _isDriveFileReference(String? path) {
    return path != null && path.startsWith('drive://');
  }

  /// Extract drive file ID from a drive file reference
  /// Format: "drive://{fileId}" -> "{fileId}"
  String? _extractDriveFileId(String path) {
    if (!_isDriveFileReference(path)) return null;
    return path.substring(8); // Remove "drive://" prefix
  }

  /// Create a drive file reference from a file ID
  /// Format: "{fileId}" -> "drive://{fileId}"
  String _createDriveFileReference(String fileId) {
    return 'drive://$fileId';
  }

  /// Calculate MD5 hash of a file
  /// Calculate MD5 hash of a file
  /// Public method so it can be called from UI when adding preview songs
  Future<String> calculateFileHash(String filePath) async {
    return _calculateFileHash(filePath);
  }
  
  Future<String> _calculateFileHash(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }
    
    final bytes = await file.readAsBytes();
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// Get content type for file extension
  String _getContentTypeForFile(String extension) {
    switch (extension.toLowerCase()) {
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.m4a':
        return 'audio/mp4';
      case '.aac':
        return 'audio/aac';
      case '.ogg':
        return 'audio/ogg';
      case '.flac':
        return 'audio/flac';
      default:
        return 'application/octet-stream';
    }
  }

  /// Upload database to Google Drive
  /// Backs up the ENTIRE application (all profiles, projects, releases, etc.)
  /// Mobile will mirror the desktop app - it doesn't need its own functionality
  Future<void> uploadDatabase({
    required ProjectRepository projectRepo,
    required ProfileRepository profileRepo,
    String? profileId, // Optional - kept for compatibility but not used in filename
  }) async {
    if (_driveApi == null || _appDataFolderId == null) {
      throw Exception('Not signed in to Google Drive');
    }

    // Reset cancellation flag at the start
    _isCancelled = false;

    try {
      // Serialize ALL data from the entire application
      // Collect data from ALL profiles, not just the current one
      final allProfiles = profileRepo.getAllProfiles();
      
      // Collect projects, releases, and roots from ALL profiles
      // IMPORTANT: We need to track which profile each project/release/root belongs to
      final allProjects = <MusicProject>[];
      final allReleases = <Release>[];
      final allRoots = <ScanRoot>[];
      
      // Maps to track which profile each item belongs to
      final projectToProfileMap = <String, String>{}; // projectId -> profileId
      final releaseToProfileMap = <String, String>{}; // releaseId -> profileId
      final rootToProfileMap = <String, String>{}; // rootId -> profileId
      
      // Map to track preview song files in Google Drive
      // projectId -> driveFileId
      final previewSongFileMap = <String, String>{};
      // Map to track preview song hashes
      // projectId -> fileHash
      final previewSongHashes = <String, String>{};
      // Map to track original filenames
      // projectId -> originalFileName
      final previewSongFileNames = <String, String>{};
      
      // Get existing hashes from previous backup (if available) to avoid unnecessary uploads
      Map<String, String> existingHashes = {};
      try {
        final existingBackup = await downloadDatabase();
        if (existingBackup['previewSongHashes'] != null) {
          existingHashes = Map<String, String>.from(existingBackup['previewSongHashes'] as Map);
          if (kDebugMode) {
            print('Found ${existingHashes.length} existing preview song hashes from previous backup');
          }
        }
      } catch (_) {
        // No previous backup or error reading it - that's okay, we'll upload everything
        if (kDebugMode) {
          print('No previous backup found or error reading it - will upload all preview songs');
        }
      }
      
      if (kDebugMode) {
        print('Collecting data from ${allProfiles.length} profiles...');
      }
      
      // Emit progress: collecting data
      _progressController.add(BackupProgress(
        stage: BackupProgressStage.collectingData,
        currentItem: 'Collecting data from profiles...',
        currentIndex: 0,
        totalItems: allProfiles.length,
        progress: 0.0,
      ));
      
      if (allProfiles.isEmpty) {
        if (kDebugMode) {
          print('WARNING: No profiles found! Cannot create backup.');
        }
        throw Exception('No profiles found - cannot create backup');
      }
      
      // Track actual preview song uploads (not estimates)
      int previewSongsUploaded = 0;
      
      int profileIndex = 0;
      for (final profile in allProfiles) {
        // Check for cancellation
        if (_isCancelled) {
          throw Exception('Upload cancelled by user');
        }
        
        profileIndex++;
        
        // Emit progress for this profile
        _progressController.add(BackupProgress(
          stage: BackupProgressStage.collectingData,
          currentItem: 'Collecting data from profile: ${profile.name}',
          currentIndex: profileIndex,
          totalItems: allProfiles.length,
          progress: profileIndex / allProfiles.length * 0.2, // 20% of total for collecting
        ));
        try {
          if (kDebugMode) {
            print('  Processing profile: ${profile.name} (${profile.id})');
          }
          
          // Open boxes for this profile
          final profileProjectsBox = await Hive.openBox<MusicProject>('${profile.id}_projects');
          final profileReleasesBox = await Hive.openBox<Release>('${profile.id}_releases');
          final profileRootsBox = await Hive.openBox<ScanRoot>('${profile.id}_roots');
          
          if (kDebugMode) {
            print('    Opened boxes: ${profileProjectsBox.length} projects, ${profileReleasesBox.length} releases, ${profileRootsBox.length} roots');
          }
          
          // Collect projects and track which profile they belong to
          for (final project in profileProjectsBox.values) {
            if (!allProjects.any((p) => p.id == project.id)) {
              allProjects.add(project);
            }
            // Track that this project belongs to this profile
            projectToProfileMap[project.id] = profile.id;
            
            // Upload preview song if it exists (only on desktop - mobile doesn't add preview songs)
            // On mobile, we only download preview songs, never upload them
            if (!Platform.isAndroid && !Platform.isIOS) {
              if (project.previewSongPath != null && project.previewSongPath!.isNotEmpty) {
                // Skip if it's a Drive reference (already uploaded)
                if (!project.previewSongPath!.startsWith('drive://')) {
                  try {
                    // Retrieve the latest project from Hive to ensure we have the most recent hash
                    final latestProject = profileProjectsBox.get(project.id);
                    if (latestProject == null) {
                      if (kDebugMode) {
                        print('  Project ${project.id} not found in Hive, skipping preview song upload');
                      }
                      continue;
                    }
                    
                    // Calculate current file hash first
                    final currentLocalHash = await _calculateFileHash(latestProject.previewSongPath!);
                    
                    // Compare with hash stored in local database (retrieved from Hive)
                    // Only use existingHashes from backup if project.uploadedPreviewSongHash is null
                    final storedHash = latestProject.uploadedPreviewSongHash;
                    
                    // If hash matches, skip upload (file hasn't changed)
                    if (storedHash != null && storedHash == currentLocalHash) {
                      if (kDebugMode) {
                        print('  Preview song unchanged for project ${latestProject.id} (local hash matches: $currentLocalHash), skipping upload');
                      }
                      // Still need to get the file ID from Drive if it exists
                      final previewSongsFolderId = await _ensurePreviewSongsFolder();
                      final fileName = path.basename(latestProject.previewSongPath!);
                      final fileExtension = path.extension(fileName);
                      final driveFileName = '${latestProject.id}_preview$fileExtension';
                      
                      var response = await _driveApi!.files.list(
                        q: "name='$driveFileName' and parents in '$previewSongsFolderId' and trashed=false",
                        spaces: 'drive',
                      );
                      
                      if (response.files != null && response.files!.isNotEmpty) {
                        previewSongFileMap[latestProject.id] = response.files!.first.id!;
                        previewSongHashes[latestProject.id] = currentLocalHash;
                        if (latestProject.previewSongFileName != null) {
                          previewSongFileNames[latestProject.id] = latestProject.previewSongFileName!;
                        }
                      }
                      continue; // Skip to next project
                    }
                    
                    // Hash changed or doesn't exist - upload
                    // Retrieve hash from Hive database (ensure we have the latest version)
                    // Use stored hash from project first, then fallback to existingHashes from backup
                    final existingHash = storedHash ?? existingHashes[latestProject.id];
                    
                    // Increment upload counter
                    previewSongsUploaded++;
                    
                    // Emit progress for preview song upload
                    // Note: We show the count but not total (since we don't know how many will need upload until we check each one)
                    _progressController.add(BackupProgress(
                      stage: BackupProgressStage.uploadingPreviewSongs,
                      currentItem: 'Uploading preview: ${path.basename(latestProject.previewSongPath!)}',
                      currentIndex: previewSongsUploaded,
                      totalItems: 0, // Unknown until we process all
                      progress: 0.2 + (previewSongsUploaded * 0.05).clamp(0.0, 0.6), // Incremental progress
                    ));
                    
                    // Check for cancellation before upload
                    if (_isCancelled) {
                      throw Exception('Upload cancelled by user');
                    }
                    
                    final result = await _uploadPreviewSongFile(
                      projectId: latestProject.id,
                      localFilePath: latestProject.previewSongPath!,
                      existingHash: existingHash,
                    );
                    if (result != null) {
                      previewSongFileMap[latestProject.id] = result['fileId']!;
                      final newHash = result['hash']!; // This is the hash of the uploaded file
                      previewSongHashes[latestProject.id] = newHash;
                      if (result.containsKey('fileName')) {
                        previewSongFileNames[latestProject.id] = result['fileName']!;
                      }
                      
                      // ALWAYS update project with new hash after successful upload
                      // This ensures the local database hash matches what was uploaded
                      // Retrieve fresh project from Hive to ensure we're updating the latest version
                      final currentProject = profileProjectsBox.get(latestProject.id);
                      if (currentProject != null) {
                        final updatedProject = currentProject.copyWith(uploadedPreviewSongHash: newHash);
                        await profileProjectsBox.put(latestProject.id, updatedProject);
                        await profileProjectsBox.flush(); // Ensure hash is persisted immediately
                        if (kDebugMode) {
                          print('  Updated project ${latestProject.id} with preview song hash after upload: $newHash');
                        }
                      } else {
                        if (kDebugMode) {
                          print('  Warning: Project ${latestProject.id} not found in Hive when trying to update hash');
                        }
                      }
                      
                      if (kDebugMode) {
                        print('  Preview song for project ${latestProject.id}: ${result['fileId']} (hash: $newHash, filename: ${result['fileName'] ?? 'N/A'})');
                      }
                    }
                  } catch (e) {
                    if (kDebugMode) {
                      print('  Error uploading preview song for project ${project.id}: $e');
                    }
                  }
                } else {
                  // It's a Drive reference - use hash from project if available
                  if (project.uploadedPreviewSongHash != null) {
                    previewSongHashes[project.id] = project.uploadedPreviewSongHash!;
                  }
                }
              }
            }
          }
          
          // Collect releases and track which profile they belong to
          for (final release in profileReleasesBox.values) {
            if (!allReleases.any((r) => r.id == release.id)) {
              allReleases.add(release);
            }
            // Track that this release belongs to this profile
            releaseToProfileMap[release.id] = profile.id;
          }
          
          // Collect roots and track which profile they belong to
          for (final root in profileRootsBox.values) {
            if (!allRoots.any((r) => r.id == root.id)) {
              allRoots.add(root);
            }
            // Track that this root belongs to this profile
            rootToProfileMap[root.id] = profile.id;
          }
          
          if (kDebugMode) {
            print('  Profile ${profile.name}: ${profileProjectsBox.length} projects, ${profileReleasesBox.length} releases, ${profileRootsBox.length} roots');
          }
          
          // Close boxes after collecting data to free resources
          // Note: We don't close them here because they might be in use by the current repository
          // Instead, we'll let Hive manage them
        } catch (e) {
          if (kDebugMode) {
            print('Error collecting data for profile ${profile.id}: $e');
          }
        }
      }
      
      // Collect TODO templates (global, not per-profile)
      final List<TodoTemplate> allTemplates = [];
      try {
        final templatesBox = await Hive.openBox<TodoTemplate>('todoTemplates');
        allTemplates.addAll(templatesBox.values);
        if (kDebugMode) {
          print('Collected ${allTemplates.length} TODO templates');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error collecting TODO templates: $e');
        }
      }
      
      final data = {
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.4', // Incremented version to include TODO templates
        'profiles': allProfiles.map((p) => _serializeProfile(p)).toList(),
        'projects': allProjects.map((p) => _serializeProject(p)).toList(),
        'releases': allReleases.map((r) => _serializeRelease(r)).toList(),
        'roots': allRoots.map((r) => _serializeRoot(r)).toList(),
        'templates': allTemplates.map((t) => _serializeTemplate(t)).toList(),
        // NEW: Profile mappings to restore correct associations
        'projectToProfile': projectToProfileMap,
        'releaseToProfile': releaseToProfileMap,
        'rootToProfile': rootToProfileMap,
        // NEW: Preview song file mappings (projectId -> driveFileId)
        'previewSongFiles': previewSongFileMap,
        // NEW: Preview song hashes (projectId -> fileHash) for change detection
        'previewSongHashes': previewSongHashes,
        // NEW: Preview song original filenames (projectId -> originalFileName)
        'previewSongFileNames': previewSongFileNames,
      };

      // Emit progress: uploading database
      _progressController.add(BackupProgress(
        stage: BackupProgressStage.uploadingDatabase,
        currentItem: 'Uploading database backup...',
        currentIndex: 1,
        totalItems: 1,
        progress: 0.85, // 85%
      ));
      
      final jsonData = jsonEncode(data);
      final bytes = utf8.encode(jsonData);

      // Use a single filename for the entire application backup
      // No profileId in filename - this is the complete app backup
      final fileName = _databaseFileName;
      if (kDebugMode) {
        print('=== Upload Complete Application Backup ===');
        print('Platform: ${Platform.operatingSystem}');
        print('File name: $fileName');
        print('Shared folder ID: $_appDataFolderId');
        print('Shared folder name: $_appDataFolderName');
        print('Spaces: drive (shared folder)');
        print('Profiles included: ${(data['profiles'] as List).length}');
        print('Projects included: ${(data['projects'] as List).length}');
        print('Releases included: ${(data['releases'] as List).length}');
        print('Templates included: ${(data['templates'] as List).length}');
      }
      final response = await _driveApi!.files.list(
        q: "name='$fileName' and parents in '$_appDataFolderId' and trashed=false",
        spaces: 'drive',
      );

      if (response.files != null && response.files!.isNotEmpty) {
        // Update existing file
        final fileId = response.files!.first.id!;
        final media = drive.Media(
          Stream.value(bytes),
          bytes.length,
          contentType: 'application/json',
        );
        await _driveApi!.files.update(
          drive.File()..name = fileName,
          fileId,
          uploadMedia: media,
        );
        if (kDebugMode) print('✓ Updated existing backup file');
      } else {
        // Create new file
        final file = drive.File();
        file.name = fileName;
        file.parents = [_appDataFolderId!];
        
        final media = drive.Media(
          Stream.value(bytes),
          bytes.length,
          contentType: 'application/json',
        );
        await _driveApi!.files.create(file, uploadMedia: media);
        if (kDebugMode) print('✓ Created new backup file');
      }

      // Update sync metadata (global, not per-profile)
      await _updateSyncMetadata(DateTime.now());
      
      // Emit progress: completed
      _progressController.add(BackupProgress(
        stage: BackupProgressStage.completed,
        currentItem: 'Backup completed successfully!',
        currentIndex: 1,
        totalItems: 1,
        progress: 1.0, // 100%
      ));
    } catch (e) {
      if (kDebugMode) print('Error uploading database: $e');
      rethrow;
    }
  }

  /// Download database from Google Drive
  /// Downloads the complete application backup (all profiles, projects, releases, etc.)
  /// Mobile will use this to mirror the desktop app
  Future<Map<String, dynamic>> downloadDatabase() async {
    if (_driveApi == null || _appDataFolderId == null) {
      throw Exception('Not signed in to Google Drive');
    }

    try {
      // Use a single filename for the entire application backup
      // No profileId in filename - this is the complete app backup
      final fileName = _databaseFileName;
      if (kDebugMode) {
        print('=== Download Complete Application Backup ===');
        print('Platform: ${Platform.operatingSystem}');
        print('File name searched: $fileName');
        print('Shared folder ID: $_appDataFolderId');
        print('Shared folder name: $_appDataFolderName');
        print('Spaces: drive (shared folder)');
      }
      final response = await _driveApi!.files.list(
        q: "name='$fileName' and parents in '$_appDataFolderId' and trashed=false",
        spaces: 'drive',
      );

      if (response.files == null || response.files!.isEmpty) {
        if (kDebugMode) {
          print('❌ Database file not found in Google Drive');
          print('File name searched: $fileName');
          print('Shared folder ID: $_appDataFolderId');
          print('Shared folder name: $_appDataFolderName');
          print('');
          print('🔍 DEBUG: Listing all files in shared folder...');
          // List all files in shared folder to help debug
          try {
            final allFiles = await _driveApi!.files.list(
              q: "parents in '$_appDataFolderId' and trashed=false",
              spaces: 'drive',
            );
            if (allFiles.files != null && allFiles.files!.isNotEmpty) {
              print('✅ Files found in shared folder (${allFiles.files!.length} files):');
              for (final file in allFiles.files!) {
                print('  - ${file.name} (ID: ${file.id})');
                // Check if this file matches the pattern we're looking for
                if (file.name?.contains('database_backup.json') == true) {
                  print('    ⚠️ This is a backup file but with a different name?');
                  print('    Expected: $fileName');
                  print('    Found: ${file.name}');
                }
              }
              print('');
              print('💡 TIP: The backup file should be named exactly: $fileName');
              print('   This is the complete application backup (all profiles included).');
            } else {
              print('❌ No files found in shared folder');
              print('   The folder exists but is empty.');
            }
          } catch (e) {
            print('❌ Error listing files: $e');
          }
          
          // Also try to find the folder by name to verify it exists
          print('');
          print('🔍 DEBUG: Verifying folder exists...');
          try {
            final folderCheck = await _driveApi!.files.list(
              q: "name='$_appDataFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false",
              spaces: 'drive',
            );
            if (folderCheck.files != null && folderCheck.files!.isNotEmpty) {
              print('✅ Folder found: ${folderCheck.files!.first.name} (ID: ${folderCheck.files!.first.id})');
              if (folderCheck.files!.first.id != _appDataFolderId) {
                print('⚠️ WARNING: Folder ID mismatch!');
                print('   Expected: $_appDataFolderId');
                print('   Found: ${folderCheck.files!.first.id}');
              }
            } else {
              print('❌ Folder not found!');
            }
          } catch (e) {
            print('❌ Error checking folder: $e');
          }
        }
        throw Exception('Database file not found in Google Drive');
      }

      final fileId = response.files!.first.id!;
      final media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // Read file content
      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }

      final jsonString = utf8.decode(bytes);
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Save timestamp of this download
      // Use timestamp from backup JSON if available, otherwise use current time
      DateTime downloadTimestamp = DateTime.now();
      if (backupData['timestamp'] != null) {
        try {
          downloadTimestamp = DateTime.parse(backupData['timestamp'] as String);
        } catch (_) {
          // If parsing fails, use current time
        }
      }
      await saveLastBackupDownloadTimestamp(downloadTimestamp);
      
      return backupData;
    } catch (e) {
      if (kDebugMode) {
        if (e.toString().contains('Database file not found')) {
          print('No backup file found (this is normal for first-time setup)');
          print('You can create an initial backup by syncing or uploading your data');
        } else {
          print('Error downloading database: $e');
        }
      }
      rethrow;
    }
  }

  /// Get last sync time for the application (global, not per-profile)
  Future<DateTime?> getLastSyncTime() async {
    try {
      final metadata = await _getSyncMetadata();
      // Metadata now stores a single 'lastSync' timestamp for the entire app
      return metadata['lastSync'] != null 
          ? DateTime.parse(metadata['lastSync'] as String)
          : null;
    } catch (e) {
      if (kDebugMode) print('Error getting last sync time: $e');
      return null;
    }
  }

  /// Update sync metadata (global for entire application)
  Future<void> _updateSyncMetadata(DateTime syncTime) async {
    if (_driveApi == null || _appDataFolderId == null) {
      return;
    }

    try {
      Map<String, dynamic> metadata = {};
      
      // Try to get existing metadata
      try {
        final existingMetadata = await _getSyncMetadata();
        metadata = existingMetadata;
      } catch (_) {
        // Metadata doesn't exist yet, create new
      }

      // Store single timestamp for the entire application
      metadata['lastSync'] = syncTime.toIso8601String();

      final jsonData = jsonEncode(metadata);
      final bytes = utf8.encode(jsonData);

      // Find or create metadata file
      final response = await _driveApi!.files.list(
        q: "name='$_metadataFileName' and parents in '$_appDataFolderId' and trashed=false",
        spaces: 'drive',
      );

      if (response.files != null && response.files!.isNotEmpty) {
        // Update existing file
        final fileId = response.files!.first.id!;
        final media = drive.Media(
          Stream.value(bytes),
          bytes.length,
          contentType: 'application/json',
        );
        await _driveApi!.files.update(
          drive.File()..name = _metadataFileName,
          fileId,
          uploadMedia: media,
        );
      } else {
        // Create new file
        final file = drive.File();
        file.name = _metadataFileName;
        file.parents = [_appDataFolderId!];
        
        final media = drive.Media(
          Stream.value(bytes),
          bytes.length,
          contentType: 'application/json',
        );
        await _driveApi!.files.create(file, uploadMedia: media);
      }
    } catch (e) {
      if (kDebugMode) print('Error updating sync metadata: $e');
    }
  }

  /// Get sync metadata
  Future<Map<String, dynamic>> _getSyncMetadata() async {
    if (_driveApi == null || _appDataFolderId == null) {
      return {};
    }

    try {
      final response = await _driveApi!.files.list(
        q: "name='$_metadataFileName' and parents in '$_appDataFolderId' and trashed=false",
        spaces: 'drive',
      );

      if (response.files == null || response.files!.isEmpty) {
        return {};
      }

      final fileId = response.files!.first.id!;
      final media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }

      final jsonString = utf8.decode(bytes);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) print('Error getting sync metadata: $e');
      return {};
    }
  }

  /// Sync database (merge local and remote) with conflict detection
  /// Syncs the ENTIRE application (all profiles, projects, releases, etc.)
  /// Mobile will mirror the desktop app
  Future<SyncResult> syncDatabase({
    required ProjectRepository projectRepo,
    required ProfileRepository profileRepo,
    String? profileId, // Optional - kept for compatibility but not used
  }) async {
    try {
      if (kDebugMode) print('Starting complete application sync...');
      
      // Get last sync times (global, not per-profile)
      final localLastModified = await _getLocalLastModified(profileRepo);
      final remoteLastSync = await getLastSyncTime();
      
      if (kDebugMode) {
        print('Local last modified: $localLastModified');
        print('Remote last sync: $remoteLastSync');
      }

      // Check if remote backup exists
      bool remoteExists = false;
      try {
        await downloadDatabase();
        remoteExists = true;
      } catch (_) {
        // Remote doesn't exist yet
        remoteExists = false;
      }

      // If no remote backup exists, just upload
      if (!remoteExists) {
        if (kDebugMode) print('No remote backup found, uploading complete local data...');
        await uploadDatabase(
          projectRepo: projectRepo,
          profileRepo: profileRepo,
        );
        return SyncResult(
          projectsAdded: 0,
          projectsUpdated: 0,
          releasesAdded: 0,
          releasesUpdated: 0,
        );
      }

      // Download remote data to check for conflicts
      final remoteData = await downloadDatabase();
      final remoteTimestamp = remoteData['timestamp'] != null 
          ? DateTime.parse(remoteData['timestamp'] as String)
          : null;

      // Conflict detection: if both local and remote were modified since last sync
      bool hasConflict = false;
      if (localLastModified != null && remoteLastSync != null && remoteTimestamp != null) {
        // Check if local was modified after last sync
        final localModifiedAfterSync = localLastModified.isAfter(remoteLastSync);
        // Check if remote was modified after last sync
        final remoteModifiedAfterSync = remoteTimestamp.isAfter(remoteLastSync);
        
        // Conflict: both were modified
        hasConflict = localModifiedAfterSync && remoteModifiedAfterSync;
        
        if (kDebugMode) {
          print('Conflict detection:');
          print('  Local modified after sync: $localModifiedAfterSync');
          print('  Remote modified after sync: $remoteModifiedAfterSync');
          print('  Has conflict: $hasConflict');
        }
      }

      if (hasConflict) {
        if (kDebugMode) print('Conflict detected! Both local and remote were modified.');
        // For conflicts, we'll merge intelligently (prefer newer data)
        // This could be improved with user interaction to choose which version to keep
      }

      // Merge data (handles conflicts by preferring newer timestamps)
      // This merges ALL profiles, projects, and releases
      // For sync operations, always download preview songs (default behavior)
      final result = await mergeData(
        remoteData: remoteData,
        projectRepo: projectRepo,
        profileRepo: profileRepo,
        downloadPreviewSongs: true, // Always download during sync
      );

      // Upload merged data (complete application backup)
      await uploadDatabase(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );

      if (kDebugMode) {
        print('Sync completed:');
        print('  Projects: +${result.projectsAdded} ~${result.projectsUpdated}');
        print('  Releases: +${result.releasesAdded} ~${result.releasesUpdated}');
        if (hasConflict) print('  ⚠️ Conflict was resolved by merging');
      }

      return result;
    } catch (e) {
      if (kDebugMode) print('Error syncing database: $e');
      rethrow;
    }
  }

  /// Get local last modified time (checks ALL profiles)
  Future<DateTime?> _getLocalLastModified(ProfileRepository profileRepo) async {
    try {
      DateTime? lastModified;
      
      // Check all profiles
      for (final profile in profileRepo.getAllProfiles()) {
        try {
          final projectsBox = await Hive.openBox<MusicProject>('${profile.id}_projects');
          final releasesBox = await Hive.openBox<Release>('${profile.id}_releases');
          
          for (final project in projectsBox.values) {
            if (lastModified == null || project.updatedAt.isAfter(lastModified)) {
              lastModified = project.updatedAt;
            }
          }
          
          for (final release in releasesBox.values) {
            // Releases don't have updatedAt, use a default
            final releaseTime = DateTime.now();
            if (lastModified == null || releaseTime.isAfter(lastModified)) {
              lastModified = releaseTime;
            }
          }
        } catch (e) {
          // Skip if box doesn't exist for this profile
          if (kDebugMode) print('Skipping profile ${profile.id}: $e');
        }
      }
      
      return lastModified;
    } catch (e) {
      if (kDebugMode) print('Error getting local last modified: $e');
      return null;
    }
  }

  /// Helper to compare lists
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Compare todos lists (by content, not just reference)
  bool _todosEqual(List<TodoItem> a, List<TodoItem> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || 
          a[i].text != b[i].text || 
          a[i].completed != b[i].completed) {
        return false;
      }
    }
    return true;
  }

  /// Check if metadata fields changed (user-editable fields, not file system fields)
  /// Android only modifies metadata (todos, notes, bpm, key, status, etc.)
  /// We don't use updatedAt because it can change when file is modified on disk
  bool _hasMetadataChanged(MusicProject remote, MusicProject local) {
    // Compare only metadata fields (what Android can modify)
    // NOT file system fields (filePath, fileName, fileSizeBytes, lastModifiedAt, etc.)
    return remote.notes != local.notes ||
        !_todosEqual(remote.todos, local.todos) ||
        remote.bpm != local.bpm ||
        remote.musicalKey != local.musicalKey ||
        remote.status != local.status ||
        remote.customDisplayName != local.customDisplayName ||
        remote.hidden != local.hidden;
  }

  /// Merge remote data with local data
  /// Merges ALL profiles, projects, and releases from the complete application backup
  /// Made public for manual download operations
  /// [downloadPreviewSongs] - If true, downloads preview song files during merge (default: true)
  Future<SyncResult> mergeData({
    required Map<String, dynamic> remoteData,
    required ProjectRepository projectRepo,
    required ProfileRepository profileRepo,
    bool downloadPreviewSongs = true,
  }) async {
    int projectsAdded = 0;
    int projectsUpdated = 0;
    int releasesAdded = 0;
    int releasesUpdated = 0;

    // First, merge profiles
    if (remoteData['profiles'] != null) {
      final remoteProfiles = (remoteData['profiles'] as List)
          .map((p) => _deserializeProfile(p as Map<String, dynamic>))
          .toList();
      
      for (final remoteProfile in remoteProfiles) {
        final localProfile = profileRepo.getProfileById(remoteProfile.id);
        if (localProfile == null) {
          // New profile from remote - add it
          await profileRepo.profilesBox.put(remoteProfile.id, remoteProfile);
          if (kDebugMode) print('Added new profile from backup: ${remoteProfile.name}');
        } else {
          // Update existing profile (merge metadata)
          await profileRepo.profilesBox.put(remoteProfile.id, remoteProfile);
          if (kDebugMode) print('Updated profile from backup: ${remoteProfile.name}');
        }
      }
    }

    // Now merge projects and releases for the CORRECT profiles
    // The backup contains profile mappings to restore correct associations
    // Get all profiles (including newly merged ones)
    final allProfiles = profileRepo.getAllProfiles();
    
    // Get profile mappings from backup (if available, for version 1.1+)
    final projectToProfileMap = remoteData['projectToProfile'] as Map<String, dynamic>?;
    final releaseToProfileMap = remoteData['releaseToProfile'] as Map<String, dynamic>?;
    final rootToProfileMap = remoteData['rootToProfile'] as Map<String, dynamic>?;
    
    // Get preview song file mappings (if available, for version 1.2+)
    // Maps projectId -> driveFileId
    final previewSongFiles = remoteData['previewSongFiles'] as Map<String, dynamic>?;
    // Get preview song original filenames (if available, for version 1.3+)
    // Maps projectId -> originalFileName
    final previewSongFileNames = remoteData['previewSongFileNames'] as Map<String, dynamic>?;
    // Get preview song hashes (if available, for version 1.3+)
    // Maps projectId -> fileHash
    final previewSongHashes = remoteData['previewSongHashes'] as Map<String, dynamic>?;
    
    // Create reverse lookup: profileId -> list of project/release/root IDs
    final profileToProjects = <String, List<String>>{};
    final profileToReleases = <String, List<String>>{};
    final profileToRoots = <String, List<String>>{};
    
    if (projectToProfileMap != null) {
      // New format (v1.1+): Use profile mappings
      projectToProfileMap.forEach((projectId, profileId) {
        profileToProjects.putIfAbsent(profileId.toString(), () => []).add(projectId);
      });
    }
    
    if (releaseToProfileMap != null) {
      releaseToProfileMap.forEach((releaseId, profileId) {
        profileToReleases.putIfAbsent(profileId.toString(), () => []).add(releaseId);
      });
    }
    
    if (rootToProfileMap != null) {
      rootToProfileMap.forEach((rootId, profileId) {
        profileToRoots.putIfAbsent(profileId.toString(), () => []).add(rootId);
      });
    }
    
    if (kDebugMode) {
      if (projectToProfileMap != null) {
        print('Using profile mappings from backup (v1.1+)');
        print('Projects will be distributed to correct profiles');
      } else {
        print('No profile mappings found (old backup format) - distributing to ALL profiles');
      }
      if (previewSongFiles != null && previewSongFiles.isNotEmpty) {
        print('Found ${previewSongFiles.length} preview songs to download');
      }
    }
    
    // Merge projects - distribute to CORRECT profiles (or ALL if no mappings)
    if (remoteData['projects'] != null) {
      final remoteProjects = (remoteData['projects'] as List)
          .map((p) => _deserializeProject(p as Map<String, dynamic>))
          .toList();
      
      // If we have profile mappings, use them; otherwise distribute to all profiles (backward compatibility)
      final targetProfiles = projectToProfileMap != null 
          ? allProfiles.where((p) => profileToProjects.containsKey(p.id)).toList()
          : allProfiles;
      
      for (final profile in targetProfiles) {
        try {
          final profileProjectsBox = await Hive.openBox<MusicProject>('${profile.id}_projects');
          int profileProjectsAdded = 0;
          int profileProjectsUpdated = 0;
          
          // Get projects that belong to this profile
          final profileProjectIds = projectToProfileMap != null
              ? (profileToProjects[profile.id] ?? [])
              : remoteProjects.map((p) => p.id).toList(); // All projects if no mapping
          
          for (final remoteProject in remoteProjects) {
            // Only process if this project belongs to this profile (or all if no mapping)
            if (profileProjectIds.contains(remoteProject.id)) {
              final localProject = profileProjectsBox.get(remoteProject.id);
              
              if (localProject == null) {
                // New project from remote
                MusicProject projectToSave = remoteProject;
                if (previewSongFiles != null && previewSongFiles.containsKey(remoteProject.id)) {
                  try {
                    final driveFileId = previewSongFiles[remoteProject.id] as String;
                    // Get original filename and hash if available
                    String? originalFileName;
                    String? expectedHash;
                    if (previewSongFileNames != null && previewSongFileNames.containsKey(remoteProject.id)) {
                      originalFileName = previewSongFileNames[remoteProject.id] as String;
                    }
                    if (previewSongHashes != null && previewSongHashes.containsKey(remoteProject.id)) {
                      expectedHash = previewSongHashes[remoteProject.id] as String;
                    }
                    
                    // Download preview song file (all platforms)
                    String? fileExtension;
                    if (originalFileName != null) {
                      fileExtension = path.extension(originalFileName);
                    }
                    
                    final localFilePath = await downloadPreviewSongFile(
                      driveFileId: driveFileId,
                      projectId: remoteProject.id,
                      expectedHash: expectedHash,
                      fileExtension: fileExtension,
                    );
                    
                    if (localFilePath != null) {
                      projectToSave = remoteProject.copyWith(
                        previewSongPath: localFilePath,
                        previewSongFileName: originalFileName,
                        uploadedPreviewSongHash: expectedHash,
                      );
                      if (kDebugMode) {
                        print('    Downloaded preview song for new project: ${remoteProject.displayName} (ID: $driveFileId)');
                      }
                    } else {
                      // Download failed, store Drive reference as fallback
                      final driveReference = _createDriveFileReference(driveFileId);
                      projectToSave = remoteProject.copyWith(
                        previewSongPath: driveReference,
                        previewSongFileName: originalFileName,
                        uploadedPreviewSongHash: expectedHash,
                      );
                      if (kDebugMode) {
                        print('    Download failed, stored Drive reference for: ${remoteProject.displayName} (ID: $driveFileId)');
                      }
                    }
                  } catch (e) {
                    if (kDebugMode) {
                      print('    Error processing preview song for project ${remoteProject.id}: $e');
                    }
                    // Continue without preview song
                  }
                }
                
                await profileProjectsBox.put(projectToSave.id, projectToSave);
                projectsAdded++;
                profileProjectsAdded++;
                if (kDebugMode) {
                  print('    + Added new project: ${remoteProject.displayName}');
                }
              } else {
                // Merge: Compare metadata fields (not file system changes)
                // Android only modifies metadata (todos, notes, bpm, key, status, etc.)
                // We need to check if any metadata field changed, not just updatedAt
                // (updatedAt can change when file is modified on disk, not just metadata)
                
                final metadataChanged = _hasMetadataChanged(remoteProject, localProject);
                
                if (metadataChanged) {
                  // Metadata changed - merge intelligently
                  // Keep file system fields from local (filePath, fileName, fileSizeBytes, lastModifiedAt, etc.)
                  // But update metadata fields from remote (todos, notes, bpm, key, status, etc.)
                  
                  // Update preview song reference if available
                  String? previewSongPath = localProject.previewSongPath;
                  String? previewSongFileName;
                  String? uploadedPreviewSongHash;
                  if (previewSongFiles != null && previewSongFiles.containsKey(remoteProject.id)) {
                    try {
                      final driveFileId = previewSongFiles[remoteProject.id] as String;
                      // Get original filename and hash if available
                      if (previewSongFileNames != null && previewSongFileNames.containsKey(remoteProject.id)) {
                        previewSongFileName = previewSongFileNames[remoteProject.id] as String;
                      }
                      if (previewSongHashes != null && previewSongHashes.containsKey(remoteProject.id)) {
                        uploadedPreviewSongHash = previewSongHashes[remoteProject.id] as String;
                      }
                      
                      if (downloadPreviewSongs) {
                        // On mobile, only download preview songs after backup is downloaded
                        // Check if we need to download (if path is Drive reference or hash changed)
                        bool needsDownload = false;
                        
                        // First, check if file exists locally (especially on mobile)
                        String? localFilePath;
                        if (previewSongPath != null && !_isDriveFileReference(previewSongPath)) {
                          // Path exists and is not a Drive reference - check if file actually exists
                          final localFile = File(previewSongPath);
                          if (await localFile.exists()) {
                            localFilePath = previewSongPath;
                            // File exists locally - verify hash if we have expected hash
                            if (uploadedPreviewSongHash != null) {
                              try {
                                final localHash = await _calculateFileHash(previewSongPath);
                                if (localHash == uploadedPreviewSongHash) {
                                  // Hash matches - no download needed
                                  if (kDebugMode) {
                                    print('    Preview song already exists locally with matching hash for: ${remoteProject.displayName}');
                                  }
                                  needsDownload = false;
                                } else {
                                  // Hash mismatch - need to re-download
                                  if (kDebugMode) {
                                    print('    Preview song hash mismatch (local: $localHash, expected: $uploadedPreviewSongHash) for: ${remoteProject.displayName}, will re-download');
                                  }
                                  needsDownload = true;
                                }
                              } catch (e) {
                                if (kDebugMode) {
                                  print('    Error checking local file hash: $e, will re-download');
                                }
                                needsDownload = true;
                              }
                            } else {
                              // No expected hash - check if local hash matches project hash
                              if (localProject.uploadedPreviewSongHash != null) {
                                try {
                                  final localHash = await _calculateFileHash(previewSongPath);
                                  if (localHash == localProject.uploadedPreviewSongHash) {
                                    // Local hash matches project hash - no download needed
                                    if (kDebugMode) {
                                      print('    Preview song already exists locally with matching hash for: ${remoteProject.displayName}');
                                    }
                                    needsDownload = false;
                                  } else {
                                    // Hash mismatch - need to re-download
                                    needsDownload = true;
                                  }
                                } catch (e) {
                                  needsDownload = true;
                                }
                              } else {
                                // No hash to compare - assume file is valid if it exists
                                needsDownload = false;
                              }
                            }
                          } else {
                            // Path exists but file doesn't - need to download
                            needsDownload = true;
                          }
                        } else if (previewSongPath == null || _isDriveFileReference(previewSongPath)) {
                          // No local path or Drive reference - need to download
                          needsDownload = true;
                        } else if (uploadedPreviewSongHash != null && localProject.uploadedPreviewSongHash != uploadedPreviewSongHash) {
                          // Hash changed - need to download
                          needsDownload = true;
                        }
                        
                        if (needsDownload) {
                          String? fileExtension;
                          if (previewSongFileName != null) {
                            fileExtension = path.extension(previewSongFileName);
                          }
                          
                          final downloadedFilePath = await downloadPreviewSongFile(
                            driveFileId: driveFileId,
                            projectId: remoteProject.id,
                            expectedHash: uploadedPreviewSongHash,
                            fileExtension: fileExtension,
                          );
                          
                          if (downloadedFilePath != null) {
                            previewSongPath = downloadedFilePath;
                            if (kDebugMode) {
                              print('    Downloaded preview song for project: ${remoteProject.displayName} (ID: $driveFileId)');
                            }
                          } else {
                            // Download failed, keep Drive reference
                            previewSongPath = _createDriveFileReference(driveFileId);
                            if (kDebugMode) {
                              print('    Download failed, kept Drive reference for: ${remoteProject.displayName}');
                            }
                          }
                        } else {
                          // File already downloaded and hash matches, keep local path
                          if (kDebugMode) {
                            print('    Preview song already downloaded with matching hash for: ${remoteProject.displayName}');
                          }
                        }
                      } else {
                        // Skip download, store Drive reference
                        previewSongPath = _createDriveFileReference(driveFileId);
                        if (kDebugMode) {
                          print('    Skipped preview song download for project: ${remoteProject.displayName} (ID: $driveFileId)');
                        }
                      }
                    } catch (e) {
                      if (kDebugMode) {
                        print('    Error updating preview song for project ${remoteProject.id}: $e');
                      }
                    }
                  } else if (remoteProject.previewSongPath != null && remoteProject.previewSongPath != localProject.previewSongPath) {
                    // Remote has preview song but no file mapping (old backup format)
                    // If it's a local file path, check if it exists
                    if (!_isDriveFileReference(remoteProject.previewSongPath)) {
                      final remoteFile = File(remoteProject.previewSongPath!);
                      if (await remoteFile.exists()) {
                        previewSongPath = remoteProject.previewSongPath;
                      }
                    } else {
                      // It's already a Drive reference, use it
                      previewSongPath = remoteProject.previewSongPath;
                    }
                  }
                  
                  final mergedProject = localProject.copyWith(
                    // Metadata fields from remote (user-editable)
                    notes: remoteProject.notes,
                    todos: remoteProject.todos,
                    bpm: remoteProject.bpm,
                    musicalKey: remoteProject.musicalKey,
                    status: remoteProject.status,
                    customDisplayName: remoteProject.customDisplayName,
                    hidden: remoteProject.hidden,
                    previewSongPath: previewSongPath,
                    previewSongFileName: previewSongFileName ?? remoteProject.previewSongFileName,
                    uploadedPreviewSongHash: uploadedPreviewSongHash ?? remoteProject.uploadedPreviewSongHash,
                    // Force update timestamp to ensure Hive detects the change
                    updatedAt: DateTime.now(),
                    // Keep file system fields from local (file-based)
                    // filePath, fileName, fileSizeBytes, lastModifiedAt, fileExtension stay from local
                  );
                  
                  // Save the merged project
                  await profileProjectsBox.put(mergedProject.id, mergedProject);
                  projectsUpdated++;
                  profileProjectsUpdated++;
                  
                  // CRITICAL: Force Hive to persist the data by calling flush
                  // This ensures the data is written to disk immediately
                  await profileProjectsBox.flush();
                  
                  // CRITICAL: Force Hive to notify listeners by doing a second put
                  // This ensures Hive emits a BoxEvent even if the object reference is the same
                  // We use copyWith to create a new instance, ensuring Hive detects the change
                  await profileProjectsBox.put(mergedProject.id, mergedProject.copyWith());
                  
                  // Flush again to ensure the second put is also persisted
                  await profileProjectsBox.flush();
                  
                  if (kDebugMode) {
                    final changes = <String>[];
                    if (remoteProject.notes != localProject.notes) changes.add('notes');
                    if (!_todosEqual(remoteProject.todos, localProject.todos)) {
                      changes.add('todos (${remoteProject.todos.length} vs ${localProject.todos.length})');
                    }
                    if (remoteProject.bpm != localProject.bpm) changes.add('bpm');
                    if (remoteProject.musicalKey != localProject.musicalKey) changes.add('key');
                    if (remoteProject.status != localProject.status) changes.add('status');
                    if (remoteProject.customDisplayName != localProject.customDisplayName) changes.add('displayName');
                    if (remoteProject.hidden != localProject.hidden) changes.add('hidden');
                    print('    ~ Updated project metadata: ${remoteProject.displayName} (${changes.join(", ")})');
                    
                    if (kDebugMode) {
                      print('      ✓ Project saved and notification triggered for: ${remoteProject.displayName}');
                    }
                  }
                } else {
                  // No metadata changes - but still check if preview song needs to be downloaded
                  // This is important for mobile apps that might not have the preview song file yet
                  String? previewSongPath = localProject.previewSongPath;
                  String? previewSongFileName = localProject.previewSongFileName;
                  String? uploadedPreviewSongHash = localProject.uploadedPreviewSongHash;
                  
                  // Check if preview song exists in backup
                  if (previewSongFiles != null && previewSongFiles.containsKey(remoteProject.id)) {
                    try {
                      final driveFileId = previewSongFiles[remoteProject.id] as String;
                      
                      // Get original filename and hash if available
                      String? originalFileName;
                      String? expectedHash;
                      if (previewSongFileNames != null && previewSongFileNames.containsKey(remoteProject.id)) {
                        originalFileName = previewSongFileNames[remoteProject.id] as String;
                      }
                      if (previewSongHashes != null && previewSongHashes.containsKey(remoteProject.id)) {
                        expectedHash = previewSongHashes[remoteProject.id] as String;
                      }
                      
                      if (downloadPreviewSongs) {
                        // On mobile, only download preview songs after backup is downloaded
                        // Check if we need to download (if path is Drive reference or hash changed)
                        bool needsDownload = false;
                        
                        // First, check if file exists locally (especially on mobile)
                        if (previewSongPath != null && !_isDriveFileReference(previewSongPath)) {
                          // Path exists and is not a Drive reference - check if file actually exists
                          final localFile = File(previewSongPath);
                          if (await localFile.exists()) {
                            // File exists locally - verify hash if we have expected hash
                            if (expectedHash != null) {
                              try {
                                final localHash = await _calculateFileHash(previewSongPath);
                                if (localHash == expectedHash) {
                                  // Hash matches - no download needed
                                  if (kDebugMode) {
                                    print('    Preview song already exists locally with matching hash for: ${localProject.displayName}');
                                  }
                                  needsDownload = false;
                                } else {
                                  // Hash mismatch - need to re-download
                                  if (kDebugMode) {
                                    print('    Preview song hash mismatch (local: $localHash, expected: $expectedHash) for: ${localProject.displayName}, will re-download');
                                  }
                                  needsDownload = true;
                                }
                              } catch (e) {
                                if (kDebugMode) {
                                  print('    Error checking local file hash: $e, will re-download');
                                }
                                needsDownload = true;
                              }
                            } else {
                              // No expected hash - check if local hash matches project hash
                              if (localProject.uploadedPreviewSongHash != null) {
                                try {
                                  final localHash = await _calculateFileHash(previewSongPath);
                                  if (localHash == localProject.uploadedPreviewSongHash) {
                                    // Local hash matches project hash - no download needed
                                    if (kDebugMode) {
                                      print('    Preview song already exists locally with matching hash for: ${localProject.displayName}');
                                    }
                                    needsDownload = false;
                                  } else {
                                    // Hash mismatch - need to re-download
                                    needsDownload = true;
                                  }
                                } catch (e) {
                                  needsDownload = true;
                                }
                              } else {
                                // No hash to compare - assume file is valid if it exists
                                needsDownload = false;
                              }
                            }
                          } else {
                            // Path exists but file doesn't - need to download
                            needsDownload = true;
                          }
                        } else if (previewSongPath == null || _isDriveFileReference(previewSongPath)) {
                          // No local path or Drive reference - need to download
                          needsDownload = true;
                        } else if (expectedHash != null && uploadedPreviewSongHash != expectedHash) {
                          // Hash changed - need to download
                          needsDownload = true;
                        }
                        
                        if (needsDownload) {
                          String? fileExtension;
                          if (originalFileName != null) {
                            fileExtension = path.extension(originalFileName);
                          }
                          
                          final localFilePath = await downloadPreviewSongFile(
                            driveFileId: driveFileId,
                            projectId: remoteProject.id,
                            expectedHash: expectedHash,
                            fileExtension: fileExtension,
                          );
                          
                          if (localFilePath != null) {
                            previewSongPath = localFilePath;
                            previewSongFileName = originalFileName;
                            uploadedPreviewSongHash = expectedHash;
                            
                            // Update project with downloaded file path
                            final updatedProject = localProject.copyWith(
                              previewSongPath: previewSongPath,
                              previewSongFileName: previewSongFileName,
                              uploadedPreviewSongHash: uploadedPreviewSongHash,
                              updatedAt: DateTime.now(),
                            );
                            await profileProjectsBox.put(updatedProject.id, updatedProject);
                            await profileProjectsBox.flush();
                            
                            if (kDebugMode) {
                              print('    Downloaded preview song for project: ${localProject.displayName} (ID: $driveFileId)');
                            }
                          } else {
                            // Download failed, store Drive reference as fallback
                            previewSongPath = _createDriveFileReference(driveFileId);
                            previewSongFileName = originalFileName;
                            uploadedPreviewSongHash = expectedHash;
                            
                            final updatedProject = localProject.copyWith(
                              previewSongPath: previewSongPath,
                              previewSongFileName: previewSongFileName,
                              uploadedPreviewSongHash: uploadedPreviewSongHash,
                              updatedAt: DateTime.now(),
                            );
                            await profileProjectsBox.put(updatedProject.id, updatedProject);
                            await profileProjectsBox.flush();
                            
                            if (kDebugMode) {
                              print('    Download failed, stored Drive reference for: ${localProject.displayName}');
                            }
                          }
                        } else {
                          // File already downloaded and hash matches, just update filename/hash if needed
                          if (originalFileName != previewSongFileName || expectedHash != uploadedPreviewSongHash) {
                            final updatedProject = localProject.copyWith(
                              previewSongFileName: originalFileName ?? previewSongFileName,
                              uploadedPreviewSongHash: expectedHash ?? uploadedPreviewSongHash,
                              updatedAt: DateTime.now(),
                            );
                            await profileProjectsBox.put(updatedProject.id, updatedProject);
                            await profileProjectsBox.flush();
                            
                            if (kDebugMode) {
                              print('    Updated preview song metadata for: ${localProject.displayName}');
                            }
                          }
                        }
                      } else {
                        // Skip download, store Drive reference
                        previewSongPath = _createDriveFileReference(driveFileId);
                        previewSongFileName = originalFileName;
                        uploadedPreviewSongHash = expectedHash;
                        
                        // Only update if it's different from current path or filename
                        if (previewSongPath != localProject.previewSongPath || originalFileName != previewSongFileName || expectedHash != uploadedPreviewSongHash) {
                          final updatedProject = localProject.copyWith(
                            previewSongPath: previewSongPath,
                            previewSongFileName: previewSongFileName,
                            uploadedPreviewSongHash: uploadedPreviewSongHash,
                            updatedAt: DateTime.now(),
                          );
                          await profileProjectsBox.put(updatedProject.id, updatedProject);
                          await profileProjectsBox.flush();
                          
                          if (kDebugMode) {
                            print('    Skipped preview song download, stored Drive reference for: ${localProject.displayName} (ID: $driveFileId)');
                          }
                        }
                      }
                    } catch (e) {
                      if (kDebugMode) {
                        print('    Error updating preview song for project ${remoteProject.id}: $e');
                      }
                    }
                  }
                  
                  if (kDebugMode) {
                    print('    = No metadata changes: ${localProject.displayName}');
                  }
                }
              }
            }
          }
          
          // Force box to notify listeners by doing a dummy update on modified projects
          // This ensures Hive streams detect the changes even after batch updates
          if (profileProjectsUpdated > 0 && profileProjectsBox.isNotEmpty) {
            // Touch all modified projects to trigger notifications
            // This ensures the stream emits for the projects that were actually changed
            final modifiedProjectIds = <String>{};
            for (final remoteProject in remoteProjects) {
              if (profileProjectIds.contains(remoteProject.id)) {
                final localProject = profileProjectsBox.get(remoteProject.id);
                if (localProject != null && _hasMetadataChanged(remoteProject, localProject)) {
                  modifiedProjectIds.add(remoteProject.id);
                }
              }
            }
            
            // Touch each modified project to trigger stream notifications
            for (final projectId in modifiedProjectIds) {
              final project = profileProjectsBox.get(projectId);
              if (project != null) {
                await profileProjectsBox.put(projectId, project);
                if (kDebugMode) {
                  print('      Triggered notification for modified project: ${project.displayName}');
                }
              }
            }
          } else if (profileProjectsBox.isNotEmpty && profileProjectsAdded > 0) {
            // If only new projects were added, touch the first one to trigger notification
            final firstProject = profileProjectsBox.values.first;
            await profileProjectsBox.put(firstProject.id, firstProject);
          }
          
          // CRITICAL: Flush the box to ensure all changes are persisted to disk
          // This is especially important when switching profiles, as the box might be closed
          await profileProjectsBox.flush();
          
          if (kDebugMode) {
            print('  Profile ${profile.name}: ${profileProjectsBox.length} projects (+$profileProjectsAdded ~$profileProjectsUpdated)');
            print('  Box flushed to disk for profile ${profile.name}');
          }
        } catch (e) {
          if (kDebugMode) print('Error merging projects for profile ${profile.id}: $e');
        }
      }
    }

    // Merge releases - distribute to CORRECT profiles (or ALL if no mappings)
    if (remoteData['releases'] != null) {
      final remoteReleases = (remoteData['releases'] as List)
          .map((r) => _deserializeRelease(r as Map<String, dynamic>))
          .toList();
      
      // If we have profile mappings, use them; otherwise distribute to all profiles (backward compatibility)
      final targetProfiles = releaseToProfileMap != null 
          ? allProfiles.where((p) => profileToReleases.containsKey(p.id)).toList()
          : allProfiles;
      
      for (final profile in targetProfiles) {
        try {
          final profileReleasesBox = await Hive.openBox<Release>('${profile.id}_releases');
          int profileReleasesAdded = 0;
          int profileReleasesUpdated = 0;
          
          // Get releases that belong to this profile
          final profileReleaseIds = releaseToProfileMap != null
              ? (profileToReleases[profile.id] ?? [])
              : remoteReleases.map((r) => r.id).toList(); // All releases if no mapping
          
          for (final remoteRelease in remoteReleases) {
            // Only process if this release belongs to this profile (or all if no mapping)
            if (profileReleaseIds.contains(remoteRelease.id)) {
              final localRelease = profileReleasesBox.get(remoteRelease.id);
              
              if (localRelease == null) {
                // New release from remote
                await profileReleasesBox.put(remoteRelease.id, remoteRelease);
                releasesAdded++;
                profileReleasesAdded++;
                if (kDebugMode) {
                  print('    + Added new release: ${remoteRelease.title}');
                }
              } else {
                // For releases, we compare based on content changes
                // Since Release doesn't have updatedAt, we check if content changed
                final hasChanges = remoteRelease.title != localRelease.title ||
                    remoteRelease.description != localRelease.description ||
                    remoteRelease.releaseDate != localRelease.releaseDate ||
                    remoteRelease.artworkImagePath != localRelease.artworkImagePath ||
                    remoteRelease.trackIds.length != localRelease.trackIds.length ||
                    !_listEquals(remoteRelease.trackIds, localRelease.trackIds) ||
                    remoteRelease.todos.length != localRelease.todos.length ||
                    remoteRelease.files.length != localRelease.files.length;
                
                if (hasChanges) {
                  // Content changed - update (remote takes precedence for releases)
                  // This ensures changes from Android (todos, description, etc.) sync back to desktop
                  await profileReleasesBox.put(remoteRelease.id, remoteRelease);
                  releasesUpdated++;
                  profileReleasesUpdated++;
                  if (kDebugMode) {
                    final changes = <String>[];
                    if (remoteRelease.title != localRelease.title) changes.add('title');
                    if (remoteRelease.description != localRelease.description) changes.add('description');
                    if (remoteRelease.todos.length != localRelease.todos.length) {
                      changes.add('todos (${remoteRelease.todos.length} vs ${localRelease.todos.length})');
                    }
                    if (remoteRelease.trackIds.length != localRelease.trackIds.length) {
                      changes.add('tracks (${remoteRelease.trackIds.length} vs ${localRelease.trackIds.length})');
                    }
                    print('    ~ Updated release: ${remoteRelease.title} (${changes.join(", ")})');
                  }
                } else {
                  // No changes - skip
                  if (kDebugMode) {
                    print('    = No change needed: ${localRelease.title}');
                  }
                }
              }
            }
          }
          
          // Force box to notify listeners by doing a dummy update on the first release
          // This ensures Hive streams detect the changes even after batch updates
          if (profileReleasesBox.isNotEmpty) {
            final firstRelease = profileReleasesBox.values.first;
            // Touch the box to trigger notifications - this will cause the stream to emit
            await profileReleasesBox.put(firstRelease.id, firstRelease);
            if (kDebugMode) {
              print('  Profile ${profile.name}: ${profileReleasesBox.length} releases (+$profileReleasesAdded ~$profileReleasesUpdated)');
            }
          }
        } catch (e) {
          if (kDebugMode) print('Error merging releases for profile ${profile.id}: $e');
        }
      }
    }

    // Merge roots - distribute to CORRECT profiles (or ALL if no mappings)
    if (remoteData['roots'] != null) {
      final remoteRoots = (remoteData['roots'] as List)
          .map((r) => _deserializeRoot(r as Map<String, dynamic>))
          .toList();
      
      // If we have profile mappings, use them; otherwise distribute to all profiles (backward compatibility)
      final targetProfiles = rootToProfileMap != null 
          ? allProfiles.where((p) => profileToRoots.containsKey(p.id)).toList()
          : allProfiles;
      
      for (final profile in targetProfiles) {
        try {
          final profileRootsBox = await Hive.openBox<ScanRoot>('${profile.id}_roots');
          
          // Get roots that belong to this profile
          final profileRootIds = rootToProfileMap != null
              ? (profileToRoots[profile.id] ?? [])
              : remoteRoots.map((r) => r.id).toList(); // All roots if no mapping
          
          for (final remoteRoot in remoteRoots) {
            // Only process if this root belongs to this profile (or all if no mapping)
            if (profileRootIds.contains(remoteRoot.id)) {
              final localRoot = profileRootsBox.get(remoteRoot.id);
              if (localRoot == null) {
                // New root from remote
                await profileRootsBox.put(remoteRoot.id, remoteRoot);
              }
            }
          }
          
          if (kDebugMode) {
            print('  Profile ${profile.name}: ${profileRootsBox.length} roots');
          }
        } catch (e) {
          if (kDebugMode) print('Error merging roots for profile ${profile.id}: $e');
        }
      }
    }

    if (kDebugMode) {
      print('Merge completed:');
      print('  Profiles: merged from backup');
      print('  Projects: +$projectsAdded ~$projectsUpdated');
      print('  Releases: +$releasesAdded ~$releasesUpdated');
    }

    return SyncResult(
      projectsAdded: projectsAdded,
      projectsUpdated: projectsUpdated,
      releasesAdded: releasesAdded,
      releasesUpdated: releasesUpdated,
    );
  }

  // Serialization helpers
  Map<String, dynamic> _serializeProfile(Profile profile) {
    return {
      'id': profile.id,
      'name': profile.name,
      'createdAt': profile.createdAt.toIso8601String(),
      'lastUsedAt': profile.lastUsedAt?.toIso8601String(),
      'photoPath': profile.photoPath,
      'bio': profile.bio,
      'artworkPath': profile.artworkPath,
      'pressKitPath': profile.pressKitPath,
      'additionalAssets': profile.additionalAssets,
      'artworkPaths': profile.artworkPaths,
      'pressKitPaths': profile.pressKitPaths,
    };
  }

  Profile _deserializeProfile(Map<String, dynamic> data) {
    return Profile(
      id: data['id'] as String,
      name: data['name'] as String,
      createdAt: DateTime.parse(data['createdAt'] as String),
      lastUsedAt: data['lastUsedAt'] != null 
          ? DateTime.parse(data['lastUsedAt'] as String)
          : null,
      photoPath: data['photoPath'] as String?,
      bio: data['bio'] as String?,
      artworkPath: data['artworkPath'] as String?,
      pressKitPath: data['pressKitPath'] as String?,
      additionalAssets: data['additionalAssets'] != null
          ? Map<String, String>.from(data['additionalAssets'] as Map)
          : null,
      artworkPaths: data['artworkPaths'] != null
          ? List<String>.from(data['artworkPaths'] as List)
          : null,
      pressKitPaths: data['pressKitPaths'] != null
          ? List<String>.from(data['pressKitPaths'] as List)
          : null,
    );
  }

  Map<String, dynamic> _serializeProject(MusicProject project) {
    return {
      'id': project.id,
      'filePath': project.filePath,
      'fileName': project.fileName,
      'fileSizeBytes': project.fileSizeBytes,
      'lastModifiedAt': project.lastModifiedAt.toIso8601String(),
      'customDisplayName': project.customDisplayName,
      'thumbnailPath': project.thumbnailPath,
      'status': project.status,
      'fileExtension': project.fileExtension,
      'createdAt': project.createdAt.toIso8601String(),
      'updatedAt': project.updatedAt.toIso8601String(),
      'bpm': project.bpm,
      'musicalKey': project.musicalKey,
      'notes': project.notes,
      'dawType': project.dawType,
      'dawVersion': project.dawVersion,
      'todos': project.todos.map((t) => {
        'id': t.id,
        'text': t.text,
        'completed': t.completed,
        'createdAt': t.createdAt.toIso8601String(),
      }).toList(),
      'hidden': project.hidden,
      'previewSongPath': project.previewSongPath,
      'previewSongFileName': project.previewSongFileName,
      'previewSongHash': project.uploadedPreviewSongHash, // Keep 'previewSongHash' key in JSON for backward compatibility
      'fileCreatedAt': project.fileCreatedAt?.toIso8601String(),
      'statusChangedAt': project.statusChangedAt?.toIso8601String(),
      'deadline': project.deadline?.toIso8601String(),
    };
  }

  MusicProject _deserializeProject(Map<String, dynamic> data) {
    return MusicProject(
      id: data['id'] as String,
      filePath: data['filePath'] as String,
      fileName: data['fileName'] as String,
      fileSizeBytes: data['fileSizeBytes'] as int,
      lastModifiedAt: DateTime.parse(data['lastModifiedAt'] as String),
      customDisplayName: data['customDisplayName'] as String?,
      thumbnailPath: data['thumbnailPath'] as String?,
      status: data['status'] as String,
      fileExtension: data['fileExtension'] as String,
      createdAt: DateTime.parse(data['createdAt'] as String),
      updatedAt: DateTime.parse(data['updatedAt'] as String),
      bpm: (data['bpm'] as num?)?.toDouble(),
      musicalKey: data['musicalKey'] as String?,
      notes: data['notes'] as String?,
      dawType: data['dawType'] as String?,
      dawVersion: data['dawVersion'] as String?,
      todos: (data['todos'] as List?)?.map((t) => TodoItem(
        id: t['id'] as String,
        text: t['text'] as String,
        completed: t['completed'] as bool? ?? false,
        createdAt: DateTime.parse(t['createdAt'] as String),
      )).toList() ?? const [],
      hidden: data['hidden'] as bool? ?? false,
      previewSongPath: data['previewSongPath'] as String?,
      previewSongFileName: data['previewSongFileName'] as String?,
      uploadedPreviewSongHash: data['previewSongHash'] as String?, // Keep 'previewSongHash' key in JSON for backward compatibility
      fileCreatedAt: data['fileCreatedAt'] != null
          ? DateTime.parse(data['fileCreatedAt'] as String)
          : null,
      statusChangedAt: data['statusChangedAt'] != null
          ? DateTime.parse(data['statusChangedAt'] as String)
          : null,
      deadline: data['deadline'] != null
          ? DateTime.parse(data['deadline'] as String)
          : null,
    );
  }

  Map<String, dynamic> _serializeRelease(Release release) {
    return {
      'id': release.id,
      'title': release.title,
      'releaseDate': release.releaseDate?.toIso8601String(),
      'artworkImagePath': release.artworkImagePath,
      'description': release.description,
      'trackIds': release.trackIds,
      'files': release.files.map((f) => {
        'id': f.id,
        'fileName': f.fileName,
        'filePath': f.filePath,
        'fileType': f.fileType,
        'fileSizeBytes': f.fileSizeBytes,
        'addedAt': f.addedAt.toIso8601String(),
        'description': f.description,
      }).toList(),
      'todos': release.todos.map((t) => {
        'id': t.id,
        'text': t.text,
        'completed': t.completed,
        'createdAt': t.createdAt.toIso8601String(),
      }).toList(),
    };
  }

  Release _deserializeRelease(Map<String, dynamic> data) {
    return Release(
      id: data['id'] as String,
      title: data['title'] as String,
      releaseDate: data['releaseDate'] != null
          ? DateTime.parse(data['releaseDate'] as String)
          : null,
      artworkImagePath: data['artworkImagePath'] as String?,
      description: data['description'] as String?,
      trackIds: List<String>.from(data['trackIds'] as List),
      files: (data['files'] as List?)?.map((f) => ReleaseFile(
        id: f['id'] as String,
        fileName: f['fileName'] as String,
        filePath: f['filePath'] as String,
        fileType: f['fileType'] as String,
        fileSizeBytes: f['fileSizeBytes'] as int,
        addedAt: DateTime.parse(f['addedAt'] as String),
        description: f['description'] as String?,
      )).toList() ?? const [],
      todos: (data['todos'] as List?)?.map((t) => TodoItem(
        id: t['id'] as String,
        text: t['text'] as String,
        completed: t['completed'] as bool,
        createdAt: DateTime.parse(t['createdAt'] as String),
      )).toList() ?? const [],
    );
  }

  Map<String, dynamic> _serializeRoot(ScanRoot root) {
    return {
      'id': root.id,
      'path': root.path,
      'addedAt': root.addedAt.toIso8601String(),
      'lastScanAt': root.lastScanAt?.toIso8601String(),
    };
  }

  ScanRoot _deserializeRoot(Map<String, dynamic> data) {
    return ScanRoot(
      id: data['id'] as String,
      path: data['path'] as String,
      addedAt: DateTime.parse(data['addedAt'] as String),
      lastScanAt: data['lastScanAt'] != null
          ? DateTime.parse(data['lastScanAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> _serializeTemplate(TodoTemplate template) {
    return {
      'id': template.id,
      'name': template.name,
      'items': template.items,
      'createdAt': template.createdAt.toIso8601String(),
      'updatedAt': template.updatedAt.toIso8601String(),
    };
  }

  TodoTemplate _deserializeTemplate(Map<String, dynamic> data) {
    return TodoTemplate(
      id: data['id'] as String,
      name: data['name'] as String,
      items: (data['items'] as List<dynamic>).cast<String>(),
      createdAt: DateTime.parse(data['createdAt'] as String),
      updatedAt: DateTime.parse(data['updatedAt'] as String),
    );
  }
}

/// Custom HTTP client that adds Google authentication headers to requests
/// Custom HTTP client that adds authentication headers to requests
/// Similar to GoogleHttpClient pattern from flutter_gdrive repository
/// This wraps a base http.Client and adds auth headers from GoogleSignIn
class _AuthenticatedHttpClient extends http.BaseClient {
  final http.Client _inner;
  final Map<String, String> _headers;

  _AuthenticatedHttpClient(this._inner, this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    // Add authentication headers to the request
    // This follows the same pattern as GoogleHttpClient in flutter_gdrive
    _headers.forEach((key, value) {
      request.headers[key] = value;
    });
    return _inner.send(request);
  }

  @override
  Future<http.Response> head(Object url, {Map<String, String>? headers}) {
    final mergedHeaders = <String, String>{..._headers};
    if (headers != null) {
      mergedHeaders.addAll(headers);
    }
    // Convert url to Uri if it's a String
    final uri = url is Uri ? url : Uri.parse(url.toString());
    return _inner.head(uri, headers: mergedHeaders);
  }

  @override
  void close() {
    _inner.close();
  }
}

/// Result of a sync operation
class SyncResult {
  final int projectsAdded;
  final int projectsUpdated;
  final int releasesAdded;
  final int releasesUpdated;

  SyncResult({
    required this.projectsAdded,
    required this.projectsUpdated,
    required this.releasesAdded,
    required this.releasesUpdated,
  });
}

