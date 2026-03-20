import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Possible outcomes of a Google Sign-In attempt.
enum AuthResult { success, invalidDomain, cancelled, error }

/// Lightweight model for the currently authenticated user.
class AuthUser {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final String role;
  final bool setupComplete;

  const AuthUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    this.role = 'USER',
    this.setupComplete = false,
  });

  bool get isAdmin => role == 'ADMIN' || role == 'SUPER_ADMIN';

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'role': role,
        'setupComplete': setupComplete,
      };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        uid: json['uid'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String? ?? '',
        photoUrl: json['photoUrl'] as String? ?? '',
        role: json['role'] as String? ?? 'USER',
        setupComplete: json['setupComplete'] as bool? ?? false,
      );
}

/// Application-wide authentication service backed by [GoogleSignIn].
///
/// Validates that the signed-in user belongs to the `@neu.edu.ph` domain.
/// Exposes [isSignedIn] / [currentUser] and notifies listeners on changes.
///
/// Persists the JWT and user data in [SharedPreferences] so sessions survive
/// page refreshes on web.
class AuthService extends ChangeNotifier {
  static const _allowedDomain = 'neu.edu.ph';
  static const _tokenKey = 'jwt_token';
  static const _userKey = 'auth_user';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '691398845872-8f2so0ocj1pnql7laesvoklrdo5nod0u.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );
  final ApiService apiService;

  AuthService(this.apiService);

  AuthUser? _currentUser;

  /// The currently authenticated user, or `null` if signed out.
  AuthUser? get currentUser => _currentUser;

  /// Whether a user is currently signed in.
  bool get isSignedIn => _currentUser != null;

  String? _lastError;

  /// Human-readable description of the last error, if any.
  String? get lastError => _lastError;

  /// Try to restore a previously saved session from local storage.
  /// Call this once on app startup (e.g. in main.dart or a splash screen).
  Future<bool> tryRestoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final userJson = prefs.getString(_userKey);

      if (token == null || userJson == null) return false;

      // Restore the JWT and user data.
      apiService.setToken(token);

      // Validate the token is still valid by calling /api/users/me.
      try {
        final profile = await apiService.getProfile();
        _currentUser = AuthUser(
          uid: (profile['id'] as num).toString(),
          email: profile['email'] as String,
          displayName: profile['fullName'] as String? ?? '',
          photoUrl: profile['photoUrl'] as String? ?? '',
          role: profile['role'] as String? ?? 'USER',
          setupComplete: profile['setupComplete'] as bool? ?? false,
        );

        // Update cached user data with latest from server.
        await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
        notifyListeners();
        debugPrint('[AuthService] Session restored for ${_currentUser!.email}');
        return true;
      } catch (e) {
        // Token expired or invalid — clear everything.
        debugPrint('[AuthService] Stored token invalid, clearing session: $e');
        await _clearStorage();
        apiService.clear();
        return false;
      }
    } catch (e) {
      debugPrint('[AuthService] Failed to restore session: $e');
      return false;
    }
  }

  /// Attempt Google Sign-In and validate the email domain.
  Future<AuthResult> signInWithGoogle() async {
    _lastError = null;
    try {
      debugPrint('[AuthService] Starting Google Sign-In…');
      final account = await _googleSignIn.signIn();

      if (account == null) {
        debugPrint('[AuthService] Sign-in returned null (user cancelled)');
        return AuthResult.cancelled;
      }

      debugPrint('[AuthService] Signed in as: ${account.email}');
      debugPrint('[AuthService] Display name : ${account.displayName}');
      debugPrint('[AuthService] ID           : ${account.id}');
      debugPrint('[AuthService] Photo URL    : ${account.photoUrl}');

      // Domain validation — only @neu.edu.ph emails are allowed.
      if (!account.email.endsWith('@$_allowedDomain')) {
        debugPrint('[AuthService] Domain rejected: ${account.email}');
        await _googleSignIn.signOut();
        _lastError = 'Domain not allowed: ${account.email}';
        return AuthResult.invalidDomain;
      }

      debugPrint('[AuthService] Domain OK — authenticating with backend');

      // Obtain tokens from the Google Sign-In result.
      final authentication = await account.authentication;
      final idToken = authentication.idToken;
      final accessToken = authentication.accessToken;

      // On web, signIn() uses the GIS OAuth2 Token Client which only
      // returns an access token — never an ID token.  We send whichever
      // token is available; the backend accepts both.
      if (idToken == null && accessToken == null) {
        _lastError = 'Could not obtain any Google token';
        return AuthResult.error;
      }

      debugPrint('[AuthService] idToken: ${idToken != null ? "present" : "null"}, '
          'accessToken: ${accessToken != null ? "present" : "null"}');

      // Exchange the Google token for our app JWT.
      final response = await apiService.authenticateWithGoogle(
        idToken: idToken,
        accessToken: accessToken,
      );
      final token = response['token'] as String;
      final user = response['user'] as Map<String, dynamic>;

      apiService.setToken(token);

      _currentUser = AuthUser(
        uid: (user['id'] as num).toString(),
        email: user['email'] as String,
        displayName: user['fullName'] as String? ?? '',
        photoUrl: user['photoUrl'] as String? ?? '',
        role: user['role'] as String? ?? 'USER',
        setupComplete: user['setupComplete'] as bool? ?? false,
      );

      // Persist the session.
      await _saveSession(token);

      notifyListeners();
      return AuthResult.success;
    } catch (e, stackTrace) {
      debugPrint('[AuthService] ERROR: $e');
      debugPrint('[AuthService] Stack trace:\n$stackTrace');
      _lastError = e.toString();
      return AuthResult.error;
    }
  }

  /// Sign the current user out and clear local state.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    apiService.clear();
    _currentUser = null;
    await _clearStorage();
    notifyListeners();
  }

  /// Persist the JWT and user data to local storage.
  Future<void> _saveSession(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (_currentUser != null) {
      await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
    }
  }

  /// Remove persisted session data.
  Future<void> _clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
