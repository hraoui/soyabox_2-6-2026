import 'package:caisse_1/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppBackButton stays hidden when route cannot pop', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(appBar: AppBar(leading: const AppBackButton())),
      ),
    );

    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('AppBackButton renders when alwaysVisible is true', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(leading: const AppBackButton(alwaysVisible: true)),
        ),
      ),
    );

    expect(find.byType(IconButton), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });
}
