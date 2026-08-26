import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

@DataClassName('VoidingScheduleEntity')
class VoidingSchedules extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get startTime => text()(); // e.g. '08:00'
  TextColumn get endTime => text()();     // e.g. '20:00'
  IntColumn get intervalMinutes => integer()(); // e.g. 120
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get daysOfWeek => integer().withDefault(const Constant(127))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('VoidingLogEntity')
class VoidingLogs extends Table {
  TextColumn get id => text()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get eventType => text()(); // 'prompted_success', 'spontaneous', 'accident', 'missed'
  IntColumn get urgencyLevel => integer().nullable()(); // 1 to 3
  TextColumn get volumeEstimation => text().nullable()(); // 'small', 'medium', 'large'
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('EnuresisLogEntity')
class EnuresisLogs extends Table {
  TextColumn get id => text()();
  TextColumn get date => text()(); // YYYY-MM-DD unique
  BoolColumn get isDry => boolean()();
  BoolColumn get wokeToPee => boolean().withDefault(const Constant(false))();
  BoolColumn get eveningFluidRestriction => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BowelLogEntity')
class BowelLogs extends Table {
  TextColumn get id => text()();
  DateTimeColumn get timestamp => dateTime()();
  IntColumn get bristolType => integer()(); // 1 to 7
  IntColumn get strainingLevel => integer().withDefault(const Constant(1))(); // 1 to 3
  BoolColumn get bloodPresent => boolean().withDefault(const Constant(false))();
  BoolColumn get soilingAccident => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'behravan.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

@DriftDatabase(tables: [VoidingSchedules, VoidingLogs, EnuresisLogs, BowelLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  // Prepopulate default schedule if empty
  Future<void> seedDefaultData() async {
    final schedules = await select(voidingSchedules).get();
    if (schedules.isEmpty) {
      await into(voidingSchedules).insert(
        VoidingSchedulesCompanion.insert(
          id: 'default_schedule',
          title: 'Daytime Timed Voiding',
          startTime: '08:00',
          endTime: '20:00',
          intervalMinutes: 120,
          isActive: const Value(true),
          daysOfWeek: const Value(127),
        ),
      );
    }
  }
}
