import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_preferences.dart';
import '../models/secure_storage_data.dart';

class StorageService {
  static const String _secureDataKey = 'secure_data';
  static const String _preferencesKey = 'app_preferences';

  final FlutterSecureStorage _secureStorage;
  final SharedPreferences? _prefsOverride;

  // Allows easy testing by injecting mocks.
  StorageService({
    FlutterSecureStorage? secureStorage,
    SharedPreferences? prefs,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _prefsOverride = prefs;

  Future<SharedPreferences> _prefs() async =>
      _prefsOverride ?? SharedPreferences.getInstance();

  // -------------------------
  // Secure storage (secrets)
  // -------------------------

  Future<SecureStorageData> getSecureData() async {
    try {
      final jsonString = await _secureStorage.read(key: _secureDataKey);
      if (jsonString == null || jsonString.isEmpty) {
        return SecureStorageData.empty();
      }
      return SecureStorageData.fromJsonString(jsonString);
    } catch (_) {
      // If parsing or read fails, return empty data.
      return SecureStorageData.empty();
    }
  }

  Future<void> saveSecureData(SecureStorageData data) {
    return _secureStorage.write(
      key: _secureDataKey,
      value: data.toJsonString(),
    );
  }

  Future<void> updateSecureData(
    SecureStorageData Function(SecureStorageData current) update,
  ) async {
    final current = await getSecureData();
    final updated = update(current);
    await saveSecureData(updated);
  }

  Future<void> clearSecureData() {
    return _secureStorage.delete(key: _secureDataKey);
  }

  // -------------------------
  // Shared preferences (non-secrets)
  // -------------------------

  Future<AppPreferences> getPreferences() async {
    try {
      final prefs = await _prefs();
      final jsonString = prefs.getString(_preferencesKey);

      if (jsonString == null || jsonString.isEmpty) {
        return AppPreferences.defaults();
      }

      return AppPreferences.fromJsonString(jsonString);
    } catch (_) {
      // If parsing or read fails, return defaults.
      return AppPreferences.defaults();
    }
  }

  Future<void> savePreferences(AppPreferences preferences) async {
    final prefs = await _prefs();
    await prefs.setString(_preferencesKey, preferences.toJsonString());
  }

  Future<void> updatePreferences(
    AppPreferences Function(AppPreferences current) update,
  ) async {
    final current = await getPreferences();
    final updated = update(current);
    await savePreferences(updated);
  }

  Future<void> clearPreferences() async {
    final prefs = await _prefs();
    await prefs.remove(_preferencesKey);
  }

  // -------------------------
  // Convenience helpers
  // -------------------------

  Future<Map<String, String>?> getCredentials() async {
    final data = await getSecureData();
    final email = data.email;
    final password = data.password;

    if (email == null || password == null) return null;
    return {'email': email, 'password': password};
  }

  Future<void> saveCredentials(String email, String password) {
    return updateSecureData(
      (data) => data.copyWith(email: email, password: password),
    );
  }

  Future<void> clearSecrets() {
    return updateSecureData(
      (data) => data.copyWith(email: null, password: null),
    );
  }

  Future<bool> getRememberMe() async {
    final prefs = await getPreferences();
    return prefs.rememberMe;
  }

  Future<void> saveRememberMe(bool rememberMe) {
    return updatePreferences((prefs) => prefs.copyWith(rememberMe: rememberMe));
  }

  Future<String?> getCustomHost() async {
    final prefs = await getPreferences();
    return prefs.customHost;
  }

  Future<void> saveCustomHost(String host) {
    return updatePreferences((prefs) => prefs.copyWith(customHost: host));
  }

  Future<bool> hasCompletedOnboarding() async {
    final prefs = await getPreferences();
    return prefs.onboardingComplete;
  }

  Future<void> setOnboardingComplete(bool complete) {
    return updatePreferences(
      (prefs) => prefs.copyWith(onboardingComplete: complete),
    );
  }

  Future<void> clearAll() async {
    await clearSecureData();
    await clearPreferences();
  }
}
