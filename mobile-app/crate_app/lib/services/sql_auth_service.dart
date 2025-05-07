import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bcrypt/bcrypt.dart';
import '../config/app_config.dart';

class SqlAuthService {
  final http.Client client;

  SqlAuthService({http.Client? client}) : client = client ?? http.Client();

  Future<List<String>> getEmployees() async {
    try {
      final response = await client.get(
        Uri.parse(AppConfig.employeesEndpoint),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((employee) => employee.toString()).toList();
      } else {
        throw Exception('Failed to load employees');
      }
    } catch (e) {
      print('Error in getEmployees: $e');
      throw Exception('Error: $e');
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await client.post(
        Uri.parse(AppConfig.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
