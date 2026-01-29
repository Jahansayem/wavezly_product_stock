class PinSetupModel {
  final String pin;
  final DateTime createdAt;

  const PinSetupModel({
    required this.pin,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'pin': pin,
        'created_at': createdAt.toIso8601String(),
      };

  factory PinSetupModel.fromJson(Map<String, dynamic> json) {
    return PinSetupModel(
      pin: json['pin'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // For secure storage (hash the PIN before saving)
  // TODO: Implement proper PIN hashing (e.g., using crypto package)
  String get hashedPin {
    // Placeholder - should use proper hashing in production
    return pin;
  }
}
