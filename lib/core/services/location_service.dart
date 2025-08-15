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
