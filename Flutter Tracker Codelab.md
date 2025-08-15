# Building a Real-Time Location Tracker App with Flutter

## Overview

In this comprehensive codelab, you'll build **Tracker X**, a sophisticated location tracking application that demonstrates real-time location updates, state management with Cubit, Firebase integration, and beautiful UI design with glassmorphism effects.

### What You'll Build

- A location tracking service with permission handling
- Real-time location updates with Firebase Firestore
- Beautiful glassmorphism UI with animations
- Interactive map with live tracking
- Background location tracking
- State management using Flutter Bloc/Cubit

### What You'll Learn

- Advanced location services and permissions
- Real-time data synchronization with Firebase
- State management patterns with Cubit
- Custom UI animations and effects
- Background task processing
- Map integration with Flutter Map

### Prerequisites

- Flutter SDK (latest stable version)
- Basic knowledge of Dart and Flutter
- Android Studio or VS Code
- Firebase project setup
- Understanding of async programming

## Step 1: Project Setup and Dependencies

### Create the Project

```bash
flutter create tracker_x
cd tracker_x
```

### Add Dependencies

Update your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_bloc: ^8.1.3
  
  # Location Services
  geolocator: ^10.1.0
  
  # Firebase
  firebase_core: ^2.24.2
  cloud_firestore: ^4.13.6
  
  # UI Components
  google_fonts: ^6.1.0
  font_awesome_flutter: ^10.6.0
  
  # Map Integration
  flutter_map: ^6.1.0
  latlong2: ^0.8.1
  
  # Local Storage
  hive: ^2.2.3
  path_provider: ^2.1.1
  
  # Background Tasks
  workmanager: ^0.5.1
  
  # HTTP Client
  dio: ^5.3.4

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

Run:
```bash
flutter pub get
```

## Step 2: Core Architecture Setup

### Create Directory Structure

```
lib/
├── core/
│   ├── network/
│   │   └── api_client.dart
│   └── services/
│       ├── location_service.dart
│       └── background_task.dart
├── features/
│   ├── tracking/
│   │   ├── cubit/
│   │   │   ├── tracking_cubit.dart
│   │   │   └── tracking_state.dart
│   │   ├── data/
│   │   │   ├── tracking_repository.dart
│   │   │   └── tracking_local_ds.dart
│   │   └── presentation/
│   │       └── tracking_screen.dart
│   ├── map/
│   │   └── presentation/
│   │       ├── map_screen.dart
│   │       └── layers/
│   │           └── base_tile_layer.dart
│   └── welcome/
│       └── presentation/
│           └── welcome_screen.dart
├── enums/
│   └── map_style.dart
└── main.dart
```

## Step 3: Location Service Implementation

Create `lib/core/services/location_service.dart`:

```dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationService {
  final _controller = StreamController<Position>.broadcast();
  Stream<Position> get stream => _controller.stream;

  Future<bool> ensurePermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  StreamSubscription<Position>? _sub;

  Future<void> start({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilterMeters = 10,
    Duration? interval,
  }) async {
    _sub?.cancel();
    _sub = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilterMeters,
        timeLimit: interval,
      ),
    ).listen(_controller.add);
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<Position?> getOnce() async {
    try {
      return await Geolocator.getCurrentPosition();
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
```

### Key Features Explained:

1. **Stream-based Architecture**: Uses a broadcast StreamController for multiple listeners
2. **Permission Management**: Handles location permissions gracefully
3. **Configurable Settings**: Allows customization of accuracy and distance filters
4. **Error Handling**: Safely handles location service failures

## Step 4: API Client for Remote Data

Create `lib/core/network/api_client.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

class ApiClient {
  final Dio _dio;
  final String baseUrl;

  ApiClient(this.baseUrl) : _dio = Dio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  Future<void> uploadLocation(Position position) async {
    try {
      await _dio.post('/locations', data: {
        'lat': position.latitude,
        'lng': position.longitude,
        'speed': position.speed,
        'accuracy': position.accuracy,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Failed to upload location: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getLocationHistory() async {
    try {
      final response = await _dio.get('/locations');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('Failed to fetch location history: $e');
      return [];
    }
  }
}
```

## Step 5: Local Data Storage

Create `lib/features/tracking/data/tracking_local_ds.dart`:

```dart
import 'package:hive/hive.dart';
import 'package:geolocator/geolocator.dart';

class TrackingLocalDS {
  static const String boxName = 'tracking';
  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(boxName);
  }

  Future<void> saveLocation(Position position) async {
    await _box.add({
      'lat': position.latitude,
      'lng': position.longitude,
      'speed': position.speed,
      'accuracy': position.accuracy,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  List<Map<String, dynamic>> getAllLocations() {
    return _box.values.cast<Map<String, dynamic>>().toList();
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}
```

