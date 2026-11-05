import 'package:behravan/core/providers.dart';
import 'package:behravan/core/theme/app_theme.dart';
import 'package:behravan/core/utils/date_utils.dart';
import 'package:behravan/data/database/app_database.dart';
import 'package:behravan/features/bowel/presentation/bowel_screen.dart';
import 'package:behravan/features/enuresis/domain/dry_streaks.dart';
import 'package:behravan/features/enuresis/presentation/enuresis_screen.dart';
import 'package:behravan/features/reports/application/clinical_report_pdf.dart';
import 'package:behravan/features/reports/presentation/reports_screen.dart';
import 'package:behravan/features/voiding/presentation/voiding_screen.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

EnuresisLogEntity _night(DateTime day, {required bool isDry, String? notes}) =>
    EnuresisLogEntity(
      id: 'n${day.toIso8601String()}',
      date: DateFormat('yyyy-MM-dd').format(day),
      isDry: isDry,
      wokeToPee: false,
      eveningFluidRestriction: false,
      notes: notes,
    );

VoidingLogEntity _void(DateTime at, String type, {String? notes}) =>
    VoidingLogEntity(
      id: 'v${at.toIso8601String()}',
      timestamp: at,
      eventType: type,
      urgencyLevel: 1,
      volumeEstimation: 'medium',
      notes: notes,
    );

BowelLogEntity _bowel(DateTime at, int type, {bool blood = false}) =>
    BowelLogEntity(
      id: 'b${at.toIso8601String()}',
      timestamp: at,
      bristolType: type,
      strainingLevel: 1,
      bloodPresent: blood,
      soilingAccident: false,
      notes: null,
    );

const _schedule = VoidingScheduleEntity(
  id: 'default_schedule',
  title: 'Daytime Timed Voiding',
  startTime: '00:00',
  endTime: '23:59',
  intervalMinutes: 120,
  isActive: true,
  daysOfWeek: 127,
);

