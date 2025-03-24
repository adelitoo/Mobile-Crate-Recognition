import 'dart:async';
import 'dart:convert';
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

  var streamedResponse = await request.send();

  if (streamedResponse.statusCode == 200) {
    // Get a regular http.Response from the streamed response
    final response = await http.Response.fromStream(streamedResponse);

    // Print all headers to debug
    print("All response headers: ${response.headers}");

    // Get the JSON string from the header
    final itemCountsJson = response.headers['item-counts'] ?? '{}';
    print("Item counts JSON: $itemCountsJson");

    // Parse the JSON string to a Map
    Map<String, dynamic> itemCounts = {};
    try {
      itemCounts = Map<String, dynamic>.from(json.decode(itemCountsJson));
    } catch (e) {
      print("Error parsing item counts: $e");
    }

    // Save the image
    final tempFile = File('${imagePath}_processed.jpg');
    await tempFile.writeAsBytes(response.bodyBytes);

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => DisplayPictureScreen(
              imagePath: tempFile.path,
              itemCounts: itemCounts,
            ),
      ),
    );
  } else {
    print("Failed to process image: ${streamedResponse.statusCode}");
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
        leading: Padding(
          padding: const EdgeInsets.only(
            left: 20,
            top: 10,
          ), // Adjust padding to move right and down
          child: Container(
            width: 50, // Fixed width for the circle
            height: 50, // Fixed height for the circle
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(
                0.6,
              ), // Semi-transparent black background
            ),
            child: Center(
              child: IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                iconSize: 24, // Adjust icon size if needed
              ),
            ),
          ),
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
  final Map<String, dynamic> itemCounts;

  const DisplayPictureScreen({
    super.key,
    required this.imagePath,
    required this.itemCounts,
  });

  @override
  Widget build(BuildContext context) {
    final imageFile = File(imagePath);

    return Scaffold(
      appBar: AppBar(title: const Text('Processed Image')),
      body: Column(
        children: [
          Expanded(
            child:
                imageFile.existsSync()
                    ? Image.file(imageFile)
                    : const CircularProgressIndicator(),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detected Items:',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // If no items detected
                if (itemCounts.isEmpty)
                  Text('No items detected', style: TextStyle(fontSize: 18)),
                // Display each item and its count
                ...itemCounts.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      '${entry.key}: ${entry.value}',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
