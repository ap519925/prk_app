import 'package:shared_preferences/shared_preferences.dart';

/// Enums for settings
enum LocationAccuracy {
  low('Low Power'),
  balanced('Balanced'),
  high('High Accuracy');

  const LocationAccuracy(this.displayName);
  final String displayName;
}

enum MapStyle {
  standard('Standard'),
  satellite('Satellite'),
  terrain('Terrain');

  const MapStyle(this.displayName);
  final String displayName;
}

/// Settings Service for managing app preferences
class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String _themeModeKey = 'theme_mode';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _soundEffectsEnabledKey = 'sound_effects_enabled';
  static const String _locationAccuracyKey = 'location_accuracy';
  static const String _navigationVoiceKey = 'navigation_voice';
  static const String _mapStyleKey = 'map_style';

  late SharedPreferences _prefs;

  /// Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Theme Mode Settings
  bool get isDarkMode {
    return _prefs.getBool(_themeModeKey) ?? true; // Default to dark mode
  }

  Future<void> setThemeMode(bool isDark) async {
    await _prefs.setBool(_themeModeKey, isDark);
  }

  // Notifications Settings
  bool get areNotificationsEnabled {
    return _prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(_notificationsEnabledKey, enabled);
  }

  // Sound Effects Settings
  bool get areSoundEffectsEnabled {
    return _prefs.getBool(_soundEffectsEnabledKey) ?? true;
  }

  Future<void> setSoundEffectsEnabled(bool enabled) async {
    await _prefs.setBool(_soundEffectsEnabledKey, enabled);
  }

  // Location Accuracy Settings
  LocationAccuracy get locationAccuracy {
    final value = _prefs.getString(_locationAccuracyKey) ?? 'balanced';
    return LocationAccuracy.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LocationAccuracy.balanced,
    );
  }

  Future<void> setLocationAccuracy(LocationAccuracy accuracy) async {
    await _prefs.setString(_locationAccuracyKey, accuracy.name);
  }

  // Navigation Voice Settings
  bool get isNavigationVoiceEnabled {
    return _prefs.getBool(_navigationVoiceKey) ?? true;
  }

  Future<void> setNavigationVoiceEnabled(bool enabled) async {
    await _prefs.setBool(_navigationVoiceKey, enabled);
  }

  // Map Style Settings
  MapStyle get mapStyle {
    final value = _prefs.getString(_mapStyleKey) ?? 'standard';
    return MapStyle.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MapStyle.standard,
    );
  }

  Future<void> setMapStyle(MapStyle style) async {
    await _prefs.setString(_mapStyleKey, style.name);
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    await _prefs.clear();
  }

  /// Get all settings as a map
  Map<String, dynamic> getAllSettings() {
    return {
      'theme_mode': isDarkMode,
      'notifications_enabled': areNotificationsEnabled,
      'sound_effects_enabled': areSoundEffectsEnabled,
      'location_accuracy': locationAccuracy.name,
      'navigation_voice_enabled': isNavigationVoiceEnabled,
      'map_style': mapStyle.name,
    };
  }
}
