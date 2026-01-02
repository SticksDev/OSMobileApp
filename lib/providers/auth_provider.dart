import 'package:flutter/foundation.dart';

import '../models/login_request.dart';
import '../models/self_user.dart';
import '../services/api_client.dart';
import '../services/storage_service.dart';
import '../utils/logger.dart';

enum AuthState { initial, loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  static const _tag = 'AuthProvider';

  final ApiClient _apiClient;
  final StorageService _storageService;

  AuthState _authState = AuthState.initial;
  String? _error;
  SelfUser? _selfUser;

  AuthProvider({
    required ApiClient apiClient,
    required StorageService storageService,
  }) : _apiClient = apiClient,
       _storageService = storageService;

  AuthState get authState => _authState;
  String? get error => _error;
  bool get isAuthenticated => _authState == AuthState.authenticated;
  bool get isLoading => _authState == AuthState.loading;
  SelfUser? get selfUser => _selfUser;

  String get currentHost => _apiClient.baseUrl;

  Future<void> initialize() async {
    Logger.log('Initializing authentication', tag: _tag);
    _setState(AuthState.loading, clearError: true);

    try {
      await _applyStoredHostIfAny();

      final cookieJar = await _apiClient.cookieJar;
      final cookies = await cookieJar.loadForRequest(
        Uri.parse(_apiClient.baseUrl),
      );

      // First, check if we have saved session cookies
      if (cookies.isNotEmpty) {
        Logger.log(
          'Found saved session cookies, validating session',
          tag: _tag,
        );

        // Try to validate the session using getSelf
        final selfResponse = await _apiClient.getSelf();
        if (selfResponse.isSuccess && selfResponse.data != null) {
          Logger.log('Session is valid, user authenticated', tag: _tag);
          _selfUser = selfResponse.data;
          _setState(AuthState.authenticated);
          return;
        }

        Logger.log(
          'Session validation failed, cookies may be expired',
          tag: _tag,
        );
      }

      // If no valid session, check for saved credentials
      final rememberMe = await _storageService.getRememberMe();
      if (rememberMe) {
        final credentials = await _storageService.getCredentials();
        if (credentials != null) {
          Logger.log(
            'Found saved credentials, attempting auto-login',
            tag: _tag,
          );

          await loginWithCredentials(
            credentials['email']!,
            credentials['password']!,
            rememberMe: true,
          );
          return;
        }
      }

      Logger.log(
        'No saved session or credentials, user needs to login',
        tag: _tag,
      );
      _setState(AuthState.unauthenticated);
    } catch (e, stackTrace) {
      _error = 'Failed to initialize: $e';
      Logger.error(
        'Initialization failed',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      _setState(AuthState.unauthenticated);
    }
  }

  Future<bool> loginWithCredentials(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    final trimmedEmail = email.trim();

    Logger.log('loginWithCredentials called for $trimmedEmail', tag: _tag);
    _setState(AuthState.loading, clearError: true);

    try {
      // 1) Login to set a session cookie.
      Logger.log('Calling API login', tag: _tag);
      final loginResponse = await _apiClient.login(
        LoginRequest(email: trimmedEmail, password: password),
      );

      Logger.log(
        'Login response success: ${loginResponse.isSuccess}',
        tag: _tag,
      );

      if (!loginResponse.isSuccess) {
        _error = loginResponse.error;
        Logger.error('Login failed: $_error', tag: _tag);
        _setState(AuthState.unauthenticated);
        return false;
      }

      // 2) Fetch self user data and validate session
      Logger.log('Fetching self user data', tag: _tag);
      final selfResponse = await _apiClient.getSelf();
      if (!selfResponse.isSuccess || selfResponse.data == null) {
        _error = 'Failed to fetch user data';
        Logger.error('Failed to fetch self user data', tag: _tag);
        _setState(AuthState.unauthenticated);
        return false;
      }

      _selfUser = selfResponse.data;

      // 4) Persist remember-me choice + credentials.
      await _persistRememberMe(
        rememberMe: rememberMe,
        email: trimmedEmail,
        password: password,
      );

      Logger.log('Login successful', tag: _tag);
      _setState(AuthState.authenticated);
      return true;
    } catch (e, stackTrace) {
      _error = 'Login failed: $e';
      Logger.error(
        'Login exception: $_error',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      _setState(AuthState.unauthenticated);
      return false;
    }
  }

  Future<void> logout() async {
    Logger.log('Logging out user', tag: _tag);
    _setState(AuthState.loading, clearError: true);

    try {
      await _apiClient.logout();
    } catch (e) {
      Logger.log(
        'Logout API call failed, continuing with local logout',
        tag: _tag,
      );
      // Intentionally ignore logout errors.
    }

    await _storageService.clearSecrets();
    await _storageService.saveRememberMe(
      false,
    ); // optional but keeps state consistent

    _selfUser = null;
    Logger.log('Logout complete', tag: _tag);
    _setState(AuthState.unauthenticated, clearError: true);
  }

  Future<void> setCustomHost(String host) async {
    final trimmed = host.trim();
    Logger.log('Setting custom host: $trimmed', tag: _tag);

    await _storageService.saveCustomHost(trimmed);
    await _apiClient.setBaseUrl(trimmed);
  }

  Future<void> _applyStoredHostIfAny() async {
    final customHost = await _storageService.getCustomHost();
    if (customHost == null || customHost.isEmpty) return;

    Logger.log('Using custom host: $customHost', tag: _tag);
    await _apiClient.setBaseUrl(customHost);
  }

  Future<void> _persistRememberMe({
    required bool rememberMe,
    required String email,
    required String password,
  }) async {
    Logger.log('Remember me: $rememberMe', tag: _tag);

    if (rememberMe) {
      await _storageService.saveCredentials(email, password);
      await _storageService.saveRememberMe(true);
      return;
    }

    // Keep preference accurate and make sure secrets are cleared.
    await _storageService.saveRememberMe(false);
    await _storageService.clearSecrets();
  }

  void _setState(AuthState state, {bool clearError = false}) {
    _authState = state;
    if (clearError) _error = null;
    notifyListeners();
  }
}
