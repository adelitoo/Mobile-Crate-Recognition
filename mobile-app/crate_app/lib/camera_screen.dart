import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({super.key, required this.camera});
  final CameraDescription camera;

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
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isProcessing = false; // To track if image is being processed

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.veryHigh);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(),
            ), // Show loading circle when processing
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            setState(() {
              _isProcessing = true; // Start processing
            });

            await _initializeControllerFuture;
            final image = await _controller.takePicture();

            if (!context.mounted) return;

            await sendImageToBackend(image.path, context);
          } catch (e) {
            print(e);
          } finally {
            setState(() {
              _isProcessing = false; // Stop processing when done
            });
          }
        },
        child: Image.asset(
          'assets/images/icon/take_photo.png',
          width: 800,
          height: 800,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final imageFile = File(imagePath);

    if (!imageFile.existsSync()) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: Image not found at $imagePath')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Processed Image')),
      body: Center(
        child:
            imageFile.existsSync()
                ? Image.file(imageFile)
                : const CircularProgressIndicator(), // Show a loading spinner while the image loads
      ),
    );
  }
}
