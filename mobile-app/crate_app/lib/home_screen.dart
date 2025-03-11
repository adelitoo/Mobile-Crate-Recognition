import 'package:camera/camera.dart';
import 'package:crate_app/camera_screen.dart';
import 'package:flutter/material.dart';

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
              'Home',
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
                onPressed: () async {
                  final cameras = await availableCameras();
                  final firstCamera = cameras.first;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => TakePictureScreen(camera: firstCamera),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Background color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      30.0,
                    ), // Rounded corners
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 15,
                  ), // Button size
                  elevation: 5, // Subtle shadow
                ),
                child: const Text(
                  'Scan',
                  style: TextStyle(
                    fontFamily: 'SFPro',
                    color: Colors.white, // Text color
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
