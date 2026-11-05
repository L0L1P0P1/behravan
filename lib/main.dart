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

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  // Individual const items inside a regular List literal
  final List<Widget> _screens = [
    const VoidingScreen(),
    const EnuresisScreen(),
    const BowelScreen(),
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
