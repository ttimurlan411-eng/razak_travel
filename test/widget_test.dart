import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:razak_travel/core/localization/locale_controller.dart';
import 'package:razak_travel/main.dart';
import 'package:razak_travel/shared/theme/theme_controller.dart';

void main() {
  testWidgets('app renders a provided home widget', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LocaleController()),
          ChangeNotifierProvider(create: (_) => ThemeController()),
        ],
        child: const MyApp(
          home: Scaffold(
            body: Center(
              child: Text('Smoke Test'),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Smoke Test'), findsOneWidget);
  });
}
