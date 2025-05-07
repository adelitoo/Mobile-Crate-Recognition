import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crate_app/components/square_title.dart';

void main() {
  testWidgets('SquareTile renders correctly and triggers onTap', (
    WidgetTester tester,
  ) async {
    // Define a mock onTap function
    bool tapped = false;
    final onTap = () {
      tapped = true;
    };

    // Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SquareTile(
            imagePath: 'assets/images/icon/apple.png',
            onTap: onTap,
          ),
        ),
      ),
    );

    // Verify that the image is rendered correctly
    expect(find.byType(Image), findsOneWidget);
    expect(
      (tester.widget<Image>(find.byType(Image)).image as AssetImage).assetName,
      'assets/images/icon/apple.png',
    );

    // Verify the tile decoration (border and background color)
    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.border, Border.all(color: Colors.white));
    expect(decoration.color, Colors.grey[200]);

    // Simulate a tap on the SquareTile
    await tester.tap(find.byType(SquareTile));
    await tester.pump();

    // Verify that the onTap function was called (i.e., tapped is set to true)
    expect(tapped, true);
  });
}
