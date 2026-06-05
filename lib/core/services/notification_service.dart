import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// A premium, highly reliable service to manage local notifications.
/// Handles Android 13+ & iOS permissions and schedules recurring daily mental check reminders.
class NotificationService {
  // Singleton pattern for application-wide easy access
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initializes the local notification service, registers channels,
  /// and automatically schedules the daily mental health check reminder.
  Future<void> initialize() async {
    // 1. Initialize timezones (essential for scheduling recurring alerts at specific hours)
    tz.initializeTimeZones();

    // 2. Android Initialization Settings
    // Uses default app icon. Make sure @mipmap/ic_launcher exists in your Android resources.
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. iOS/Darwin Initialization Settings
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false, // Requested explicitly via requestPermissions()
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    // 4. Initialize the plugin
    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Can be used to navigate to AddMoodScreen upon tapping
      },
    );

    // 5. Schedule the daily 21:00 check-in reminder
    await scheduleDailyReminder();
  }

  /// Requests permission to display notifications explicitly for Android 13+ (API 33+) and iOS.
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _localNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final bool? granted = await androidImplementation.requestNotificationsPermission();
        return granted ?? false;
      }
    } else if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          _localNotificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        final bool? granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    }
    return false;
  }

  /// Schedules a recurring notification daily at 21:00 (9:00 PM)
  Future<void> scheduleDailyReminder() async {
    const int notificationId = 101; // Unique ID for our daily mental health reminder

    // Set up Android specific notification channel details
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'daily_reminder_channel_id',
      'Nhắc Nhở Hàng Ngày',
      channelDescription: 'Kênh gửi thông báo nhắc nhở chăm sóc sức khỏe tinh thần lúc 21:00',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    // Set up iOS notification details
    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    // Calculate the next occurrence of 21:00 (9:00 PM) in local timezone
    final tz.TZDateTime scheduledTime = _nextInstanceOfNinePM();

    await _localNotificationsPlugin.zonedSchedule(
      notificationId,
      'MindMirror 🧠',
      'Đã đến lúc dành 1 phút cho bản thân. Hôm nay của bạn thế nào?',
      scheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Enforces daily recurrence
    );
  }

  /// Calculates the next TZDateTime instance of 21:00 (9:00 PM)
  tz.TZDateTime _nextInstanceOfNinePM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 21, 0, 0);
    
    // If 21:00 has already passed today, schedule it for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Cancels the scheduled daily reminder
  Future<void> cancelDailyReminder() async {
    await _localNotificationsPlugin.cancel(101);
  }
}
