import 'dart:convert';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/device_with_shockers.dart';
import '../models/login_request.dart';
import '../models/self_user.dart';
import '../models/shared_user.dart';
import '../utils/logger.dart';

class ApiClient {
  static const String defaultBaseUrl = 'https://api.openshock.app';

  static const _cookieStorageKey = 'session_cookies';
  static const _tag = 'ApiClient';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  late final Dio _dio;
  late CookieJar _cookieJar;

  String _baseUrl;
  bool _initialized = false;

  ApiClient({String? baseUrl}) : _baseUrl = baseUrl ?? defaultBaseUrl;

  String get baseUrl => _baseUrl;

  Future<CookieJar> get cookieJar async {
    await _ensureInitialized();
    return _cookieJar;
  }

  Future<void> setBaseUrl(String baseUrl) async {
    _baseUrl = baseUrl;
    await _ensureInitialized();

    // Make sure Dio uses the updated base URL.
    _dio.options.baseUrl = _baseUrl;
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    _cookieJar = CookieJar();
    _initializeDio();
    await _loadCookiesFromSecureStorage();

    _initialized = true;
  }

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // Cookie manager handles session cookies automatically.
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  // -------------------------
  // Cookies (secure storage)
  // -------------------------

  Future<void> _loadCookiesFromSecureStorage() async {
    try {
      final cookiesJson = await _secureStorage.read(key: _cookieStorageKey);
      if (cookiesJson == null || cookiesJson.isEmpty) return;

      final decoded = jsonDecode(cookiesJson);
      if (decoded is! List) return;

      final uri = Uri.parse(_baseUrl);

      final cookies = decoded
          .whereType<Map<String, dynamic>>()
          .map(_cookieFromJson)
          .toList();

      await _cookieJar.saveFromResponse(uri, cookies);

      Logger.log(
        'Loaded ${cookies.length} cookies from secure storage',
        tag: _tag,
      );
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to load cookies from secure storage',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Cookie _cookieFromJson(Map<String, dynamic> json) {
    return Cookie(json['name'] as String? ?? '', json['value'] as String? ?? '')
      ..domain = json['domain'] as String?
      ..path = json['path'] as String?
      ..expires = (json['expires'] is String)
          ? DateTime.tryParse(json['expires'] as String)
          : null
      ..secure = json['secure'] as bool? ?? false
      ..httpOnly = json['httpOnly'] as bool? ?? false;
  }

  Future<void> _saveCookiesToSecureStorage() async {
    try {
      final uri = Uri.parse(_baseUrl);
      final cookies = await _cookieJar.loadForRequest(uri);

      if (cookies.isEmpty) {
        Logger.log('No cookies to save; clearing secure storage', tag: _tag);
        await _secureStorage.delete(key: _cookieStorageKey);
        return;
      }

      final cookiesList = cookies.map(_cookieToJson).toList();
      await _secureStorage.write(
        key: _cookieStorageKey,
        value: jsonEncode(cookiesList),
      );

      Logger.log(
        'Saved ${cookies.length} cookies to secure storage',
        tag: _tag,
      );
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to save cookies to secure storage',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Map<String, dynamic> _cookieToJson(Cookie cookie) => {
    'name': cookie.name,
    'value': cookie.value,
    'domain': cookie.domain,
    'path': cookie.path,
    'expires': cookie.expires?.toIso8601String(),
    'secure': cookie.secure,
    'httpOnly': cookie.httpOnly,
  };

  // -------------------------
  // API calls
  // -------------------------

  Future<ApiResponse<void>> login(LoginRequest request) async {
    await _ensureInitialized();

    try {
      final response = await _dio.post(
        '/1/account/login',
        data: request.toJson(),
      );

      Logger.log('Login response status: ${response.statusCode}', tag: _tag);

      if (response.statusCode == 200) {
        await _saveCookiesToSecureStorage();
        return ApiResponse.success(null);
      }

      if (response.statusCode == 401) {
        return ApiResponse.error('Invalid email or password');
      }

      if (response.statusCode == 403) {
        return ApiResponse.error('Access forbidden');
      }

      return ApiResponse.error('Login failed: ${response.statusMessage}');
    } on DioException catch (e) {
      Logger.error(
        'Login DioException',
        tag: _tag,
        error: e,
        stackTrace: e.stackTrace,
      );
      return ApiResponse.error(_handleDioError(e));
    } catch (e, stackTrace) {
      Logger.error(
        'Login unexpected error',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResponse.error('An unexpected error occurred: $e');
    }
  }

  Future<ApiResponse<SelfUser>> getSelf() async {
    await _ensureInitialized();

    try {
      Logger.log('Fetching self user', tag: _tag);
      final response = await _dio.get('/1/users/self');

      if (response.statusCode == 200) {
        final data = _extractData(response.data);
        if (data == null) {
          Logger.error('Unexpected response format for self user', tag: _tag);
          return ApiResponse.error('Unexpected response format');
        }

        final selfUser = SelfUser.fromJson(data);
        Logger.log('Loaded self user: ${selfUser.name}', tag: _tag);
        return ApiResponse.success(selfUser);
      }

      if (response.statusCode == 401) {
        Logger.error('Unauthorized when fetching self user', tag: _tag);
        return ApiResponse.error('Unauthorized - please login again');
      }

      Logger.error(
        'Failed to load self user: ${response.statusCode}',
        tag: _tag,
      );
      return ApiResponse.error(
        'Failed to load self user: ${response.statusMessage}',
      );
    } on DioException catch (e) {
      Logger.error(
        'Get self user DioException',
        tag: _tag,
        error: e,
        stackTrace: e.stackTrace,
      );
      return ApiResponse.error(_handleDioError(e));
    } catch (e, stackTrace) {
      Logger.error(
        'Get self user error',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  Future<ApiResponse<List<DeviceWithShockers>>> getOwnShockers() async {
    await _ensureInitialized();

    try {
      Logger.log('Fetching own shockers', tag: _tag);
      final response = await _dio.get('/1/shockers/own');

      if (response.statusCode == 200) {
        final data = _extractListData(response.data);
        if (data == null) {
          Logger.error(
            'Unexpected response format for own shockers',
            tag: _tag,
          );
          return ApiResponse.error('Unexpected response format');
        }

        final devices = data
            .whereType<Map<String, dynamic>>()
            .map(DeviceWithShockers.fromJson)
            .toList();

        Logger.log('Loaded ${devices.length} devices with shockers', tag: _tag);
        return ApiResponse.success(devices);
      }

      if (response.statusCode == 401) {
        Logger.error('Unauthorized when fetching shockers', tag: _tag);
        return ApiResponse.error('Unauthorized - please login again');
      }

      Logger.error(
        'Failed to load shockers: ${response.statusCode}',
        tag: _tag,
      );
      return ApiResponse.error(
        'Failed to load shockers: ${response.statusMessage}',
      );
    } on DioException catch (e) {
      Logger.error(
        'Get own shockers DioException',
        tag: _tag,
        error: e,
        stackTrace: e.stackTrace,
      );
      return ApiResponse.error(_handleDioError(e));
    } catch (e, stackTrace) {
      Logger.error(
        'Get own shockers error',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  Future<ApiResponse<List<SharedUser>>> getSharedShockers() async {
    await _ensureInitialized();

    try {
      Logger.log('Fetching shared shockers', tag: _tag);
      final response = await _dio.get('/1/shockers/shared');

      if (response.statusCode == 200) {
        final data = _extractListData(response.data);
        if (data == null) {
          Logger.error(
            'Unexpected response format for shared shockers',
            tag: _tag,
          );
          return ApiResponse.error('Unexpected response format');
        }

        final sharedUsers = data
            .whereType<Map<String, dynamic>>()
            .map(SharedUser.fromJson)
            .toList();

        Logger.log(
          'Loaded ${sharedUsers.length} shared users with shockers',
          tag: _tag,
        );
        return ApiResponse.success(sharedUsers);
      }

      if (response.statusCode == 401) {
        Logger.error('Unauthorized when fetching shared shockers', tag: _tag);
        return ApiResponse.error('Unauthorized - please login again');
      }

      Logger.error(
        'Failed to load shared shockers: ${response.statusCode}',
        tag: _tag,
      );
      return ApiResponse.error(
        'Failed to load shared shockers: ${response.statusMessage}',
      );
    } on DioException catch (e) {
      Logger.error(
        'Get shared shockers DioException',
        tag: _tag,
        error: e,
        stackTrace: e.stackTrace,
      );
      return ApiResponse.error(_handleDioError(e));
    } catch (e, stackTrace) {
      Logger.error(
        'Get shared shockers error',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  Future<ApiResponse<void>> logout() async {
    await _ensureInitialized();

    try {
      Logger.log('Logging out', tag: _tag);
      final response = await _dio.post('/1/account/logout');

      if (response.statusCode == 200) {
        _cookieJar.deleteAll();
        await _secureStorage.delete(key: _cookieStorageKey);
        Logger.log('Logout successful', tag: _tag);
        return ApiResponse.success(null);
      }

      Logger.error('Logout failed: ${response.statusCode}', tag: _tag);
      return ApiResponse.error('Logout failed: ${response.statusMessage}');
    } on DioException catch (e) {
      Logger.error(
        'Logout DioException',
        tag: _tag,
        error: e,
        stackTrace: e.stackTrace,
      );
      return ApiResponse.error(_handleDioError(e));
    } catch (e, stackTrace) {
      Logger.error('Logout error', tag: _tag, error: e, stackTrace: stackTrace);
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  // -------------------------
  // Helpers
  // -------------------------

  Map<String, dynamic>? _extractData(dynamic responseData) {
    if (responseData is Map<String, dynamic> &&
        responseData.containsKey('data')) {
      final data = responseData['data'];
      if (data is Map<String, dynamic>) return data;
    }

    return null;
  }

  List<dynamic>? _extractListData(dynamic responseData) {
    if (responseData is List<dynamic>) return responseData;

    if (responseData is Map<String, dynamic>) {
      final data = responseData['data'];
      if (data is List<dynamic>) return data;
    }

    return null;
  }

  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.connectionError:
        return 'Cannot connect to server. Please check your internet connection.';
      case DioExceptionType.badResponse:
        return 'Server error: ${e.response?.statusMessage ?? 'Unknown error'}';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      default:
        return 'Network error occurred';
    }
  }
}

class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  ApiResponse._({this.data, this.error, required this.isSuccess});

  factory ApiResponse.success(T? data) {
    return ApiResponse._(data: data, isSuccess: true);
  }

  factory ApiResponse.error(String error) {
    return ApiResponse._(error: error, isSuccess: false);
  }
}
