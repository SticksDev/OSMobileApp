class ShockerLimits {
  final int? intensity;
  final int? duration;

  ShockerLimits({
    this.intensity,
    this.duration,
  });

  factory ShockerLimits.fromJson(Map<String, dynamic> json) {
    return ShockerLimits(
      intensity: json['intensity'] as int?,
      duration: json['duration'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'intensity': intensity,
      'duration': duration,
    };
  }
}
