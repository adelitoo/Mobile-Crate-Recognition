import 'package:camera/camera.dart';
import 'package:crate_app/camera_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

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

  void signUserOut() {
    FirebaseAuth.instance.signOut();
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
          Positioned(
            top: 75,
            right: 30,
            child: IconButton(
              onPressed: signUserOut,
              icon: const Icon(Icons.logout),
              iconSize: 28,
              color: Colors.black,
            ),
          ),

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
                    color: Color.fromARGB(255, 172, 170, 170).withValues(),
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
                    color:
                        const Color.fromARGB(255, 172, 170, 170).withValues(),
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
