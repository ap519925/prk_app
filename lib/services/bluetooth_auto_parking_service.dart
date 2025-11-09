// Auto-Parking via Bluetooth presence (BLE) detection
// Uses flutter_blue_plus to observe a chosen BLE device's presence.
// When the device was recently seen and then disappears (disconnect surrogate),
// we automatically save a parking spot using current GPS, fetch alerts, and notify.

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/parking_spot.dart';
import '../models/parking_alert.dart';
import '../services/location_service.dart';
import '../services/parking_alerts_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

class BluetoothAutoParkingService {
  static final BluetoothAutoParkingService instance =
      BluetoothAutoParkingService._();
  BluetoothAutoParkingService._();

  // Pref keys
  static const _kEnabledKey = 'auto_parking_bt_enabled';
  static const _kDeviceIdKey = 'auto_parking_bt_device_id';
  static const _kDeviceNameKey = 'auto_parking_bt_device_name';

  // Runtime state
  bool _monitoring = false;
  String? _selectedDeviceId;
  String? _selectedDeviceName;

  Timer? _scanTimer;
  DateTime? _lastSeenSelected;
  DateTime? _lastAutoParkTrigger;
  final Duration _scanInterval = const Duration(seconds: 12);
  final Duration _presenceTimeout = const Duration(seconds: 45);
  final Duration _retriggerCooldown = const Duration(minutes: 15);

