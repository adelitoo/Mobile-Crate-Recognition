import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crate_app/login_screen.dart';
import 'package:crate_app/home_screen.dart';
import 'package:mockito/mockito.dart';
import 'package:crate_app/services/sql_auth_service.dart';

// Mock the SqlAuthService
class MockSqlAuthService extends Mock implements SqlAuthService {}

void main() {
  testWidgets('LoginScreen Widget Test', (WidgetTester tester) async {
    // Create a mock auth service
    final mockAuthService = MockSqlAuthService();

    // Stub the getEmployees method to return a list of employees
    when(
      mockAuthService.getEmployees(),
    ).thenAnswer((_) async => ['JohnDoe', 'JaneSmith']);

    // Stub the login method to return true (successful login)
    when(
      mockAuthService.login('JohnDoe', 'password'),
    ).thenAnswer((_) async => true);

    // Build the LoginScreen widget using the mocked auth service
    await tester.pumpWidget(MaterialApp(home: LoginScreen()));

    // Wait for the screen to load
    await tester.pumpAndSettle();

    // Verify that the employee selection dropdown is visible
    expect(find.text('Select Employee'), findsOneWidget);

    // Verify the login animation
    expect(find.byType(Lottie), findsOneWidget);

    // Verify the password field is visible
    expect(find.byType(MyTextField), findsOneWidget);

    // Select an employee from the dropdown
    await tester.tap(find.text('Select Employee'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('JohnDoe'));
    await tester.pumpAndSettle();

    // Enter password
    await tester.enterText(find.byType(MyTextField), 'password');
    await tester.pumpAndSettle();

    // Tap the Sign In button
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    // Verify that the login function was called with the correct parameters
    verify(mockAuthService.login('JohnDoe', 'password')).called(1);

    // Verify that the HomeScreen is pushed after successful login
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('LoginScreen handles error when login fails', (
    WidgetTester tester,
  ) async {
    // Create a mock auth service
    final mockAuthService = MockSqlAuthService();

    // Stub the getEmployees method to return a list of employees
    when(
      mockAuthService.getEmployees(),
    ).thenAnswer((_) async => ['JohnDoe', 'JaneSmith']);

    // Stub the login method to return false (failed login)
    when(
      mockAuthService.login('JohnDoe', 'wrongPassword'),
    ).thenAnswer((_) async => false);

    // Build the LoginScreen widget using the mocked auth service
    await tester.pumpWidget(MaterialApp(home: LoginScreen()));

    // Wait for the screen to load
    await tester.pumpAndSettle();

    // Select an employee from the dropdown
    await tester.tap(find.text('Select Employee'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('JohnDoe'));
    await tester.pumpAndSettle();

    // Enter wrong password
    await tester.enterText(find.byType(MyTextField), 'wrongPassword');
    await tester.pumpAndSettle();

    // Tap the Sign In button
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    // Verify that the login function was called with the wrong parameters
    verify(mockAuthService.login('JohnDoe', 'wrongPassword')).called(1);

    // Verify that an error message is shown
    expect(find.text('Invalid password'), findsOneWidget);
  });

  testWidgets('LoginScreen shows loading indicator when logging in', (
    WidgetTester tester,
  ) async {
    // Create a mock auth service
    final mockAuthService = MockSqlAuthService();

    // Stub the getEmployees method to return a list of employees
    when(
      mockAuthService.getEmployees(),
    ).thenAnswer((_) async => ['JohnDoe', 'JaneSmith']);

    // Stub the login method to simulate a delay and return true (successful login)
    when(mockAuthService.login('JohnDoe', 'password')).thenAnswer((_) async {
      await Future.delayed(Duration(seconds: 1));
      return true;
    });

    // Build the LoginScreen widget using the mocked auth service
    await tester.pumpWidget(MaterialApp(home: LoginScreen()));

    // Wait for the screen to load
    await tester.pumpAndSettle();

    // Select an employee from the dropdown
    await tester.tap(find.text('Select Employee'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('JohnDoe'));
    await tester.pumpAndSettle();

    // Enter password
    await tester.enterText(find.byType(MyTextField), 'password');
    await tester.pumpAndSettle();

    // Tap the Sign In button
    await tester.tap(find.text('Sign In'));

    // Verify the loading indicator is shown
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for the login process to complete
    await tester.pumpAndSettle();

    // Verify that the loading indicator is no longer visible after login
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Verify that the HomeScreen is pushed after successful login
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
