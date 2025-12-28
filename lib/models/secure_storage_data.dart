import 'dart:convert';

/// Model for all secure storage data (credentials, cookies, etc.)
class SecureStorageData {
  final String? email;
  final String? password;
  final String? sessionCookies;

  SecureStorageData({
    this.email,
    this.password,
    this.sessionCookies,
  });

  factory SecureStorageData.fromJson(Map<String, dynamic> json) {
    return SecureStorageData(
      email: json['email'] as String?,
      password: json['password'] as String?,
      sessionCookies: json['sessionCookies'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'sessionCookies': sessionCookies,
    };
  }

  SecureStorageData copyWith({
    String? email,
    String? password,
    String? sessionCookies,
  }) {
    return SecureStorageData(
      email: email ?? this.email,
      password: password ?? this.password,
      sessionCookies: sessionCookies ?? this.sessionCookies,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory SecureStorageData.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return SecureStorageData.fromJson(json);
  }

  static SecureStorageData empty() {
    return SecureStorageData();
  }
}
