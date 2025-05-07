import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crate_app/main.dart';
import 'package:crate_app/login_screen.dart';

void main() {
  testWidgets('MyApp renders LoginScreen as home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('MyApp has the correct title and theme', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(
      find.byWidgetPredicate(
        (widget) => widget is MaterialApp && widget.title == 'Crate App',
      ),
      findsOneWidget,
    );

    final ThemeData theme = Theme.of(tester.element(find.byType(MyApp)));
    expect(theme.primaryColor, Colors.blue);
  });
}
