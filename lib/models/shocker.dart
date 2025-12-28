class Shocker {
  final String id;
  final String name;
  final String? rfId;
  final String? model;
  final DateTime createdOn;
  final bool isPaused;

  Shocker({
    required this.id,
    required this.name,
    this.rfId,
    this.model,
    required this.createdOn,
    required this.isPaused,
  });

  factory Shocker.fromJson(Map<String, dynamic> json) {
    return Shocker(
      id: json['id'] as String,
      name: json['name'] as String,
      rfId: json['rfId'] as String?,
      model: json['model'] as String?,
      createdOn: DateTime.parse(json['createdOn'] as String),
      isPaused: json['isPaused'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rfId': rfId,
      'model': model,
      'createdOn': createdOn.toIso8601String(),
      'isPaused': isPaused,
    };
  }
}