Future<void> _pumpScreen(
  WidgetTester tester,
  Widget screen, {
  List<VoidingLogEntity> voiding = const [],
  List<EnuresisLogEntity> nights = const [],
  List<BowelLogEntity> bowel = const [],
  Size size = const Size(360, 640),
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        voidingSchedulesProvider.overrideWith(
          (ref) => Stream.value([_schedule]),
        ),
        voidingLogsProvider.overrideWith((ref) => Stream.value(voiding)),
        enuresisLogsProvider.overrideWith((ref) => Stream.value(nights)),
        bowelLogsProvider.overrideWith((ref) => Stream.value(bowel)),
      ],
      child: MaterialApp(
        locale: const Locale('fa', 'IR'),
        supportedLocales: const [Locale('fa', 'IR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: buildAppTheme(),
        home: screen,
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  DateTime daysAgo(int days) =>
      DateTime(today.year, today.month, today.day - days);

  group('computeDryStreaks', () {
    test('a pending entry for today does not break the current run', () {
      final streaks = computeDryStreaks([
        _night(daysAgo(1), isDry: true),
        _night(daysAgo(2), isDry: true),
        _night(daysAgo(3), isDry: false),
      ], today);

      expect(streaks.current, 2);
      expect(streaks.longest, 2);
    });

    test('a wet night today resets the current run only', () {
      final streaks = computeDryStreaks([
        _night(today, isDry: false),
        _night(daysAgo(1), isDry: true),
        _night(daysAgo(2), isDry: true),
      ], today);

      expect(streaks.current, 0);
      expect(streaks.longest, 2);
    });

    test('the best run counts history older than 90 days', () {
      final streaks = computeDryStreaks([
        for (var i = 200; i < 205; i++) _night(daysAgo(i), isDry: true),
      ], today);

      expect(streaks.current, 0);
      expect(streaks.longest, 5);
    });
  });

  test('relativeDay names recent days and dates older ones', () {
    final reference = DateTime(2026, 11, 5, 9);

    expect(
      PersianDateFormatter.relativeDay(reference, now: reference),
      'امروز',
    );
    expect(
      PersianDateFormatter.relativeDay(
        DateTime(2026, 11, 4, 23),
        now: reference,
      ),
      'دیروز',
    );
    expect(
      PersianDateFormatter.relativeDay(DateTime(2026, 11, 1), now: reference),
      '10 آبان',
    );
  });

  testWidgets('the voiding diary lists only today', (tester) async {
    await _pumpScreen(
      tester,
      const VoidingScreen(),
      size: const Size(360, 1400),
      voiding: [
        _void(now, 'accident', notes: 'today-note'),
        _void(daysAgo(2), 'spontaneous', notes: 'old-note'),
      ],
    );

    expect(find.text('today-note'), findsOneWidget);
    expect(find.text('old-note'), findsNothing);
    expect(find.text('1 رویداد'), findsOneWidget);
  });

  testWidgets('logs open in the edit sheet with a delete action', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      const VoidingScreen(),
      size: const Size(360, 1400),
      voiding: [_void(now, 'spontaneous', notes: 'editable')],
    );

    await tester.tap(find.text('editable'));
    await tester.pumpAndSettle();

    expect(find.text('ویرایش ثبت'), findsOneWidget);
    expect(find.text('حذف این ثبت'), findsOneWidget);
  });

  testWidgets('reports hide the rate until there is enough data', (
    tester,
  ) async {
    await _pumpScreen(tester, const ReportsScreen());

    expect(find.textContaining('موفقیت'), findsNothing);
    final button = tester.widget<FilledButton>(
      find.byWidgetPredicate((w) => w is FilledButton),
    );
    expect(button.onPressed, isNull);
  });

  group('no layout overflow on a small phone', () {
    final voiding = [
      _void(now, 'prompted_success', notes: 'یادداشت بسیار طولانی ' * 6),
      _void(now.subtract(const Duration(minutes: 5)), 'accident'),
    ];
    final nights = [
      _night(today, isDry: true, notes: 'یادداشت بسیار طولانی ' * 6),
      _night(daysAgo(1), isDry: false),
    ];
    final bowel = [_bowel(now, 4), _bowel(daysAgo(3), 1, blood: true)];

    final screens = <String, Widget>{
      'voiding': const VoidingScreen(),
      'enuresis': const EnuresisScreen(),
      'bowel': const BowelScreen(),
      'reports': const ReportsScreen(),
    };

    for (final MapEntry(key: name, value: screen) in screens.entries) {
      testWidgets(name, (tester) async {
        await _pumpScreen(
          tester,
          screen,
          size: const Size(320, 640),
          voiding: voiding,
          nights: nights,
          bowel: bowel,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('bowel entry sheet', (tester) async {
      await _pumpScreen(
        tester,
        const BowelScreen(),
        size: const Size(320, 640),
      );
      await tester.tap(find.text('ثبت نوبت جدید'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('voiding detail sheet', (tester) async {
      await _pumpScreen(
        tester,
        const VoidingScreen(),
        size: const Size(320, 640),
      );
      await tester.tap(find.textContaining('ثبت با جزئیات'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('schedule sheet', (tester) async {
      await _pumpScreen(
        tester,
        const VoidingScreen(),
        size: const Size(320, 640),
      );
      await tester.tap(find.textContaining('هر 120 دقیقه'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('with a real database', () {
    Future<AppDatabase> pumpWithDatabase(
      WidgetTester tester,
      Widget screen,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());

      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            locale: const Locale('fa', 'IR'),
            supportedLocales: const [Locale('fa', 'IR')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: buildAppTheme(),
            home: screen,
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      return db;
    }

    /// Unmounts inside the test body so drift's stream cleanup timers finish
    /// before the framework checks for pending timers.
    Future<void> finish(WidgetTester tester, AppDatabase db) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
      await tester.runAsync(db.close);
    }

    Future<void> settle(WidgetTester tester) async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('marking a night dry keeps its saved details', (tester) async {
      final db = await pumpWithDatabase(tester, const EnuresisScreen());
      await tester.runAsync(
        () => db
            .into(db.enuresisLogs)
            .insert(
              EnuresisLogsCompanion.insert(
                id: 'night',
                date: DateFormat('yyyy-MM-dd').format(today),
                isDry: false,
                wokeToPee: const Value(true),
                eveningFluidRestriction: const Value(true),
                notes: const Value('خواب سنگین'),
              ),
            ),
      );
      await settle(tester);

      await tester.tap(find.text('شب خشک').first);
      await settle(tester);

      final saved = await tester.runAsync(
        () => db.select(db.enuresisLogs).getSingle(),
      );
      expect(saved!.isDry, isTrue);
      expect(saved.wokeToPee, isTrue);
      expect(saved.eveningFluidRestriction, isTrue);
      expect(saved.notes, 'خواب سنگین');

      await finish(tester, db);
    });

    testWidgets('a deleted bowel log can be restored with undo', (
      tester,
    ) async {
      final db = await pumpWithDatabase(tester, const BowelScreen());
      await tester.runAsync(
        () => db
            .into(db.bowelLogs)
            .insert(
              BowelLogsCompanion.insert(
                id: 'log',
                timestamp: now,
                bristolType: 4,
              ),
            ),
      );
      await settle(tester);

      await tester.tap(find.text('مارپیچ و نرم'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حذف این ثبت'));
      await tester.pump(const Duration(milliseconds: 500));
      await settle(tester);

      final afterDelete = await tester.runAsync(
        () => db.select(db.bowelLogs).get(),
      );
      expect(afterDelete, isEmpty);

      await tester.tap(find.text('لغو'));
      await settle(tester);

      final afterUndo = await tester.runAsync(
        () => db.select(db.bowelLogs).get(),
      );
      expect(afterUndo!.single.id, 'log');

      await finish(tester, db);
    });
  });

  test('the clinical report builds with Persian free text', () async {
    TestWidgetsFlutterBinding.ensureInitialized();

    final bytes = await buildClinicalReportPdf(
      voidingLogs: [_void(now, 'accident', notes: 'سرما خورده بود')],
      enuresisLogs: [_night(today, isDry: false, notes: 'خواب سنگین')],
      bowelLogs: [_bowel(now, 4)],
      evaluation: null,
    );

    expect(bytes, isNotEmpty);
  });
}
