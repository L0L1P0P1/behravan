import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'core/localization/app_localizations.dart';
import 'core/providers.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'data/database/app_database.dart';
import 'features/bowel/presentation/bowel_screen.dart';
import 'features/enuresis/presentation/enuresis_screen.dart';
import 'features/reports/presentation/reports_screen.dart';
import 'features/rewards/application/rewards_provider.dart';
import 'features/rewards/presentation/badge_unlocked_dialog.dart';
import 'features/rewards/presentation/rewards_screen.dart';
import 'features/tutorial/presentation/tutorial_screen.dart';
import 'features/voiding/presentation/voiding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  final prefs = await SharedPreferences.getInstance();

  try {
    await NotificationService.instance.init();
    await NotificationService.instance.requestPermissions();
    await NotificationService.instance.scheduleMorningEnuresisPrompt();

    final db = AppDatabase();
    await NotificationService.instance.resetTimerForActiveSchedules(db);
    await db.close();
  } catch (e, st) {
    debugPrint('Notification init error: $e\n$st');
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const BehravanApp(),
    ),
  );
}

class BehravanApp extends StatelessWidget {
  const BehravanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'بهروان',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [Locale('fa', 'IR'), Locale('en', 'US')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildAppTheme(),
      // The app shows 24-hour clocks everywhere, so pickers must match.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({super.key});

  @override
  ConsumerState<MainNavigationShell> createState() =>
      _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  int _currentIndex = 0;
  bool _celebrating = false;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    if (!(prefs.getBool(tutorialSeenKey) ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await TutorialScreen.open(context);
        await prefs.setBool(tutorialSeenKey, true);
        await _celebrateNewBadges();
      });
    }
    ref.listenManual(rewardsProvider, (_, _) => _celebrateNewBadges());
  }

  /// Shows newly earned badges once, after the save toast has had a moment.
  Future<void> _celebrateNewBadges() async {
    if (_celebrating) return;
    final prefs = ref.read(sharedPreferencesProvider);
    // Waits for the first-launch tutorial, which calls back when closed.
    if (!(prefs.getBool(tutorialSeenKey) ?? false)) return;
    final seen = (prefs.getStringList(seenBadgesKey) ?? const []).toSet();
    final fresh = [
      for (final b in ref.read(rewardsProvider).unlocked)
        if (!seen.contains(b.id)) b,
    ];
    if (fresh.isEmpty) return;

    _celebrating = true;
    await prefs.setStringList(seenBadgesKey, [
      ...seen,
      for (final b in fresh) b.id,
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (mounted) await BadgeUnlockedDialog.show(context, fresh);
    _celebrating = false;
  }

  // Individual const items inside a regular List literal
  final List<Widget> _screens = [
    const VoidingScreen(),
    const EnuresisScreen(),
    const BowelScreen(),
    const RewardsScreen(),
    const ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) =>
                setState(() => _currentIndex = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.timer_outlined, color: Color(0xFF64748B)),
                selectedIcon: Icon(
                  Icons.timer_rounded,
                  color: Color(0xFF0284C7),
                ),
                label: 'ادرار',
              ),
              NavigationDestination(
                icon: Icon(Icons.nightlight_outlined, color: Color(0xFF64748B)),
                selectedIcon: Icon(
                  Icons.nightlight_rounded,
                  color: Color(0xFF0284C7),
                ),
                label: 'شب‌ادراری',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.health_and_safety_outlined,
                  color: Color(0xFF64748B),
                ),
                selectedIcon: Icon(
                  Icons.health_and_safety_rounded,
                  color: Color(0xFF0284C7),
                ),
                label: 'مدفوع',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.emoji_events_outlined,
                  color: Color(0xFF64748B),
                ),
                selectedIcon: Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFF0284C7),
                ),
                label: 'جایزه',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_rounded, color: Color(0xFF64748B)),
                selectedIcon: Icon(
                  Icons.bar_chart_rounded,
                  color: Color(0xFF0284C7),
                ),
                label: 'گزارش',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
