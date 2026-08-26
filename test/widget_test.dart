import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:behravan/main.dart';
import 'package:behravan/core/providers.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Mock data providers here
          voidingLogsProvider.overrideWith((ref) => const Stream.empty()),
          voidingSchedulesProvider.overrideWith((ref) => const Stream.empty()),
        ],
        child: const BehravanApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ادرار روزانه و یادآورها'), findsOneWidget);
  });
}
