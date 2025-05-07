import 'package:camera/camera.dart';
import 'package:crate_app/camera_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crate_app/login_screen.dart';
import 'config/app_config.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LatLng? currentLocation;
  late GoogleMapController _mapController;
  final Map<String, Marker> _markers = {};

  void signUserOut() {
    // Navigate back to login screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<void> getClientsCoordinates() async {
    try {
      final response = await http.get(
        Uri.parse(AppConfig.clientsEndpoint),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        addUserMarkers(data);
      } else {
        print('Failed to call Python script: ${response.statusCode}');
      }
    } catch (e) {
      print('Error calling Python script: $e');
    }
  }

  void addUserMarkers(List<dynamic> usersInfo) async {
    for (var userData in usersInfo) {
      double latitude = userData['latitude'];
      double longitude = userData['longitude'];
      String name = userData['name'];

      LatLng userLocation = LatLng(latitude, longitude);

      var markerIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(),
        'assets/images/icon/restaurant.png',
      );

      final resizedIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(100, 100)),
        'assets/images/icon/restaurant.png',
      );

      var marker = Marker(
        markerId: MarkerId(name),
        position: userLocation,
        infoWindow: InfoWindow(title: name, snippet: 'Location of $name'),
        icon: resizedIcon, // Use the resized icon
        onTap: () {
          showCustomSnackBar('$name');
        },
      );

      setState(() {
        _markers[name] = marker;
      });
    }
  }

  void showCustomSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontSize: 16.0, color: Colors.white),
        ),
        backgroundColor: Colors.black.withOpacity(0.8), // Dark background color
        duration: Duration(seconds: 2), // Duration similar to iOS-style
        behavior: SnackBarBehavior.floating, // Floating style
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0), // Rounded corners
        ),
        margin: EdgeInsets.fromLTRB(16.0, 100.0, 16.0, 16.0),
      ),
    );
  }

  Future<void> getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
    });

    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(currentLocation!, 14),
    );

    addMarker('currentLocation', currentLocation!);

    await getClientsCoordinates();
  }

  void addMarker(String markerId, LatLng location) async {
    var markerIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(),
      'assets/images/icon/truck.png',
    );

    var marker = Marker(
      markerId: MarkerId(markerId),
      position: location,
      infoWindow: const InfoWindow(
        title: 'You',
        snippet: 'This is your current location',
      ),
      icon: markerIcon,
    );
    _markers[markerId] = marker;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Home title
          const Padding(
            padding: EdgeInsets.fromLTRB(30, 70, 0, 0),
            child: Text(
              "Home🏠",
              style: TextStyle(
                fontFamily: 'SFPro',
                fontSize: 42,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.9,
              ),
            ),
          ),
          // Logout button
          Positioned(
            top: 75,
            right: 30,
            child: IconButton(
              onPressed: () async {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => CupertinoAlertDialog(
                        title: const Text('Confirm Logout'),
                        content: const Text(
                          'Are you sure you want to log out?',
                        ),
                        actions: [
                          CupertinoDialogAction(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                            isDefaultAction: true,
                          ),
                          CupertinoDialogAction(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Logout'),
                            isDestructiveAction: true,
                          ),
                        ],
                      ),
                );
                if (shouldLogout == true) {
                  signUserOut();
                }
              },
              icon: const Icon(Icons.logout),
              iconSize: 28,
              color: Colors.black,
            ),
          ),
          // User Info
          Positioned(
            top: 140,
            left: 30,
            right: 30,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB(255, 172, 170, 170).withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage:
                        const AssetImage('assets/images/icon/default_user.png')
                            as ImageProvider,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.username,
                        style: const TextStyle(
                          fontFamily: 'SFPro',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "Welcome back!",
                        style: TextStyle(
                          fontFamily: 'SFPro',
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Google Map
          Positioned(
            top: 260,
            left: 30,
            right: 30,
            child: Container(
              height: 520,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(
                      255,
                      172,
                      170,
                      170,
                    ).withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: currentLocation ?? LatLng(0, 0),
                        zoom: 14.0,
                      ),
                      markers: Set<Marker>.of(_markers.values),
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                      },
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 5,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () {
                            if (currentLocation != null) {
                              _mapController.animateCamera(
                                CameraUpdate.newLatLngZoom(
                                  currentLocation!,
                                  14,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.my_location),
                          color: Colors.blue,
                          iconSize: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Scan button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    final cameras = await availableCameras();
                    final firstCamera = cameras.first;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => TakePictureScreen(
                              camera: firstCamera,
                              username: widget.username,
                            ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 16,
                    ),
                    elevation: 0,
                    minimumSize: const Size(200, 55),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.camera_alt_rounded, size: 20),
                      const SizedBox(width: 10),
                      const Text(
                        'Scan',
                        style: TextStyle(
                          fontFamily: 'SFPro',
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
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
