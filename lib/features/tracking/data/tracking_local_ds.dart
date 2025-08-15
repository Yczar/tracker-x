import 'package:hive/hive.dart';
import 'location_entry.dart';

class TrackingLocalDS {
  static const _boxName = 'location_entries';
  late Box<LocationEntry> _box;

  Future<void> init() async {
    Hive.registerAdapter(LocationEntryAdapter());
    _box = await Hive.openBox<LocationEntry>(_boxName);
  }

  Future<void> save(LocationEntry entry) async {
    await _box.add(entry);
  }

  List<LocationEntry> getAll() => _box.values.toList();

  Future<void> remove(LocationEntry entry) async {
    await entry.delete();
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