## Step 6: Repository Pattern Implementation

Create `lib/features/tracking/data/tracking_repository.dart`:

```dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/location_service.dart';
import '../../../core/network/api_client.dart';
import 'tracking_local_ds.dart';

class TrackingRepository {
  final LocationService _locationService;
  final ApiClient _apiClient;
  final TrackingLocalDS _localDS;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TrackingRepository(this._locationService, this._apiClient, this._localDS);

  Stream<Position> get locationStream => _locationService.stream;

  Future<bool> checkPermissions() => _locationService.ensurePermissions();

  Future<void> startTracking() async {
    await _locationService.start();
    
    // Listen to location updates and sync to Firebase
    _locationService.stream.listen((position) {
      _syncLocationToFirebase(position);
      _localDS.saveLocation(position);
    });
  }

  Future<void> stopTracking() => _locationService.stop();

  Future<Position?> getCurrentLocation() => _locationService.getOnce();

  Future<void> _syncLocationToFirebase(Position position) async {
    try {
      await _firestore.collection('locations').add({
        'lat': position.latitude,
        'lng': position.longitude,
        'speed': position.speed,
        'accuracy': position.accuracy,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Firebase sync error: $e');
    }
  }

  void dispose() => _locationService.dispose();
}
```

## Step 7: State Management with Cubit

Create `lib/features/tracking/cubit/tracking_state.dart`:

```dart
import 'package:geolocator/geolocator.dart';
import 'package:equatable/equatable.dart';

abstract class TrackingState extends Equatable {
  const TrackingState();
  
  @override
  List<Object?> get props => [];
}

class TrackingInitial extends TrackingState {}

class TrackingPermissionDenied extends TrackingState {}

class TrackingActive extends TrackingState {
  final Position? position;
  final bool isTracking;

  const TrackingActive({this.position, this.isTracking = false});

  TrackingActive copyWith({Position? position, bool? isTracking}) {
    return TrackingActive(
      position: position ?? this.position,
      isTracking: isTracking ?? this.isTracking,
    );
  }

  @override
  List<Object?> get props => [position, isTracking];
}

class TrackingError extends TrackingState {
  final String message;
  
  const TrackingError(this.message);
  
  @override
  List<Object?> get props => [message];
}
```

Create `lib/features/tracking/cubit/tracking_cubit.dart`:

```dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../data/tracking_repository.dart';
import 'tracking_state.dart';

class TrackingCubit extends Cubit<TrackingState> {
  final TrackingRepository _repository;
  StreamSubscription<Position>? _locationSubscription;

  TrackingCubit(this._repository) : super(TrackingInitial()) {
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await _repository.checkPermissions();
    if (!hasPermission) {
      emit(TrackingPermissionDenied());
      return;
    }
    emit(const TrackingActive());
  }

  Future<void> startTracking() async {
    try {
      await _repository.startTracking();
      
      _locationSubscription?.cancel();
      _locationSubscription = _repository.locationStream.listen(
        (position) {
          if (state is TrackingActive) {
            emit((state as TrackingActive).copyWith(
              position: position,
              isTracking: true,
            ));
          }
        },
        onError: (error) => emit(TrackingError(error.toString())),
      );

      if (state is TrackingActive) {
        emit((state as TrackingActive).copyWith(isTracking: true));
      }
    } catch (e) {
      emit(TrackingError(e.toString()));
    }
  }

  Future<void> stopTracking() async {
    try {
      await _repository.stopTracking();
      await _locationSubscription?.cancel();
      _locationSubscription = null;

      if (state is TrackingActive) {
        emit((state as TrackingActive).copyWith(isTracking: false));
      }
    } catch (e) {
      emit(TrackingError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    _repository.dispose();
    return super.close();
  }
}
```

## Step 8: Beautiful UI Implementation

### Welcome Screen

Create `lib/features/welcome/presentation/welcome_screen.dart` with the glassmorphism design from your provided code.

### Tracking Screen

Create `lib/features/tracking/presentation/tracking_screen.dart` with the beautiful tracking interface from your provided code.

### Map Screen

Create `lib/features/map/presentation/map_screen.dart` with real-time map tracking from your provided code.

## Step 9: Background Task Setup

Create `lib/core/services/background_task.dart`:

```dart
import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Get current location
      final position = await Geolocator.getCurrentPosition();
      
      // Upload to Firebase
      await FirebaseFirestore.instance.collection('locations').add({
        'lat': position.latitude,
        'lng': position.longitude,
        'speed': position.speed,
        'accuracy': position.accuracy,
        'timestamp': FieldValue.serverTimestamp(),
        'background': true,
      });
      
      return Future.value(true);
    } catch (e) {
      print('Background task failed: $e');
      return Future.value(false);
    }
  });
}
```

## Step 10: Main App Setup

