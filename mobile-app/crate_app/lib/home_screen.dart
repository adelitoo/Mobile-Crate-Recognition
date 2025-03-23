import 'package:camera/camera.dart';
import 'package:crate_app/camera_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LatLng currentLocation = LatLng(46.0100800, 8.9600400);
  late GoogleMapController _mapController;
  Map<String, Marker> _markers = {};
  final user = FirebaseAuth.instance.currentUser;

  void signUserOut() {
    FirebaseAuth.instance.signOut();
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
        statusBarColor: Colors.black, // Makes status bar black
        statusBarIconBrightness: Brightness.light, // Ensures icons stay white
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Title at top left corner
          const Padding(
            padding: EdgeInsets.fromLTRB(30, 70, 0, 0),
            child: Text(
              "Home",
              style: TextStyle(
                fontFamily: 'SFPro',
                fontSize: 42,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          // Logout icon at top right corner
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

          // User Info Card (iPhone widget style)
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
                    color: Colors.black.withOpacity(0.1),
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
              height: 550, // Set a specific height
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
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
                    target: currentLocation,
                    zoom: 14,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    addMarker('test', currentLocation);
                  },
                  markers: _markers.values.toSet(),
                ),
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
