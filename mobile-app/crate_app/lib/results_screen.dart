import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'services/pdf_generator.dart';
import 'package:crate_app/home_screen.dart';
import 'package:geolocator/geolocator.dart';

class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;
  final Map<String, dynamic> itemCounts;
  final String username;

  const DisplayPictureScreen({
    super.key,
    required this.imagePath,
    required this.itemCounts,
    required this.username,
  });

  @override
  State<DisplayPictureScreen> createState() => _DisplayPictureScreenState();
}

Future<void> sendImageToBackend(
  String imagePath,
  BuildContext context,
  String username,
) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('http://192.168.1.27:5000/upload'),
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
              username: username,
            ),
      ),
    );
  } else {
    print("Failed to process image: ${streamedResponse.statusCode}");
  }
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  late Map<String, int> counts;
  late Map<String, double?> prices;
  String? selectedClient;
  List<String> clients = [];
  bool isLoadingClients = true;

  // Instance of our PDF generator service
  final PdfGeneratorService _pdfGenerator = PdfGeneratorService();

  @override
  void initState() {
    super.initState();
    // Parse counts and prices from itemCounts
    counts = {};
    prices = {};
    widget.itemCounts.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        counts[key] = int.tryParse(value['count'].toString()) ?? 0;
        var priceVal = value['price'];
        if (priceVal == null || priceVal == 'N/A') {
          prices[key] = null;
        } else {
          prices[key] = double.tryParse(priceVal.toString());
        }
      } else {
        counts[key] = int.tryParse(value.toString()) ?? 0;
        prices[key] = null;
      }
    });
    _loadClients();
  }

  Future<void> _loadClients() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.27:5000/clients'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          clients = data.map((client) => client['name'] as String).toList();
          isLoadingClients = false;
        });

        // Get the nearest client based on current location
        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          final nearestResponse = await http.get(
            Uri.parse('http://192.168.1.27:5000/nearest_client').replace(
              queryParameters: {
                'lat': position.latitude.toString(),
                'lon': position.longitude.toString(),
              },
            ),
            headers: {'Content-Type': 'application/json'},
          );

          if (nearestResponse.statusCode == 200) {
            final data = jsonDecode(nearestResponse.body);
            final nearestClient = data['name'];
            if (nearestClient != null && clients.contains(nearestClient)) {
              setState(() {
                selectedClient = nearestClient;
              });
            }
          }
        } catch (e) {
          print('Error getting nearest client: $e');
        }
      }
    } catch (e) {
      print('Error loading clients: $e');
      setState(() {
        isLoadingClients = false;
      });
    }
  }

  void _incrementCount(String item) {
    setState(() {
      counts[item] = (counts[item] ?? 0) + 1;
    });
  }

  void _decrementCount(String item) {
    setState(() {
      counts[item] = max((counts[item] ?? 0) - 1, 0);
      if (counts[item] == 0) {
        counts.remove(item);
        prices.remove(item);
      }
    });
  }

  void _addNewItem() {
    showDialog(
      context: context,
      builder: (context) {
        String newItemName = '';
        String newItemPrice = '';
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
              SizedBox(height: 10),
              CupertinoTextField(
                placeholder: "Price (optional)",
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) => newItemPrice = value,
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
                    prices[newItemName] = double.tryParse(newItemPrice) ?? null;
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

  double getTotalPrice() {
    double total = 0.0;
    counts.forEach((item, count) {
      final price = prices[item];
      if (price != null) {
        total += price * count;
      }
    });
    return total;
  }

  // Method to open full screen image view
  void _openFullScreenImage(BuildContext context, File imageFile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageView(imageFile: imageFile),
      ),
    );
  }

  // Add this function to return the emoji based on the entry.key
  String _getEmojiForItem(String item) {
    if (item.toLowerCase().contains('birra')) {
      return '🍺'; // Beer keg emoji
    } else if (item.toLowerCase().contains('acqua')) {
      return '💧'; // Water bottle emoji
    } else {
      return '📦'; // Default to crates emoji for other items
    }
  }

  // Generate PDF invoice and then navigate to home only if successful
  Future<void> _generateInvoiceAndGoHome() async {
    // Show progress dialog immediately
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => WillPopScope(
            onWillPop: () async => false,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        CupertinoColors.activeBlue,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Generating invoice...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    // Validate client selection
    if (selectedClient == null) {
      // Close the progress dialog
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a client'),
          backgroundColor: CupertinoColors.activeOrange,
        ),
      );
      return;
    }

    // Convert counts map to the format expected by PDF generator
    final List<Map<String, dynamic>> itemsList =
        counts.entries.map((entry) {
          return {
            'name': entry.key,
            'count': entry.value,
            'price': prices[entry.key],
          };
        }).toList();

    // Generate and save the PDF, get the result status
    final bool success = await _pdfGenerator.generateAndSavePdf(
      imagePath: widget.imagePath,
      items: itemsList,
      context: context,
      clientName: selectedClient!,
      employeeName: widget.username,
    );

    // If not mounted anymore, exit
    if (!mounted) return;

    // Close the progress dialog
    Navigator.of(context).pop();

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

  @override
  Widget build(BuildContext context) {
    final imageFile = File(widget.imagePath);
    final totalCount = getTotalCount();
    final totalPrice = getTotalPrice();

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
          // Client and Employee Info Section
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Labels
                Padding(
                  padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Text(
                            'Client',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Text(
                            'Employee',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Selection Boxes
                Row(
                  children: [
                    // Client Selection (Left half)
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            hint: Center(
                              child: Text(
                                isLoadingClients
                                    ? 'Loading clients...'
                                    : 'Select Client',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                            value: selectedClient,
                            items:
                                clients.map((String client) {
                                  return DropdownMenuItem<String>(
                                    value: client,
                                    child: Center(child: Text(client)),
                                  );
                                }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedClient = newValue;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16), // Spacing between the two sections
                    // Employee Name (Right half)
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person,
                                color: Colors.blue[600],
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                widget.username,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Image section with card wrapper
          Padding(
            padding: const EdgeInsets.only(
              left: 12.0,
              right: 12.0,
              bottom: 12.0,
            ),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Item Counts',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'SFPro',
                                ),
                              ),
                              Row(
                                children: [
                                  // Add button
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.add,
                                        color: CupertinoColors.activeBlue,
                                        size: 20,
                                      ),
                                      onPressed: _addNewItem,
                                      tooltip: 'Add Item',
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  // Save button
                                  Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.activeBlue,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: CupertinoColors.activeBlue
                                              .withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: MaterialButton(
                                      onPressed: _generateInvoiceAndGoHome,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.save,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Save',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Expanded(
                            child: ListView.builder(
                              itemCount: counts.length,
                              itemBuilder: (context, index) {
                                final entry = counts.entries.elementAt(index);
                                final price = prices[entry.key];
                                return Dismissible(
                                  key: Key(entry.key),
                                  direction: DismissDirection.endToStart,
                                  onDismissed: (direction) {
                                    setState(() {
                                      counts.remove(entry.key);
                                      prices.remove(entry.key);
                                    });
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
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              entry.key,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            price != null
                                                ? 'CHF ${price.toStringAsFixed(2)}'
                                                : 'N/A',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Decrement button (smaller)
                                          IconButton(
                                            iconSize: 18,
                                            padding: EdgeInsets.zero,
                                            constraints: BoxConstraints(),
                                            icon: Container(
                                              padding: EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.red[50],
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.red
                                                        .withOpacity(0.15),
                                                    blurRadius: 3,
                                                    offset: Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                Icons.remove,
                                                size: 16,
                                                color: Colors.red[700],
                                              ),
                                            ),
                                            onPressed:
                                                () =>
                                                    _decrementCount(entry.key),
                                          ),
                                          // Count display (smaller)
                                          Container(
                                            width: 32,
                                            height: 32,
                                            margin: EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.07),
                                                  blurRadius: 2,
                                                  offset: Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              '${entry.value}',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          // Increment button (smaller)
                                          IconButton(
                                            iconSize: 18,
                                            padding: EdgeInsets.zero,
                                            constraints: BoxConstraints(),
                                            icon: Container(
                                              padding: EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.green[50],
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.green
                                                        .withOpacity(0.15),
                                                    blurRadius: 3,
                                                    offset: Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                Icons.add,
                                                size: 16,
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
                          // Total price display
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 16.0,
                              right: 8.0,
                              left: 8.0,
                              bottom: 4.0,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.07),
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.shopping_cart,
                                        color: Colors.blue[800],
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Total',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue[900],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'CHF ' + totalPrice.toStringAsFixed(2),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[800],
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
        ],
      ),
      floatingActionButton: null,
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
