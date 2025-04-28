import 'package:camera/camera.dart';
import 'package:crate_app/camera_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LatLng? currentLocation;
  late GoogleMapController _mapController;
  final Map<String, Marker> _markers = {};
  final user = FirebaseAuth.instance.currentUser;
  List<dynamic> usersInfo = [];

  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  Future<void> getClientsCoordinates() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.27:5000/clients'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          usersInfo = data;
        });
        print('Received data from Python: $usersInfo');
        addUserMarkers(); // Add markers for each user
      } else {
        print('Failed to call Python script: ${response.statusCode}');
      }
    } catch (e) {
      print('Error calling Python script: $e');
    }
  }

  // Add markers for each user
  void addUserMarkers() {
    for (var userData in usersInfo) {
      double latitude = userData['latitude'];
      double longitude = userData['longitude'];
      String name = userData['name'];

      LatLng userLocation = LatLng(latitude, longitude);

      var marker = Marker(
        markerId: MarkerId(name), // Use the name as a unique identifier
        position: userLocation,
        infoWindow: InfoWindow(title: name, snippet: 'Location of $name'),
      );

      setState(() {
        _markers[name] = marker;
      });
    }
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
                        user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : const AssetImage(
                                  'assets/images/icon/default_user.png',
                                )
                                as ImageProvider,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? user?.email ?? "User",
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
              height: 550,
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
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: currentLocation ?? LatLng(46.0100800, 8.9600400),
                    zoom: 14,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (currentLocation != null) {
                      addMarker('currentLocation', currentLocation!);
                    }
                  },
                  markers: _markers.values.toSet(),
                ),
              ),
            ),
          ),
          // Scan button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 40),
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
                            (context) => TakePictureScreen(camera: firstCamera),
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
