class ShockerPermissions {
  final bool vibrate;
  final bool sound;
  final bool shock;
  final bool live;

  ShockerPermissions({
    required this.vibrate,
    required this.sound,
    required this.shock,
    required this.live,
  });

  factory ShockerPermissions.fromJson(Map<String, dynamic> json) {
    return ShockerPermissions(
      vibrate: json['vibrate'] as bool,
      sound: json['sound'] as bool,
      shock: json['shock'] as bool,
      live: json['live'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vibrate': vibrate,
      'sound': sound,
      'shock': shock,
      'live': live,
    };
  }
}
