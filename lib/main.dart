import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/notification_service.dart';
import 'core/localization/app_localizations.dart';
import 'features/voiding/presentation/voiding_screen.dart';
import 'features/enuresis/presentation/enuresis_screen.dart';
import 'features/bowel/presentation/bowel_screen.dart';
import 'features/reports/presentation/reports_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Safe synchronous timezone initialization
  tz.initializeTimeZones();

  runApp(
    const ProviderScope(
      child: BehravanApp(),
    ),
  );

  // Initialize notifications asynchronously in background
  NotificationService.instance.init().then((_) {
    NotificationService.instance.scheduleMorningEnuresisPrompt();
  }).catchError((e) {
    debugPrint('Notification init error: $e');
  });
}

class BehravanApp extends StatelessWidget {
  const BehravanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'بهرavan',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [
        Locale('fa', 'IR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'Vazirmatn',
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

  final List<Widget> _screens = const [
    VoidingScreen(),
    EnuresisScreen(),
    BowelScreen(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.timer_outlined),
              selectedIcon: Icon(Icons.timer),
              label: 'ادرار',
            ),
            NavigationDestination(
              icon: Icon(Icons.nightlight_outlined),
              selectedIcon: Icon(Icons.nightlight),
              label: 'شب‌ادراری',
            ),
            NavigationDestination(
              icon: Icon(Icons.medical_services_outlined),
              selectedIcon: Icon(Icons.medical_services),
              label: 'مدفوع',
            ),
            NavigationDestination(
              icon: Icon(Icons.assessment_outlined),
              selectedIcon: Icon(Icons.assessment),
              label: 'گزارش',
            ),
          ],
        ),
      ),
    );
  }
}
