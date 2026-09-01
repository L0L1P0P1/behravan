import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';
import '../../data/database/app_database.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  if (response.actionId == null) return;
  await NotificationService.instance.handleNotificationAction(
    response.actionId!,
    response.payload,
  );
}

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final _nextAlarmController = StreamController<DateTime?>.broadcast();
  Stream<DateTime?> get nextAlarmStream => _nextAlarmController.stream;
  DateTime? currentNextAlarm;

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
        log(
          'Notification tapped: ${response.actionId} | payload: ${response.payload}',
        );
        if (response.actionId != null) {
          await handleNotificationAction(response.actionId!, response.payload);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Explicit V2 channel with forced sound & high importance
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'voiding_alarms_v2',
      'Timed Voiding High Priority Alarms',
      description: 'Loud reminders for pediatric timed voiding routine',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }
  }

  Future<DateTime?> scheduleDailyVoidingSlots({
    required String scheduleId,
    required String title,
    required String startTime,
    required String endTime,
    required int intervalMinutes,
  }) async {
    await init();
    await cancelScheduleAlarms(scheduleId);

    if (intervalMinutes <= 0) return null;

    final startParts = startTime.split(':').map(int.parse).toList();
    final endParts = endTime.split(':').map(int.parse).toList();

    final now = DateTime.now();
    final startDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      startParts[0],
      startParts[1],
    );
    final endDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      endParts[0],
      endParts[1],
    );

    DateTime nextTargetTime;

    if (now.isBefore(startDateTime)) {
      nextTargetTime = startDateTime;
    } else if (now.isBefore(endDateTime)) {
      nextTargetTime = now.add(Duration(minutes: intervalMinutes));
      if (nextTargetTime.isAfter(endDateTime)) {
        nextTargetTime = startDateTime.add(const Duration(days: 1));
      }
    } else {
      // Testing or late evening override
      if (intervalMinutes <= 30) {
        nextTargetTime = now.add(Duration(minutes: intervalMinutes));
      } else {
        nextTargetTime = startDateTime.add(const Duration(days: 1));
      }
    }

    if (nextTargetTime.difference(now).inSeconds < 2) {
      nextTargetTime = now.add(const Duration(seconds: 4));
    }

    currentNextAlarm = nextTargetTime;
    _nextAlarmController.add(currentNextAlarm);

    final notificationId = (scheduleId.hashCode & 0x7FFFFFFF);

    final androidDetails = AndroidNotificationDetails(
      'voiding_alarms_v2',
      'Timed Voiding High Priority Alarms',
      channelDescription: 'Loud reminders for pediatric timed voiding routine',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'voiding_success',
          'رفتم دستشویی (موفق)',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          'voiding_accident',
          'تصادف / خیس',
          showsUserInterface: false,
        ),
      ],
    );

    final scheduledTZ = tz.TZDateTime.from(nextTargetTime, tz.local);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      '🚽 $title',
      'زمان دستشویی رفتن فرارسیده است!',
      scheduledTZ,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'voiding_slot_$scheduleId',
    );

    return nextTargetTime;
  }

  Future<void> scheduleMorningEnuresisPrompt() async {
    await init();
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      7,
      30,
    );
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
      '🌅 بررسی شب‌ادراری صبحگاهی',
      'دیشب چطور بود؟ وضعیت شب گذشته را ثبت کنید.',
      scheduledDate,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'enuresis_prompt',
    );
  }

  Future<void> resetTimerForActiveSchedules(AppDatabase db) async {
    await init();
    final activeSchedules = await (db.select(
      db.voidingSchedules,
    )..where((t) => t.isActive.equals(true))).get();

    for (final s in activeSchedules) {
      await scheduleDailyVoidingSlots(
        scheduleId: s.id,
        title: s.title,
        startTime: s.startTime,
        endTime: s.endTime,
        intervalMinutes: s.intervalMinutes,
      );
    }
  }

  Future<void> cancelScheduleAlarms(String scheduleId) async {
    final id = (scheduleId.hashCode & 0x7FFFFFFF);
    await flutterLocalNotificationsPlugin.cancel(id);
    currentNextAlarm = null;
    _nextAlarmController.add(null);
  }

  Future<void> handleNotificationAction(
    String actionId,
    String? payload,
  ) async {
    final db = AppDatabase();
    const uuid = Uuid();

    try {
      if (actionId == 'voiding_success') {
        await db
            .into(db.voidingLogs)
            .insert(
              VoidingLogsCompanion.insert(
                id: uuid.v4(),
                timestamp: DateTime.now(),
                eventType: 'prompted_success',
                urgencyLevel: const Value(1),
                volumeEstimation: const Value('medium'),
                notes: const Value('ثبت سریع از طریق اعلان'),
              ),
            );
        await resetTimerForActiveSchedules(db);
      } else if (actionId == 'voiding_accident') {
        await db
            .into(db.voidingLogs)
            .insert(
              VoidingLogsCompanion.insert(
                id: uuid.v4(),
                timestamp: DateTime.now(),
                eventType: 'accident',
                urgencyLevel: const Value(3),
                volumeEstimation: const Value('medium'),
                notes: const Value('ثبت تصادف از طریق اعلان'),
              ),
            );
        await resetTimerForActiveSchedules(db);
      }
    } catch (e, st) {
      log('Error handling notification action $actionId: $e\n$st');
    } finally {
      await db.close();
    }
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    currentNextAlarm = null;
    _nextAlarmController.add(null);
  }
}
