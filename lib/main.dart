import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'core/localization/app_localizations.dart';
import 'core/providers.dart';
import 'core/services/notification_service.dart';
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
    const primaryColor = Color(0xFF0284C7);
    const surfaceColor = Color(0xFFF8FAFC);

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
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Vazirmatn',
        scaffoldBackgroundColor: surfaceColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          surface: surfaceColor,
          surfaceContainerLowest: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: surfaceColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          height: 68,
          indicatorColor: const Color(0xFFE0F2FE),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final isSelected = states.contains(WidgetState.selected);
            return TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? const Color(0xFF0369A1)
                  : const Color(0xFF64748B),
            );
          }),
        ),
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
                  Icons.analytics_rounded,
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
