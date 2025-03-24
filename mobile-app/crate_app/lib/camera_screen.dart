import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
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
          padding: const EdgeInsets.only(left: 20, top: 10),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                iconSize: 24,
              ),
            ),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            'Take Photo',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 3.0,
                  color: Colors.black.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
        centerTitle: true,
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
                  return Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                }
              },
            ),
          ),
          // Camera guide overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.transparent),
              ),
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.width * 0.8,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          // Processing overlay
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 20),
                      Text(
                        'Analyzing image...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () async {
            try {
              setState(() {
                _isProcessing = true;
              });

              await _initializeControllerFuture;
              final image = await _controller.takePicture();

              if (!context.mounted) return;

              await sendImageToBackend(image.path, context);
            } catch (e) {
              print(e);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            } finally {
              setState(() {
                _isProcessing = false;
              });
            }
          },
          child: Image.asset(
            'assets/images/icon/take_photo.png',
            width: 60,
            height: 60,
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
    );
  }
}

class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;
  final Map<String, dynamic> itemCounts;

  const DisplayPictureScreen({
    super.key,
    required this.imagePath,
    required this.itemCounts,
  });

  @override
  State<DisplayPictureScreen> createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  late Map<String, int> counts;

  // Brand colors for common beverages
  final Map<String, Color> brandColors = {
    'Perrier': Color(0xFF85C441),
    'San Clemente': Color(0xFF00A3E0),
    'Valsers': Color(0xFF0078C1),
    'Coca Cola': Color(0xFFE61A27),
    'Pepsi': Color(0xFF005CB4),
    'Sprite': Color(0xFF008B47),
    'Evian': Color(0xFFFF85AB),
    'San Pellegrino': Color(0xFFE71B2A),
  };

  Color getBrandColor(String brand) {
    return brandColors[brand] ?? Colors.blueGrey;
  }

  @override
  void initState() {
    super.initState();
    // Convert the dynamic values to int
    counts = Map<String, int>.from(
      widget.itemCounts.map(
        (key, value) => MapEntry(key, int.tryParse(value.toString()) ?? 0),
      ),
    );
  }

  void _incrementCount(String item) {
    setState(() {
      counts[item] = (counts[item] ?? 0) + 1;
    });
  }

  void _decrementCount(String item) {
    setState(() {
      counts[item] = max((counts[item] ?? 0) - 1, 0);
      // Remove if count reaches 0
      if (counts[item] == 0) {
        counts.remove(item);
      }
    });
  }

  void _addNewItem() {
    showDialog(
      context: context,
      builder: (context) {
        String newItemName = '';

        return AlertDialog(
          title: Text('Add New Item'),
          content: TextField(
            onChanged: (value) {
              newItemName = value;
            },
            decoration: InputDecoration(
              hintText: "Item name",
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (newItemName.isNotEmpty) {
                    counts[newItemName] = 1;
                  }
                });
                Navigator.pop(context);
              },
              child: Text('Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  int getTotalCount() {
    return counts.values.fold(0, (prev, count) => prev + count);
  }

  // Method to open full screen image view
  void _openFullScreenImage(BuildContext context, File imageFile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageView(imageFile: imageFile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageFile = File(widget.imagePath);
    final totalCount = getTotalCount();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Detected Items',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Adjust item counts as needed and tap Save when done',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Image section with card wrapper
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior:
                  Clip.antiAlias, // Ensures the image respects the card's rounded corners
              child: InkWell(
                onTap: () => _openFullScreenImage(context, imageFile),
                child: Stack(
                  children: [
                    // Image
                    Container(
                      height: MediaQuery.of(context).size.height * 0.35,
                      width: double.infinity,
                      child:
                          imageFile.existsSync()
                              ? Image.file(imageFile, fit: BoxFit.cover)
                              : const Center(
                                child: CircularProgressIndicator(),
                              ),
                    ),

                    // Gradient overlay at the bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Total count badge
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.inventory_2,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              '$totalCount items',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Tap to view icon
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.fullscreen,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Tap to view',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Items list
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child:
                  counts.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No items detected',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _addNewItem,
                              icon: Icon(Icons.add),
                              label: Text('Add Item'),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Item Counts',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          Expanded(
                            child: ListView.builder(
                              itemCount: counts.length,
                              itemBuilder: (context, index) {
                                final entry = counts.entries.elementAt(index);
                                return Card(
                                  margin: EdgeInsets.only(bottom: 12),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: getBrandColor(entry.key),
                                      child: Text(
                                        entry.key.substring(0, 1).toUpperCase(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      entry.key,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Container(
                                            padding: EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(Icons.remove, size: 18),
                                          ),
                                          onPressed:
                                              () => _decrementCount(entry.key),
                                          color: Colors.red[700],
                                        ),
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '${entry.value}',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Container(
                                            padding: EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(Icons.add, size: 18),
                                          ),
                                          onPressed:
                                              () => _incrementCount(entry.key),
                                          color: Colors.green[700],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (counts.isNotEmpty) ...[
            FloatingActionButton(
              heroTag: 'addItem',
              onPressed: _addNewItem,
              child: Icon(Icons.add),
              mini: true,
              backgroundColor: Colors.green,
            ),
            SizedBox(height: 10),
          ],
          FloatingActionButton.extended(
            heroTag: 'saveItems',
            onPressed: () {
              // Save action
              Navigator.pop(context, counts);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Counts saved successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            label: Text('Save'),
            icon: Icon(Icons.save),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }
}

// New class for full screen image view
class FullScreenImageView extends StatelessWidget {
  final File imageFile;

  const FullScreenImageView({super.key, required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () {
          Navigator.of(context).pop();
        },
        child: Center(
          child: Hero(
            tag: 'imageHero',
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(
                imageFile,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
