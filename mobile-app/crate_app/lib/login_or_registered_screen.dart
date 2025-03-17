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
  final PageController _pageController = PageController();
  bool showLoginPage = true;

  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
      _pageController.animateToPage(
        showLoginPage ? 0 : 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          showLoginPage = index == 0;
        });
      },
      children: [
        LoginScreen(onTap: togglePages),
        RegisterScreen(onTap: togglePages),
      ],
    );
  }
}
