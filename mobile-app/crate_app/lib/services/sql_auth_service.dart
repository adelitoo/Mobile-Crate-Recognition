import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bcrypt/bcrypt.dart';

class SqlAuthService {
  final String baseUrl = 'http://192.168.1.123:5000'; // Your backend URL

  Future<List<String>> getEmployees() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/employees'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // The backend returns a list of strings directly, not objects
        return data.map((employee) => employee.toString()).toList();
      } else {
        throw Exception('Failed to load employees');
      }
    } catch (e) {
      print('Error in getEmployees: $e'); // Add this line for debugging
      throw Exception('Error: $e');
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}