Update `lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tracker_x/core/network/api_client.dart';
import 'package:tracker_x/core/services/background_task.dart';
import 'package:tracker_x/core/services/location_service.dart';
import 'package:tracker_x/features/tracking/cubit/tracking_cubit.dart';
import 'package:tracker_x/features/tracking/data/tracking_local_ds.dart';
import 'package:tracker_x/features/tracking/data/tracking_repository.dart';
import 'package:tracker_x/features/welcome/presentation/welcome_screen.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Hive
  final appDocDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocDir.path);

  // Initialize local data source
  final localDS = TrackingLocalDS();
  await localDS.init();

  // Initialize background tasks
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    'locationTask',
    'fetchLocation',
    frequency: const Duration(minutes: 15),
  );

  // Create repository
  final repo = TrackingRepository(
    LocationService(),
    ApiClient('https://your-api-endpoint.com'),
    localDS,
  );

  runApp(MyApp(repo: repo));
}

class MyApp extends StatelessWidget {
  final TrackingRepository repo;
  const MyApp({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TrackingCubit(repo),
      child: MaterialApp(
        title: 'Tracker X',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: WelcomeScreen(repo: repo),
      ),
    );
  }
}
```

## Step 11: Permissions Configuration

### Android Permissions

Update `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

### iOS Permissions

Update `ios/Runner/Info.plist`:

```xml
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location access to track your position.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to track your position.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>This app needs background location access for continuous tracking.</string>
```

## Step 12: Firebase Setup

1. **Create Firebase Project**: Go to Firebase Console and create a new project
2. **Add Flutter App**: Follow the FlutterFire CLI setup instructions
3. **Enable Firestore**: Enable Cloud Firestore in your Firebase project
4. **Configure Rules**: Set up Firestore security rules

Firestore Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /locations/{document} {
      allow read, write: if true; // Adjust based on your auth requirements
    }
  }
}
```

## Step 13: Testing and Debugging

### Test Location Permissions

```dart
void testLocationService() async {
  final locationService = LocationService();
  final hasPermission = await locationService.ensurePermissions();
  print('Permission granted: $hasPermission');
}
```

### Test Firebase Connection

```dart
void testFirebaseConnection() async {
  await FirebaseFirestore.instance.collection('test').add({
    'timestamp': FieldValue.serverTimestamp(),
    'message': 'Connection test successful'
  });
}
```

## Step 14: Advanced Features

### Real-time Map Updates

The map screen includes:
- **Smooth marker animation** between location updates
- **Follow mode** that automatically centers on current location
- **Map style switching** between different tile providers
- **Track history visualization** with polylines

### Background Location Tracking

Implements WorkManager for:
- **Periodic location updates** even when app is closed
- **Battery optimization** with configurable intervals
- **Offline storage** with sync when connectivity returns

### State Persistence

Uses Hive for:
- **Local location history** storage
- **Offline capability** when network is unavailable
- **Fast data retrieval** for app startup

## Step 15: Performance Optimization

### Location Service Optimization

```dart
// Optimize for battery life
await locationService.start(
  accuracy: LocationAccuracy.balanced, // Instead of high
  distanceFilterMeters: 50, // Larger distance filter
  interval: Duration(seconds: 30), // Less frequent updates
);
```

### Memory Management

```dart
@override
void dispose() {
  // Always clean up subscriptions
  _locationSubscription?.cancel();
  _repository.dispose();
  super.dispose();
}
```

## Step 16: Deployment Preparation

### Build for Android

```bash
flutter build apk --release
```

### Build for iOS

```bash
flutter build ios --release
```

### Key Considerations

1. **Location Permissions**: Test thoroughly on both platforms
2. **Background Execution**: Verify background tasks work correctly
3. **Firebase Quotas**: Monitor Firestore usage and costs
4. **Battery Usage**: Test impact on device battery life
5. **Network Handling**: Test offline scenarios

## Conclusion

You've built a comprehensive location tracking app with:

- ✅ Real-time location tracking with permissions
- ✅ Beautiful glassmorphism UI design
- ✅ State management with Cubit pattern
- ✅ Firebase real-time synchronization
- ✅ Interactive map with animations
- ✅ Background location tracking
- ✅ Local data persistence
- ✅ Professional architecture patterns

### Next Steps

1. **Add user authentication** with Firebase Auth
2. **Implement geofencing** for location-based alerts
3. **Add location sharing** between users
4. **Implement location analytics** and insights
5. **Add offline map support** for remote areas
6. **Implement location-based notifications**

### Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Geolocator Package](https://pub.dev/packages/geolocator)
- [Flutter Map Package](https://pub.dev/packages/flutter_map)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter Bloc Documentation](https://bloclibrary.dev/)

This codelab provides a solid foundation for building location-aware Flutter applications with professional architecture and beautiful UI design.