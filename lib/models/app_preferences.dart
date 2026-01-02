import 'dart:convert';

/// Model for all non-secure app preferences
class AppPreferences {
  final bool rememberMe;
  final String? customHost;
  final bool onboardingComplete;

  AppPreferences({
    this.rememberMe = false,
    this.customHost,
    this.onboardingComplete = false,
  });

  factory AppPreferences.fromJson(Map<String, dynamic> json) {
    return AppPreferences(
      rememberMe: json['rememberMe'] as bool? ?? false,
      customHost: json['customHost'] as String?,
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rememberMe': rememberMe,
      'customHost': customHost,
      'onboardingComplete': onboardingComplete,
    };
  }

  AppPreferences copyWith({
    bool? rememberMe,
    String? customHost,
    bool? onboardingComplete,
  }) {
    return AppPreferences(
      rememberMe: rememberMe ?? this.rememberMe,
      customHost: customHost ?? this.customHost,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory AppPreferences.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return AppPreferences.fromJson(json);
  }

  static AppPreferences defaults() {
    return AppPreferences();
  }
}
