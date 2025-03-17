import 'package:crate_app/login_screen.dart';
import 'package:flutter/material.dart';

import 'register_screen.dart';

class LoginOrRegisteredScreen extends StatefulWidget {
  const LoginOrRegisteredScreen({super.key});

  @override
  State<LoginOrRegisteredScreen> createState() =>
      _LoginOrRegisteredScreenState();
}

class _LoginOrRegisteredScreenState extends State<LoginOrRegisteredScreen> {
  // initally show login page
  bool showLoginPage = true;

  // toggle between login and register page
  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginScreen(onTap: togglePages);
    } else {
      return RegisterScreen(onTap: togglePages);
    }
  }
}
