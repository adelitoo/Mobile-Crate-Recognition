# 📦 Crate App - Mobile Crate Recognition System

A Flutter-based mobile application for scanning and managing crates, bottles, and kegs with real-time location tracking and client management.

## 🚀 Features

- 📸 **Crate Scanning**: Scan crates, bottles, and kegs using your device's camera
- 📍 **Location Tracking**: Real-time location tracking with Google Maps integration
- 👥 **Client Management**: Manage multiple clients and their locations
- 📊 **Inventory Tracking**: Keep track of items and their quantities
- 📱 **Cross-Platform**: Works on iOS and Android devices

## 📋 Prerequisites

- Flutter SDK (version 3.7.0 or higher)
- Dart SDK
- Android Studio / Xcode for mobile development
- Google Maps API Key
- Camera access permissions
- Location services enabled
- Python 3.x
- MySQL Server
- Virtual Environment (venv)

## 🛠️ Installation

1. Clone the repository:
```bash
git clone [repository-url]
cd Mobile-Crate-Recognition/mobile-app/crate_app/
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Google Maps API:
   - Add your Google Maps API key in:
     - `android/app/src/main/AndroidManifest.xml`
     - `ios/Runner/AppDelegate.swift`

4. Run the app:
```bash
flutter run
```

## 🔧 Backend Setup

### 🐍 Python Backend
1. Navigate to the backend directory:
```bash
cd backend
```

2. Create and activate virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows use: venv\Scripts\activate
```

3. Install Python dependencies:
```bash
pip install -r requirements.txt
```

4. Start the backend server:
```bash
python app.py
```

### 🗄️ Database Setup
1. Start MySQL server
2. Access MySQL command line:
```bash
mysql -u root -p
```
3. Enter your MySQL root password when prompted : test1234

## 📱 How to Use

### 🔐 Login
- Launch the app
- Select the employer
- Default password: password123
- Grant necessary permissions (camera, location)

### 🗺️ Map View
- View your current location on the map
- See nearby client locations
- Use the location button to recenter the map

### 📸 Scanning Items
1. Tap the "Scan" button on the home screen
2. Position the item within the camera guide
3. Take the photo
4. Review the detected items
5. Adjust quantities if needed

### 📊 Managing Items
- Add new items manually
- Adjust quantities using + and - buttons
- View total count and price
- Select client from the dropdown menu

### 📄 Generating Reports
- View scanned items and their quantities
- Generate PDF reports
- Share reports with clients

## 🔒 Permissions Required

- Camera access for scanning items
- Location services for map functionality
- Storage access for saving reports

## 🆘 Troubleshooting

If you encounter any issues:
1. Ensure all permissions are granted
2. Check your internet connection
3. Verify Google Maps API key is correctly configured
4. Make sure location services are enabled
5. Ensure the backend server is running
6. Verify MySQL server is running and accessible
