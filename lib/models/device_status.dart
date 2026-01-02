class DeviceStatus {
  final String deviceId;
  final bool online;
  final String? firmwareVersion;

  DeviceStatus({
    required this.deviceId,
    required this.online,
    this.firmwareVersion,
  });

  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    return DeviceStatus(
      deviceId: json['device'] as String,
      online: json['online'] as bool? ?? false,
      firmwareVersion: json['firmwareVersion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device': deviceId,
      'online': online,
      'firmwareVersion': firmwareVersion,
    };
  }
}
