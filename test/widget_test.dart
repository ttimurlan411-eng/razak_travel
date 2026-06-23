import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:razak_travel/main.dart';
import 'package:razak_travel/shared/localization/locale_controller.dart';

void main() {
  testWidgets('app renders a provided home widget', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LocaleController(),
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
