import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/parking_alert.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    // Android initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for iOS
    await _requestPermissions();

    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    final androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    final iosImplementation = _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    print('Notification tapped: ${response.payload}');
  }

  /// Show immediate notification for parking alerts
  Future<void> showParkingAlert(ParkingAlert alert) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'parking_alerts',
      'Parking Alerts',
      channelDescription: 'Notifications for parking restrictions and rules',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      alert.id.hashCode,
      '${alert.emoji} ${alert.title}',
      alert.description,
      notificationDetails,
      payload: alert.id,
    );
  }

  /// Schedule a notification for a specific time
  Future<void> scheduleParkingReminder({
    required DateTime scheduledTime,
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();

    final scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'parking_reminders',
      'Parking Reminders',
      channelDescription: 'Reminders for parking expiration and time limits',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      scheduledTime.millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Schedule notifications for parking timer expiration
  Future<void> scheduleTimerNotifications({
    required DateTime expirationTime,
    String? locationDescription,
  }) async {
    await initialize();

    final location = locationDescription ?? 'your parking spot';

    // Cancel existing timer notifications
    await cancelTimerNotifications();

    // Notification 15 minutes before expiration
    final fifteenMinBefore = expirationTime.subtract(const Duration(minutes: 15));
    if (fifteenMinBefore.isAfter(DateTime.now())) {
      await scheduleParkingReminder(
        scheduledTime: fifteenMinBefore,
        title: '⏱️ Parking Time Alert',
        body: '15 minutes remaining at $location',
        payload: 'timer_15min',
      );
    }

    // Notification 5 minutes before expiration
    final fiveMinBefore = expirationTime.subtract(const Duration(minutes: 5));
    if (fiveMinBefore.isAfter(DateTime.now())) {
      await scheduleParkingReminder(
        scheduledTime: fiveMinBefore,
        title: '⚠️ Parking Time Almost Up',
        body: '5 minutes remaining at $location',
        payload: 'timer_5min',
      );
    }

    // Notification at expiration
    if (expirationTime.isAfter(DateTime.now())) {
      await scheduleParkingReminder(
        scheduledTime: expirationTime,
        title: '🚫 Parking Time Expired',
        body: 'Your parking time at $location has expired!',
        payload: 'timer_expired',
      );
    }
  }

  /// Schedule notifications for parking alerts based on time restrictions
  Future<void> scheduleAlertNotifications(
    List<ParkingAlert> alerts,
    String? locationDescription,
  ) async {
    await initialize();

    final location = locationDescription ?? 'your parking location';

    for (final alert in alerts) {
      if (alert.expiresAt != null && alert.expiresAt!.isAfter(DateTime.now())) {
        // Schedule notification 30 minutes before restriction starts
        final notificationTime = alert.expiresAt!.subtract(const Duration(minutes: 30));
        
        if (notificationTime.isAfter(DateTime.now())) {
          await scheduleParkingReminder(
            scheduledTime: notificationTime,
            title: '${alert.emoji} ${alert.title}',
            body: '${alert.description} starting soon at $location',
            payload: alert.id,
          );
        }

        // Schedule notification at restriction time
        await scheduleParkingReminder(
          scheduledTime: alert.expiresAt!,
          title: '🚫 ${alert.title}',
          body: 'Parking restriction now in effect at $location',
          payload: '${alert.id}_active',
        );
      }
    }
  }

  /// Cancel all timer-related notifications
  Future<void> cancelTimerNotifications() async {
    // Cancel specific timer notification IDs
    final now = DateTime.now();
    final baseId = now.millisecondsSinceEpoch ~/ 1000;
    
    // Try to cancel potential timer notifications
    for (var i = 0; i < 100; i++) {
      await _notifications.cancel(baseId + i);
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Show a summary notification with all active alerts
  Future<void> showAlertSummary(List<ParkingAlert> alerts) async {
    if (alerts.isEmpty) return;

    await initialize();

    final activeAlerts = alerts.where((a) => a.isActive).toList();
    if (activeAlerts.isEmpty) return;

    final title = activeAlerts.length == 1
        ? '${activeAlerts.first.emoji} Parking Alert'
        : '⚠️ ${activeAlerts.length} Parking Alerts';

    final body = activeAlerts.length == 1
        ? activeAlerts.first.description
        : '${activeAlerts.map((a) => a.title).join(", ")}';

    const androidDetails = AndroidNotificationDetails(
      'parking_summary',
      'Parking Summary',
      channelDescription: 'Summary of all parking restrictions at your location',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999999, // Fixed ID for summary
      title,
      body,
      notificationDetails,
    );
  }
}

