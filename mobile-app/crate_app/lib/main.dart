import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  // Keep the splash screen as long as the home page is not initialized
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Future.delayed(Duration(seconds: 2));
  FlutterNativeSplash.remove();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const HomeScreen());
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Title at top left corner
          const Padding(
            padding: EdgeInsets.fromLTRB(30, 70, 0, 0),
            child: Text(
              'Home 🏠',
              style: TextStyle(
                fontFamily: 'SFPro',
                fontSize: 42,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          // Centered Scan button at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 40),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Background color (iPhone buttons are often blue)
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0), // Rounded corners
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15), // Adjust the size of the button
                  elevation: 5, // Subtle shadow for a raised effect
                ),
                child: const Text(
                  'Scan',
                  style: TextStyle(
                    fontFamily: 'SFPro',
                    color: Colors.white, // Text color (iPhone buttons often have white text)
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
