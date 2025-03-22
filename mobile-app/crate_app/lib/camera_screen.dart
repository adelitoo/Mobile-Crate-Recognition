import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

// New screen that can change over time (hence, StatefulWidget)
class TakePictureScreen extends StatefulWidget {
  // Constructor that takes as a parameter the camera and is mandatory
  const TakePictureScreen({super.key, required this.camera});
  // Stores the camera, either front or back
  final CameraDescription camera;

  // ???
  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

Future<void> sendImageToBackend(String imagePath, BuildContext context) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('http://192.168.1.55:5000/upload'),
  );

  request.files.add(await http.MultipartFile.fromPath('image', imagePath));

  var response = await request.send();

  if (response.statusCode == 200) {
    final bytes = await response.stream.toBytes();
    final tempFile = File('${imagePath}_processed.jpg');
    await tempFile.writeAsBytes(bytes);

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DisplayPictureScreen(imagePath: tempFile.path),
      ),
    );
  } else {
    print("Failed to process image");
  }
}

class TakePictureScreenState extends State<TakePictureScreen> {
  // Camera controller -> turning it on, taking pics, etc ...
  late CameraController _controller;
  // Stores the camaera init process
  late Future<void> _initializeControllerFuture;

  // Function called as soon as the page loads
  @override
  void initState() {
    // Good practice
    super.initState();
    // Connect the camera to the controller
    _controller = CameraController(widget.camera, ResolutionPreset.veryHigh);
    // Starts the camera and stores the result
    _initializeControllerFuture = _controller.initialize();
  }

  // Called when the screen is removed
  @override
  void dispose() {
    // Frees up the camera so other apps can use it
    _controller.dispose();
    // Good practice
    super.dispose();
  }

  // Builds the screen UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Allows the AppBar to overlay the camera
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Makes the AppBar transparent
        elevation: 0, // Removes shadow
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ), // Ensures visibility
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_controller);
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            final image = await _controller.takePicture();

            if (!context.mounted) return;

            await sendImageToBackend(image.path, context);
          } catch (e) {
            print(e);
          }
        },
        child: Image.asset(
          'assets/images/icon/take_photo.png',
          width: 800,
          height: 800,
        ),
        backgroundColor: Colors.transparent, // Makes FAB background transparent
        elevation: 0, // Removes shadow if desired      ),
      ),
    );
  }
}

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Display the Picture')),
      body: Image.file(File(imagePath)),
    );
  }
}
