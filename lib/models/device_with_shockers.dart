import 'shocker.dart';

class DeviceWithShockers {
  final String id;
  final String name;
  final DateTime createdOn;
  final List<Shocker> shockers;

  DeviceWithShockers({
    required this.id,
    required this.name,
    required this.createdOn,
    required this.shockers,
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
    };
  }
}
