import 'shared_device.dart';

class SharedUser {
  final String id;
  final String name;
  final String? image;
  final List<SharedDevice> devices;

  SharedUser({
    required this.id,
    required this.name,
    this.image,
    required this.devices,
  });

  factory SharedUser.fromJson(Map<String, dynamic> json) {
    final devicesList = json['devices'] as List<dynamic>;
    return SharedUser(
      id: json['id'] as String,
      name: json['name'] as String,
      image: json['image'] as String?,
      devices: devicesList
          .map((item) => SharedDevice.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'devices': devices.map((d) => d.toJson()).toList(),
    };
  }
}
