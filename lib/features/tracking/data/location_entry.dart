import 'package:hive/hive.dart';

part 'location_entry.g.dart';

@HiveType(typeId: 1)
class LocationEntry extends HiveObject {
  @HiveField(0)
  String trackerId;

  @HiveField(1)
  double lat;

  @HiveField(2)
  double lng;

  @HiveField(3)
  double? accuracy;

  @HiveField(4)
  double? speed;

  @HiveField(5)
  String timestamp;

  LocationEntry({
    required this.trackerId,
    required this.lat,
    required this.lng,
    this.accuracy,
    this.speed,
    required this.timestamp,
  });
}
