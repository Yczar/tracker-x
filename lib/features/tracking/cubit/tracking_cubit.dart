import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../data/tracking_repository.dart';

class TrackingState {
  final bool running;
  final Position? position;

  TrackingState({this.running = false, this.position});
  TrackingState copyWith({bool? running, Position? position}) => TrackingState(
    running: running ?? this.running,
    position: position ?? this.position,
  );
}

class TrackingCubit extends Cubit<TrackingState> {
  final TrackingRepository _repo;

  TrackingCubit(this._repo) : super(TrackingState());

  Future<void> start() async {
    final ok = await _repo.ensurePermissions();
    if (!ok) return;

    await _repo.startForegroundTracking();
    _repo.positionStream.listen((pos) {
      emit(state.copyWith(running: true, position: pos));
      _repo.sendPosition(pos); // active tracking send
    });
  }

  Future<void> stop() async {
    await _repo.stopForegroundTracking();
    emit(state.copyWith(running: false, position: null));
  }
}
