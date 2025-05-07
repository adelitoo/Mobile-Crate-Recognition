import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'components/my_textfield.dart';
import 'components/my_button.dart';
import 'services/sql_auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final passwordController = TextEditingController();
  String errorMessage = '';
  String? selectedEmployee;
  List<String> employees = [];
  final SqlAuthService authService = SqlAuthService();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadEmployees();
  }

  Future<void> loadEmployees() async {
    try {
      print('Loading employees...'); // Debug print
      final employeeList = await authService.getEmployees();
      print('Received employees: $employeeList'); // Debug print
      setState(() {
        employees = employeeList;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading employees: $e'); // Debug print
      setState(() {
        errorMessage = 'Failed to load employees: $e';
        isLoading = false;
      });
    }
  }

  void signUserIn() async {
    if (selectedEmployee == null) {
      setState(() {
        errorMessage = 'Please select an employee';
      });
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final success = await authService.login(
        selectedEmployee!,
        passwordController.text,
      );

      Navigator.pop(context);

      if (success) {
        setState(() {
          errorMessage = '';
        });
        // Navigate to home screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(username: selectedEmployee!),
          ),
        );
      } else {
        setState(() {
          errorMessage = 'Invalid password';
        });
      }
    } catch (e) {
      Navigator.pop(context);
      setState(() {
        errorMessage = 'Login failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/images/animations/login1.json',
                  width: 200,
                ),
                Text(
                  'Welcome back!',
                  style: TextStyle(color: Colors.grey[700], fontSize: 16),
                ),
                const SizedBox(height: 25),

                // Employee Selection Dropdown
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text('Select Employee'),
                        ),
                        value: selectedEmployee,
                        items:
                            employees.map((String employee) {
                              return DropdownMenuItem<String>(
                                value: employee,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                  ),
                                  child: Text(employee),
                                ),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedEmployee = newValue;
                            errorMessage = '';
                          });
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                MyTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),

                if (errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25.0,
                      vertical: 10.0,
                    ),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                const SizedBox(height: 25),
                MyButton(text: "Sign In", onTap: signUserIn),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
