import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crate_app/components/my_button.dart'; // Update with your actual import path

void main() {
  testWidgets('MyButton renders and triggers onTap callback', (
    WidgetTester tester,
  ) async {
    // Set up a mock onTap callback
    bool tapped = false;
    void onTap() {
      tapped = true;
    }

    // Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MyButton(onTap: onTap, text: 'Click Me')),
      ),
    );

    // Verify the button text is displayed
    expect(find.text('Click Me'), findsOneWidget);

    // Verify the button decoration
    final container = tester.widget<Container>(find.byType(Container));
    expect(container.decoration, isA<BoxDecoration>());
    final boxDecoration = container.decoration as BoxDecoration;
    expect(boxDecoration.color, Colors.black);
    expect(boxDecoration.borderRadius, BorderRadius.circular(8));

    // Tap the button and verify the onTap callback is called
    await tester.tap(find.byType(GestureDetector));
    await tester.pump(); // Wait for the callback to be executed

    // Verify that the onTap callback was triggered
    expect(tapped, true);
  });
}
