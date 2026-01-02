import 'shocker_permissions.dart';
import 'shocker_limits.dart';

class SharedShocker {
  final String id;
  final String name;
  final bool isPaused;
  final ShockerPermissions permissions;
  final ShockerLimits limits;

  SharedShocker({
    required this.id,
    required this.name,
    required this.isPaused,
    required this.permissions,
    required this.limits,
  });

  factory SharedShocker.fromJson(Map<String, dynamic> json) {
    return SharedShocker(
      id: json['id'] as String,
      name: json['name'] as String,
      isPaused: json['isPaused'] as bool,
      permissions: ShockerPermissions.fromJson(
        json['permissions'] as Map<String, dynamic>,
      ),
      limits: ShockerLimits.fromJson(
        json['limits'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isPaused': isPaused,
      'permissions': permissions.toJson(),
      'limits': limits.toJson(),
    };
  }
}
