enum ParkingAlertType {
  streetCleaning,
  meteredParking,
  timeLimitedZone,
  permitOnly,
  snowEmergency,
  noParking,
  other,
}

class ParkingAlert {
  final String id;
  final ParkingAlertType type;
  final String title;
  final String description;
  final DateTime? expiresAt;
  final String? dayOfWeek;
  final String? timeRange;
  final bool isActive;
  final String? source;

  ParkingAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.expiresAt,
    this.dayOfWeek,
    this.timeRange,
    this.isActive = true,
    this.source,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'description': description,
      'expiresAt': expiresAt?.toIso8601String(),
      'dayOfWeek': dayOfWeek,
      'timeRange': timeRange,
      'isActive': isActive,
      'source': source,
    };
  }

  factory ParkingAlert.fromJson(Map<String, dynamic> json) {
    return ParkingAlert(
      id: json['id'] as String,
      type: ParkingAlertType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ParkingAlertType.other,
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      dayOfWeek: json['dayOfWeek'] as String?,
      timeRange: json['timeRange'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      source: json['source'] as String?,
    );
  }

  String get emoji {
    switch (type) {
      case ParkingAlertType.streetCleaning:
        return '🧹';
      case ParkingAlertType.meteredParking:
        return '💰';
      case ParkingAlertType.timeLimitedZone:
        return '⏱️';
      case ParkingAlertType.permitOnly:
        return '🎫';
      case ParkingAlertType.snowEmergency:
        return '❄️';
      case ParkingAlertType.noParking:
        return '🚫';
      default:
        return '⚠️';
    }
  }

  String get severityColor {
    switch (type) {
      case ParkingAlertType.noParking:
      case ParkingAlertType.snowEmergency:
        return 'error'; // Uses theme color scheme.error (red)
      case ParkingAlertType.streetCleaning:
      case ParkingAlertType.meteredParking:
        return 'tertiary'; // Uses theme color scheme.tertiary (orange)
      case ParkingAlertType.timeLimitedZone:
      case ParkingAlertType.permitOnly:
        return 'secondary'; // Uses theme color scheme.secondary (slate gray)
      default:
        return 'primary'; // Uses theme color scheme.primary (teal)
    }
  }
}

class ParkingRulesResponse {
  final List<ParkingAlert> alerts;
  final String? city;
  final String? state;
  final bool hasActiveRestrictions;

  ParkingRulesResponse({
    required this.alerts,
    this.city,
    this.state,
    this.hasActiveRestrictions = false,
  });
}
