import 'parking_alert.dart';

class ParkingSpot {
  final double latitude;
  final double longitude;
  final DateTime savedAt;
  final String? photoPath;
  final DateTime? timerEnd;
  final String? address;
  final List<ParkingAlert>? alerts;
  final String? city;
  final String? state;

  ParkingSpot({
    required this.latitude,
    required this.longitude,
    required this.savedAt,
    this.photoPath,
    this.timerEnd,
    this.address,
    this.alerts,
    this.city,
    this.state,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'savedAt': savedAt.toIso8601String(),
      'photoPath': photoPath,
      'timerEnd': timerEnd?.toIso8601String(),
      'address': address,
      'alerts': alerts?.map((a) => a.toJson()).toList(),
      'city': city,
      'state': state,
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
      alerts: json['alerts'] != null
          ? (json['alerts'] as List).map((a) => ParkingAlert.fromJson(a)).toList()
          : null,
      city: json['city'] as String?,
      state: json['state'] as String?,
    );
  }

  String get coordinates => '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}

