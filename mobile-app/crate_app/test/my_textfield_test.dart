import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crate_app/components/my_textfield.dart'; // Update with your actual import path

void main() {
  testWidgets('MyTextField renders correctly and handles input', (
    WidgetTester tester,
  ) async {
    // Create a TextEditingController for testing
    final controller = TextEditingController();

    // Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyTextField(
            controller: controller,
            hintText: 'Enter text',
            obscureText: false,
          ),
        ),
      ),
    );

    // Verify the TextField renders with the correct hint text
    expect(find.text('Enter text'), findsOneWidget);

    // Verify the TextField decoration
    final textField = tester.widget<TextField>(find.byType(TextField));
    final decoration = textField.decoration;

    expect(decoration?.fillColor, Colors.grey.shade200);
    expect(decoration?.hintStyle?.color, Colors.grey[500]);

    // Simulate typing into the TextField
    await tester.enterText(find.byType(TextField), 'Test Input');
    await tester.pump(); // Trigger a frame update

    // Verify that the controller's text has been updated
    expect(controller.text, 'Test Input');

    // Now test the obscureText behavior
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyTextField(
            controller: controller,
            hintText: 'Enter password',
            obscureText: true,
          ),
        ),
      ),
    );

    // Verify that the obscureText property works (i.e., obscure the text input)
    final textFieldWithObscure = tester.widget<TextField>(
      find.byType(TextField),
    );
    expect(textFieldWithObscure.obscureText, true);

    // Simulate typing into the TextField with obscureText = true
    await tester.enterText(find.byType(TextField), 'Secret123');
    await tester.pump();

    // Verify that the controller's text is still 'Secret123'
    expect(controller.text, 'Secret123');
  });
}