  // Public stream for UI updates
  final StreamController<BluetoothAutoParkingStatus> _statusCtrl =
      StreamController.broadcast();
  Stream<BluetoothAutoParkingStatus> get statusStream => _statusCtrl.stream;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_kEnabledKey) ?? false;
    _selectedDeviceId = prefs.getString(_kDeviceIdKey);
    _selectedDeviceName = prefs.getString(_kDeviceNameKey);
    if (enabled && _selectedDeviceId != null) {
      await startMonitoring();
    } else {
      _emitStatus();
    }
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabledKey, enabled);
    if (enabled) {
      await startMonitoring();
    } else {
      await stopMonitoring();
    }
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kEnabledKey) ?? false;
  }

  bool get isMonitoring => _monitoring;

  String? get selectedDeviceId => _selectedDeviceId;
  String? get selectedDeviceName => _selectedDeviceName;

  Future<void> setSelectedDevice({
    required String deviceId,
    required String deviceName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDeviceIdKey, deviceId);
    await prefs.setString(_kDeviceNameKey, deviceName);
    _selectedDeviceId = deviceId;
    _selectedDeviceName = deviceName;
    _emitStatus();

    // Auto-start monitoring if feature already enabled
    try {
      if (await isEnabled()) {
        await startMonitoring();
      }
    } catch (_) {
      // Swallow to avoid disrupting UI; status stream will surface errors
    }
  }

  Future<List<BluetoothDeviceInfo>> scanForDevices(
      {Duration timeout = const Duration(seconds: 6)}) async {
    final supported = await FlutterBluePlus.isSupported;
    if (!supported) {
      _statusCtrl.add(BluetoothAutoParkingStatus(
        enabled: await isEnabled(),
        monitoring: _monitoring,
        selectedDeviceId: _selectedDeviceId,
        selectedDeviceName: _selectedDeviceName,
        adapterState: BluetoothAdapterState.unknown,
        lastSeen: _lastSeenSelected,
        error: 'Bluetooth not supported on this device',
      ));
      return [];
    }

    // Ensure adapter on
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      _emitStatus();
      return [];
    }

    List<BluetoothDeviceInfo> results = [];
    final subs = <StreamSubscription>[];

    try {
      // Start scan
      await FlutterBluePlus.startScan(timeout: timeout);

      final sub =
          FlutterBluePlus.onScanResults.listen((List<ScanResult> rlist) {
        for (final r in rlist) {
          final id = r.device.remoteId.str;
          final name = r.advertisementData.advName.isNotEmpty
              ? r.advertisementData.advName
              : r.device.platformName;
          // Avoid duplicates
          if (results.indexWhere((e) => e.id == id) == -1) {
            results.add(BluetoothDeviceInfo(
              id: id,
              name: name.isNotEmpty ? name : 'Unknown',
              rssi: r.rssi,
            ));
          }
          // Track presence for selected device
          if (_selectedDeviceId != null && id == _selectedDeviceId) {
            _lastSeenSelected = DateTime.now();
            _emitStatus();
          }
        }
      });
      subs.add(sub);

      // Wait for timeout
      await Future.delayed(timeout);
    } finally {
      await FlutterBluePlus.stopScan();
      for (final s in subs) {
        await s.cancel();
      }
    }

    // Sort by strongest signal
    results.sort((a, b) => (b.rssi ?? -999).compareTo(a.rssi ?? -999));
    return results;
  }

  Future<void> startMonitoring() async {
    if (_monitoring) return;
    final enabled = await isEnabled();
    if (!enabled) {
      await setEnabled(true);
    }
    if (_selectedDeviceId == null) {
      _emitStatus(error: 'No Bluetooth device selected');
      return;
    }

    final supported = await FlutterBluePlus.isSupported;
    if (!supported) {
      _emitStatus(error: 'Bluetooth not supported on this device');
      return;
    }

    // Permissions
    final ok = await _ensurePermissions();
    if (!ok) {
      _emitStatus(error: 'Bluetooth/Location permissions denied');
      return;
    }

    _monitoring = true;
    _emitStatus();

    // Kick off recurring scans to detect presence/absence
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(_scanInterval, (_) async {
      try {
        await _monitorOnce();
      } catch (e) {
        _emitStatus(error: 'Monitor error: $e');
      }
    });

    // Also run immediately
    await _monitorOnce();
  }

  Future<void> stopMonitoring() async {
    _monitoring = false;
    _scanTimer?.cancel();
    _scanTimer = null;
    _emitStatus();
  }

  Future<void> _monitorOnce() async {
    if (!_monitoring || _selectedDeviceId == null) return;

    // Skip if adapter off
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      _emitStatus(error: 'Bluetooth adapter is off');
      return;
    }

    // Ensure permissions
    final ok = await _ensurePermissions();
    if (!ok) {
      _emitStatus(error: 'Bluetooth/Location permissions denied');
      return;
    }

    final now = DateTime.now();
    // Quick visibility scan (short)
    const timeout = Duration(seconds: 5);
    await FlutterBluePlus.startScan(timeout: timeout);

    final sub = FlutterBluePlus.onScanResults.listen((List<ScanResult> rlist) {
      for (final r in rlist) {
        if (r.device.remoteId.str == _selectedDeviceId) {
          _lastSeenSelected = DateTime.now();
        }
      }
    });

    await Future.delayed(timeout);
    await FlutterBluePlus.stopScan();
    await sub.cancel();

    // Evaluate presence -> absence transition
    final lastSeen = _lastSeenSelected;
    final recentlySeen =
        lastSeen != null && now.difference(lastSeen) <= _presenceTimeout;
    if (!recentlySeen && lastSeen != null) {
      // It used to be around, now considered "disconnected"
      await _maybeTriggerAutoParking();
    }

    _emitStatus();
  }

  Future<void> _maybeTriggerAutoParking() async {
    // Cooldown to avoid repeated triggers
    final now = DateTime.now();
    if (_lastAutoParkTrigger != null &&
        now.difference(_lastAutoParkTrigger!) < _retriggerCooldown) {
      return;
    }

    // Grab current position
    final pos = await LocationService.instance.getCurrentLocation();
    if (pos == null) {
      _emitStatus(error: 'Location unavailable for auto-parking');
      return;
    }

    // Fetch alerts (city/state included inside)
    final alertsResp = await ParkingAlertsService.instance.getParkingAlerts(
      pos.latitude,
      pos.longitude,
    );

    final address = await LocationService.instance.getAddressFromCoordinates(
      pos.latitude,
      pos.longitude,
    );

    final spot = ParkingSpot(
      latitude: pos.latitude,
      longitude: pos.longitude,
      savedAt: DateTime.now(),
      address: address,
      alerts: alertsResp.alerts,
      city: alertsResp.city,
      state: alertsResp.state,
    );

    await StorageService.instance.saveParkingSpot(spot);
    _lastAutoParkTrigger = now;

    // Notify user
    await NotificationService.instance.showParkingAlert(
      // Construct a pseudo alert summary for notification UI
      ParkingAlert(
        id: 'auto_bt_${now.millisecondsSinceEpoch}',
        type: ParkingAlertType.other,
        title: 'Auto-saved Parking Spot',
        description: _selectedDeviceName != null
            ? 'Saved when "${_selectedDeviceName!}" disconnected'
            : 'Saved via Bluetooth auto-parking',
        isActive: true,
        source: 'Bluetooth',
      ),
    );

    // Also show alert summary if any alerts found
    if (alertsResp.alerts.isNotEmpty) {
      await NotificationService.instance.showAlertSummary(alertsResp.alerts);
    }

    // Emit status for UI
    _emitStatus();
  }

  void _emitStatus({String? error}) async {
    final enabled = await isEnabled();
    BluetoothAdapterState adapterState = BluetoothAdapterState.unknown;
    try {
      adapterState = await FlutterBluePlus.adapterState.first
          .timeout(const Duration(milliseconds: 300));
    } catch (_) {}
    _statusCtrl.add(
      BluetoothAutoParkingStatus(
        enabled: enabled,
        monitoring: _monitoring,
        selectedDeviceId: _selectedDeviceId,
        selectedDeviceName: _selectedDeviceName,
        adapterState: adapterState,
        lastSeen: _lastSeenSelected,
        error: error,
      ),
    );
  }

  Future<void> dispose() async {
    _scanTimer?.cancel();
    await _statusCtrl.close();
  }

  Future<bool> _ensurePermissions() async {
    try {
      if (Platform.isAndroid) {
        // Android 12+ needs BLUETOOTH_SCAN/CONNECT; legacy needs location for BLE
        final req = <Permission>[
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.locationWhenInUse,
        ];
        final statuses = await req.request();
        return statuses.values.every((s) => s.isGranted);
      } else if (Platform.isIOS) {
        // iOS BLE + nearby location for stronger behavior
        final req = <Permission>[
          Permission.bluetooth,
          Permission.locationWhenInUse,
        ];
        final statuses = await req.request();
        return statuses.values.every((s) => s.isGranted);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}

class BluetoothDeviceInfo {
  final String id;
  final String name;
  final int? rssi;
  BluetoothDeviceInfo({required this.id, required this.name, this.rssi});
}

class BluetoothAutoParkingStatus {
  final bool enabled;
  final bool monitoring;
  final String? selectedDeviceId;
  final String? selectedDeviceName;
  final BluetoothAdapterState adapterState;
  final DateTime? lastSeen;
  final String? error;

  BluetoothAutoParkingStatus({
    required this.enabled,
    required this.monitoring,
    required this.selectedDeviceId,
    required this.selectedDeviceName,
    required this.adapterState,
    required this.lastSeen,
    this.error,
  });

  String get adapterLabel {
    switch (adapterState) {
      case BluetoothAdapterState.on:
        return 'On';
      case BluetoothAdapterState.off:
        return 'Off';
      default:
        return describeEnum(adapterState);
    }
  }
}
