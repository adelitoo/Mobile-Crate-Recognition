import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'services/pdf_generator.dart'; // Import the PDF generator service

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

Future<void> sendImageToBackend(String imagePath, BuildContext context) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('http://192.168.1.125:5000/upload'),
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

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  late Map<String, int> counts;

  // Instance of our PDF generator service
  final PdfGeneratorService _pdfGenerator = PdfGeneratorService();

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

        return CupertinoAlertDialog(
          title: Text(
            "Add New Item",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            children: [
              SizedBox(height: 10),
              CupertinoTextField(
                placeholder: "Item name",
                onChanged: (value) => newItemName = value,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(
                "Cancel",
                style: TextStyle(color: CupertinoColors.activeBlue),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text(
                "Add",
                style: TextStyle(color: CupertinoColors.activeBlue),
              ),
              onPressed: () {
                if (newItemName.isNotEmpty) {
                  setState(() {
                    counts[newItemName] = 1;
                  });
                }
                Navigator.pop(context);
              },
            ),
          ],
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

  // Generate PDF invoice and then navigate to home only if successful
  Future<void> _generateInvoiceAndGoHome() async {
    // Convert counts map to the format expected by PDF generator
    final List<Map<String, dynamic>> itemsList =
        counts.entries.map((entry) {
          return {'name': entry.key, 'count': entry.value};
        }).toList();

    // Generate and save the PDF, get the result status
    final bool success = await _pdfGenerator.generateAndSavePdf(
      imagePath: widget.imagePath,
      items: itemsList,
      context: context,
    );

    // If not mounted anymore, exit
    if (!mounted) return;

    // Only proceed with success message and navigation if PDF was created successfully
    if (success) {
      // Show a confirmation message with styling matching the other SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invoice generated successfully!'),
          backgroundColor: CupertinoColors.activeGreen,
        ),
      );

      // Navigate to home page (clearing all previous routes)
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saving interrupted!'),
          backgroundColor: CupertinoColors.activeOrange,
        ),
      );
    }
  }

  // Add this function to return the emoji based on the entry.key
  String _getEmojiForItem(String item) {
    if (item.toLowerCase().contains('keg')) {
      return '🍺'; // Beer keg emoji
    } else if (item.toLowerCase().contains('bottle')) {
      return '💧'; // Water bottle emoji
    } else {
      return '📦'; // Default to crates emoji for other items
    }
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
              showDialog(
                context: context,
                builder:
                    (context) => CupertinoAlertDialog(
                      title: Text(
                        "Need Help?",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      content: Text(
                        "Adjust item counts as needed and tap Save when done.",
                        style: TextStyle(fontSize: 16),
                      ),
                      actions: [
                        CupertinoDialogAction(
                          child: Text(
                            "Got it",
                            style: TextStyle(
                              color: CupertinoColors.activeBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
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
                          //color: Theme.of(context).primaryColor,
                          color: Colors.blue.withOpacity(0.3),
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
                            SizedBox(height: 24),
                            Text(
                              'No items detected',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 80),
                            ElevatedButton.icon(
                              onPressed: _addNewItem,
                              icon: Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 20,
                              ),
                              label: Text(
                                'Add Item',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: CupertinoColors.activeBlue,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                                shadowColor: Colors.black.withOpacity(0.3),
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
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'SFPro',
                            ),
                          ),
                          SizedBox(height: 20),
                          Expanded(
                            child: ListView.builder(
                              padding: EdgeInsets.only(
                                bottom: counts.isNotEmpty ? 130 : 0,
                              ),
                              itemCount: counts.length,
                              itemBuilder: (context, index) {
                                final entry = counts.entries.elementAt(index);
                                return Dismissible(
                                  key: Key(
                                    entry.key,
                                  ), // Unique key for each dismissible item
                                  direction:
                                      DismissDirection
                                          .endToStart, // Swipe direction
                                  onDismissed: (direction) {
                                    // Remove item when swiped
                                    setState(() {
                                      counts.remove(entry.key);
                                    });
                                    // Optionally, show a snackbar or confirmation
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${entry.key} removed'),
                                      ),
                                    );
                                  },
                                  background: Container(
                                    decoration: BoxDecoration(
                                      color:
                                          Colors
                                              .red[400], // Background color for swipe
                                      borderRadius: BorderRadius.circular(
                                        12,
                                      ), // Add the border radius
                                    ),
                                    alignment: Alignment.centerRight,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),

                                  child: Container(
                                    margin: EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        20,
                                      ), // Adjust border radius for consistency
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color.fromARGB(
                                            255,
                                            172,
                                            170,
                                            170,
                                          ).withOpacity(
                                            0.3,
                                          ), // Apply shadow color
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                          offset: Offset(
                                            0,
                                            5,
                                          ), // Offset of the shadow
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.white,
                                        child: Text(
                                          _getEmojiForItem(
                                            entry.key,
                                          ), // Call the function to get the emoji based on the key
                                          style: TextStyle(
                                            fontSize:
                                                32, // Adjust the font size as needed
                                            color:
                                                Colors
                                                    .white, // Set text color to white for contrast
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
                                          // Decrement button with a soft design
                                          IconButton(
                                            icon: Container(
                                              padding: EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color:
                                                    Colors
                                                        .red[50], // Lighter red for a softer look
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.red
                                                        .withOpacity(0.3),
                                                    blurRadius: 6,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                Icons.remove,
                                                size: 22,
                                                color: Colors.red[700],
                                              ),
                                            ),
                                            onPressed:
                                                () =>
                                                    _decrementCount(entry.key),
                                          ),

                                          // Count display container with smooth edges and a light background
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius: BorderRadius.circular(
                                                12,
                                              ), // Rounded corners for the number container
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.1),
                                                  blurRadius: 6,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              '${entry.value}',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    Colors
                                                        .black87, // Darker text for better readability
                                              ),
                                            ),
                                          ),

                                          // Increment button with a subtle hover effect
                                          IconButton(
                                            icon: Container(
                                              padding: EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color:
                                                    Colors
                                                        .green[50], // Lighter green for a subtle look
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.green
                                                        .withOpacity(0.3),
                                                    blurRadius: 6,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                Icons.add,
                                                size: 22,
                                                color: Colors.green[700],
                                              ),
                                            ),
                                            onPressed:
                                                () =>
                                                    _incrementCount(entry.key),
                                          ),
                                        ],
                                      ),
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
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                heroTag: 'addItem',
                onPressed: _addNewItem,
                backgroundColor: CupertinoColors.activeGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(Icons.add, color: Colors.white, size: 24),
              ),
            ),
            SizedBox(height: 10),
            // Generate Invoice button
            Container(
              width: 180,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                heroTag: 'generateInvoice',
                onPressed: () {
                  _generateInvoiceAndGoHome();
                },
                label: Text(
                  'Generate Invoice',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                icon: Icon(Icons.receipt_long, size: 22, color: Colors.white),
                backgroundColor: CupertinoColors.activeBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
            SizedBox(height: 10),
          ],
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
