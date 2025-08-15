import 'package:geolocator/geolocator.dart';
import 'package:tracker_x/core/network/api_client.dart';
import '../../../../core/services/location_service.dart';
import 'tracking_local_ds.dart';
import 'location_entry.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class TrackingRepository {
  final LocationService _locationService;
  final ApiClient _apiClient;
  final TrackingLocalDS _localDS;
  final String _trackerId = 'demo-user'; // Could be dynamic per user

  TrackingRepository(this._locationService, this._apiClient, this._localDS);

  Stream<Position> get positionStream => _locationService.stream;

  Future<bool> ensurePermissions() => _locationService.ensurePermissions();
  Future<void> startForegroundTracking() => _locationService.start();
  Future<void> stopForegroundTracking() => _locationService.stop();
  Future<Position?> getCurrentLocation() => _locationService.getOnce();

  Future<void> sendPosition(Position pos) async {
    final entry = LocationEntry(
      trackerId: _trackerId,
      lat: pos.latitude,
      lng: pos.longitude,
      accuracy: pos.accuracy,
      speed: pos.speed,
      timestamp: DateTime.now().toUtc().toIso8601String(),
    );

    try {
      // send to your existing API
      await _apiClient.sendLocation(
        lat: entry.lat,
        lng: entry.lng,
        accuracy: entry.accuracy,
        speed: entry.speed,
        trackerId: entry.trackerId,
        timestamp: DateTime.parse(entry.timestamp),
      );

      // ALSO write to Firestore
      await FirebaseFirestore.instance.collection('locations').add({
        'trackerId': entry.trackerId,
        'lat': entry.lat,
        'lng': entry.lng,
        'accuracy': entry.accuracy,
        'speed': entry.speed,
        'timestamp': entry.timestamp,
      });
    } catch (error) {
      print('Location $error');
      // offline — save locally
      await _localDS.save(entry);
    }
  }

  Future<void> sendCurrentLocationOnce() async {
    final ok = await ensurePermissions();
    if (!ok) return;
    final pos = await getCurrentLocation();
    if (pos != null) await sendPosition(pos);
  }

  /// Sync cached locations when online
  Future<void> syncPending() async {
    final pending = _localDS.getAll();
    for (final entry in pending) {
      try {
        await _apiClient.sendLocation(
          lat: entry.lat,
          lng: entry.lng,
          accuracy: entry.accuracy,
          speed: entry.speed,
          trackerId: entry.trackerId,
          timestamp: DateTime.parse(entry.timestamp),
        );

        // ALSO sync to Firestore
        await FirebaseFirestore.instance.collection('locations').add({
          'trackerId': entry.trackerId,
          'lat': entry.lat,
          'lng': entry.lng,
          'accuracy': entry.accuracy,
          'speed': entry.speed,
          'timestamp': entry.timestamp,
        });

        await _localDS.remove(entry);
      } catch (_) {
        // if still offline, stop early to save battery
        break;
      }
    }
  }
}
