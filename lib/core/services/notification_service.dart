import 'dart:developer';
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
          'Notification action tapped: ${response.actionId} with payload ${response.payload}',
        );
        if (response.actionId != null) {
          await handleNotificationAction(response.actionId!, response.payload);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

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

  /// Schedules repeating reminders across the day window
  Future<void> scheduleDailyVoidingSlots({
    required String scheduleId,
    required String title,
    required String startTime,
    required String endTime,
    required int intervalMinutes,
  }) async {
    await init();
    await cancelScheduleAlarms(scheduleId);

    final startParts = startTime.split(':').map(int.parse).toList();
    final endParts = endTime.split(':').map(int.parse).toList();

    final now = DateTime.now();
    var currentSlotTime = DateTime(
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

    int slotIndex = 0;
    while (!currentSlotTime.isAfter(endDateTime)) {
      final notificationId = (scheduleId.hashCode ^ slotIndex).toSigned(31);

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
            showsUserInterface: false,
          ),
          AndroidNotificationAction(
            'voiding_accident',
            'Had Accident',
            showsUserInterface: false,
          ),
        ],
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        '🚽 $title',
        'Time for a scheduled bathroom break!',
        _nextInstanceOfTime(
          startParts[0],
          startParts[1],
          slotIndex * intervalMinutes,
        ),
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'voiding_slot_$scheduleId',
      );

      currentSlotTime = currentSlotTime.add(Duration(minutes: intervalMinutes));
      slotIndex++;
    }
  }

  /// Resets and pushes the next alarm forward when a voiding occurs
  Future<void> resetTimerForActiveSchedules(AppDatabase db) async {
    await init();
    final activeSchedules = await (db.select(
      db.voidingSchedules,
    )..where((t) => t.isActive.equals(true))).get();

    for (final s in activeSchedules) {
      await cancelScheduleAlarms(s.id);

      final endParts = s.endTime.split(':').map(int.parse).toList();
      final now = DateTime.now();
      final endDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        endParts[0],
        endParts[1],
      );

      final nextAlarmTime = now.add(Duration(minutes: s.intervalMinutes));

      // Only schedule if the reset time falls before the end time
      if (!nextAlarmTime.isAfter(endDateTime)) {
        final notificationId = (s.id.hashCode ^ 0).toSigned(31);

        const androidDetails = AndroidNotificationDetails(
          'voiding_reminders',
          'Timed Voiding Alarms',
          channelDescription: 'Reminders for timed voiding routine',
          importance: Importance.max,
          priority: Priority.high,
        );

        await flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId,
          '🚽 ${s.title}',
          'Time for a scheduled bathroom break!',
          tz.TZDateTime.from(nextAlarmTime, tz.local),
          const NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'voiding_reset_${s.id}',
        );
      }
    }
  }

  tz.TZDateTime _nextInstanceOfTime(
    int startHour,
    int startMinute,
    int addedMinutes,
  ) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      startHour,
      startMinute,
    ).add(Duration(minutes: addedMinutes));

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> cancelScheduleAlarms(
    String scheduleId, {
    int maxSlots = 20,
  }) async {
    for (int i = 0; i < maxSlots; i++) {
      final id = (scheduleId.hashCode ^ i).toSigned(31);
      await flutterLocalNotificationsPlugin.cancel(id);
    }
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
  }
}
