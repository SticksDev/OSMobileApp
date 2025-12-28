import 'shared_shocker.dart';

class SharedDevice {
  final String id;
  final String name;
  final List<SharedShocker> shockers;

  SharedDevice({
    required this.id,
    required this.name,
    required this.shockers,
  });

  factory SharedDevice.fromJson(Map<String, dynamic> json) {
    final shockersList = json['shockers'] as List<dynamic>;
    return SharedDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      shockers: shockersList
          .map((item) => SharedShocker.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'shockers': shockers.map((s) => s.toJson()).toList(),
    };
  }
}
