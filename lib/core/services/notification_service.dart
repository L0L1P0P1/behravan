import 'dart:developer';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        log('Notification action tapped: ${response.actionId} with payload ${response.payload}');
        // Handle actions: voiding_success, voiding_snooze, voiding_accident
        if (response.actionId != null) {
          handleNotificationAction(response.actionId!, response.payload);
        }
      },
    );

    _initialized = true;
  }

  Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }
  }

  Future<void> scheduleVoidingReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await init();
    try {
      const androidDetails = AndroidNotificationDetails(
        'voiding_reminders',
        'Timed Voiding Alarms',
        channelDescription: 'Reminders for timed voiding routine',
        importance: Importance.max,
        priority: Priority.high,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'voiding_success',
            'Peed Successfully',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'voiding_snooze',
            'Snooze 10m',
            showsUserInterface: false,
          ),
          AndroidNotificationAction(
            'voiding_accident',
            'Had Accident',
            showsUserInterface: true,
          ),
        ],
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'voiding_reminder',
      );
      log('Scheduled voiding reminder at $scheduledTime');
    } catch (e) {
      log('Error scheduling notification: $e');
    }
  }

  Future<void> scheduleMorningEnuresisPrompt() async {
    await init();
    // Daily at 07:30 AM
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 7, 30);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'enuresis_prompts',
      'Morning Enuresis Check',
      channelDescription: 'Daily prompt to log dry/wet morning status',
      importance: Importance.high,
      priority: Priority.high,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      9999,
      '🌅 Morning Dry Night Check',
      'How was last night? Tap to log enuresis status.',
      scheduledDate,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'enuresis_prompt',
    );
  }

  void handleNotificationAction(String actionId, String? payload) {
    // Actions are handled in app or via callbacks
    log('Action received: $actionId');
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
