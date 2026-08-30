import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../data/database/app_database.dart';

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
