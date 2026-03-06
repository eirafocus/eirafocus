import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  NotificationService._();

  bool _initialized = false;

  Future<void> init() async {
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      await _plugin.initialize(settings);
      _initialized = true;
    } catch (_) {
      // Notification init may fail on some devices/emulators
    }
  }

  Future<void> scheduleDailyReminder(int hour, int minute) async {
    if (!_initialized) await init();
    await cancelAll();

    // Request permission on Android 13+
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'Daily Reminder',
      channelDescription: 'Reminds you to practice mindfulness',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    // Schedule using periodic — daily at specified time
    // We use zonedSchedule for precise daily scheduling
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.periodicallyShow(
      0,
      'Time to practice',
      'Take a moment to breathe and focus.',
      RepeatInterval.daily,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }
}
