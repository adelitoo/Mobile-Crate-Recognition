import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crate_app/services/sql_auth_service.dart'; // Adjust to your actual import
import 'package:crate_app/config/app_config.dart'; // Adjust to your actual import

// Mocking the http client
class MockHttpClient extends Mock implements http.Client {}

void main() {
  late SqlAuthService authService;
  late MockHttpClient mockHttpClient;

  setUp(() {
    mockHttpClient = MockHttpClient();
    // Mock static members of AppConfig
    when(
      () => AppConfig.employeesEndpoint,
    ).thenReturn('http://fake.com/employees');
    when(() => AppConfig.loginEndpoint).thenReturn('http://fake.com/login');

    // Instantiate the service with the mocked HTTP client
    authService = SqlAuthService(client: mockHttpClient);
  });

  test(
    'getEmployees returns a list of employees when the response is 200',
    () async {
      final mockResponse = jsonEncode(["Employee1", "Employee2"]);

      // Mock the http client to return a successful response
      when(
        () => mockHttpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response(mockResponse, 200));

      // Call the method to test
      final employees = await authService.getEmployees();

      // Verify the result
      expect(employees, ["Employee1", "Employee2"]);
    },
  );

  test('login returns true when the response is 200', () async {
    final mockResponse = jsonEncode({"message": "Success"});

    // Mock the http client to return a successful response
    when(
      () => mockHttpClient.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => http.Response(mockResponse, 200));

    // Call the method to test
    final result = await authService.login("user", "password");

    // Verify the result
    expect(result, true);
  });

  test('login returns false when the response is not 200', () async {
    final mockResponse = jsonEncode({"message": "Failed"});

    // Mock the http client to return a failed response
    when(
      () => mockHttpClient.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => http.Response(mockResponse, 400));

    // Call the method to test
    final result = await authService.login("user", "wrongpassword");

    // Verify the result
    expect(result, false);
  });
}
