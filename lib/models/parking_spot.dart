class ParkingSpot {
  final double latitude;
  final double longitude;
  final DateTime savedAt;
  final String? photoPath;
  final DateTime? timerEnd;
  final String? address;

  ParkingSpot({
    required this.latitude,
    required this.longitude,
    required this.savedAt,
    this.photoPath,
    this.timerEnd,
    this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'savedAt': savedAt.toIso8601String(),
      'photoPath': photoPath,
      'timerEnd': timerEnd?.toIso8601String(),
      'address': address,
    };
  }

  factory ParkingSpot.fromJson(Map<String, dynamic> json) {
    return ParkingSpot(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      savedAt: DateTime.parse(json['savedAt'] as String),
      photoPath: json['photoPath'] as String?,
      timerEnd: json['timerEnd'] != null 
          ? DateTime.parse(json['timerEnd'] as String)
          : null,
      address: json['address'] as String?,
    );
  }

  String get coordinates => '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}

