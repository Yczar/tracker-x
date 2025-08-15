import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tracker_x/core/network/api_client.dart';
import 'package:tracker_x/features/tracking/data/tracking_local_ds.dart';
import 'package:tracker_x/features/tracking/data/tracking_repository.dart';
import 'package:tracker_x/firebase_options.dart';
import 'package:workmanager/workmanager.dart';
import '../services/location_service.dart';

const String apiUrl = "http://localhost:8080/locations";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final trackingLocal = TrackingLocalDS();
    await trackingLocal
        .init(); // must re-init Hive or local storage if used here

    final repo = TrackingRepository(
      LocationService(),
      ApiClient('http://10.0.2.2:8080'),
      trackingLocal,
    );

    try {
      await repo.sendCurrentLocationOnce();
    } catch (e) {
      print('Background task error: $e');
    }
    return Future.value(true);
  });
}
