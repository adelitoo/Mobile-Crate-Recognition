import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crate_app/home_screen.dart';
import 'package:crate_app/login_screen.dart';
import 'package:crate_app/camera_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  testWidgets('HomeScreen Widget Test', (WidgetTester tester) async {
    const testUsername = 'JohnDoe';

    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(username: testUsername)),
    );

    await tester.pumpAndSettle();

    expect(find.text('Home🏠'), findsOneWidget);

    expect(find.text(testUsername), findsOneWidget);

    expect(find.byType(GoogleMap), findsOneWidget);

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(username: testUsername)),
    );

    final scanButton = find.text('Scan');
    expect(scanButton, findsOneWidget);
    await tester.tap(scanButton);
    await tester.pumpAndSettle();

    expect(find.byType(TakePictureScreen), findsOneWidget);
  });
}
