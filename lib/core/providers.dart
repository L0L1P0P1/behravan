import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../data/database/app_database.dart';
import 'services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Prefs not initialized');
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final voidingSchedulesProvider = StreamProvider<List<VoidingScheduleEntity>>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  return db.select(db.voidingSchedules).watch();
});

final voidingLogsProvider = StreamProvider<List<VoidingLogEntity>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(
    db.voidingLogs,
  )..orderBy([(t) => OrderingTerm.desc(t.timestamp)])).watch();
});

final enuresisLogsProvider = StreamProvider<List<EnuresisLogEntity>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(
    db.enuresisLogs,
  )..orderBy([(t) => OrderingTerm.desc(t.date)])).watch();
});

final bowelLogsProvider = StreamProvider<List<BowelLogEntity>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(
    db.bowelLogs,
  )..orderBy([(t) => OrderingTerm.desc(t.timestamp)])).watch();
});

final nextAlarmProvider = StreamProvider<DateTime?>((ref) {
  return NotificationService.instance.nextAlarmStream;
});
