import 'shocker.dart';

class DeviceWithShockers {
  final String id;
  final String name;
  final DateTime createdOn;
  final List<Shocker> shockers;
  final bool isOnline;
  final String? firmwareVersion;

  DeviceWithShockers({
    required this.id,
    required this.name,
    required this.createdOn,
    required this.shockers,
    this.isOnline = false,
    this.firmwareVersion,
  });

  factory DeviceWithShockers.fromJson(Map<String, dynamic> json) {
    return DeviceWithShockers(
      id: json['id'] as String,
      name: json['name'] as String,
      createdOn: DateTime.parse(json['createdOn'] as String),
      shockers: (json['shockers'] as List<dynamic>?)
              ?.map((s) => Shocker.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdOn': createdOn.toIso8601String(),
      'shockers': shockers.map((s) => s.toJson()).toList(),
      'isOnline': isOnline,
      'firmwareVersion': firmwareVersion,
    };
  }

  DeviceWithShockers copyWith({
    String? id,
    String? name,
    DateTime? createdOn,
    List<Shocker>? shockers,
    bool? isOnline,
    String? firmwareVersion,
  }) {
    return DeviceWithShockers(
      id: id ?? this.id,
      name: name ?? this.name,
      createdOn: createdOn ?? this.createdOn,
      shockers: shockers ?? this.shockers,
      isOnline: isOnline ?? this.isOnline,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
    );
  }
}
