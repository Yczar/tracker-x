import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:tracker_x/enums/map_style.dart';
import 'package:tracker_x/features/map/presentation/layers/base_tile_layer.dart';

class TrackViewerScreen extends StatefulWidget {
  const TrackViewerScreen({super.key});

  @override
  State<TrackViewerScreen> createState() => _TrackViewerScreenState();
}

class _TrackViewerScreenState extends State<TrackViewerScreen>
    with TickerProviderStateMixin {
  final MapController _controller = MapController();

  int _mapStyleIndex = 0;

  late AnimationController _pulseController;
  late AnimationController _moveController;
  Animation<LatLng>? _moveAnimation;
  bool _isFollowMode = false;

  LatLng? _animatedPosition;
  List<LatLng> _trackPoints = [];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Subscribe to Firestore manually
    FirebaseFirestore.instance
        .collection('locations')
        .orderBy('timestamp')
        .snapshots()
        .listen((snapshot) {
          final newPoints = snapshot.docs.map((doc) {
            final data = doc.data();
            return LatLng(
              (data['lat'] as num).toDouble(),
              (data['lng'] as num).toDouble(),
            );
          }).toList();

          if (newPoints.isEmpty) return;

          setState(() {
            if (_trackPoints.isEmpty) {
              // first load
              _trackPoints = newPoints;
              _animatedPosition = newPoints.last;
            } else if (newPoints.last != _trackPoints.last) {
              // add only new point
              final from = _trackPoints.last;
              final to = newPoints.last;

              _trackPoints.add(to);
              _animateMarker(from, to);
            }
          });
        });
  }

  void _animateMarker(LatLng from, LatLng to) {
    _moveController.reset();
    _moveAnimation =
        LatLngTween(begin: from, end: to).animate(
          CurvedAnimation(parent: _moveController, curve: Curves.easeInOut),
        )..addListener(() {
          setState(() {
            _animatedPosition = _moveAnimation!.value;
            if (_isFollowMode && _animatedPosition != null) {
              _controller.move(_animatedPosition!, _controller.camera.zoom);
            }
          });
        });

    _moveController.forward().whenComplete(() {
      setState(() {
        _animatedPosition = to;
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _moveController.dispose();
    super.dispose();
  }

  void _nextMapStyle() {
    setState(() {
      _mapStyleIndex = (_mapStyleIndex + 1) % MapStyle.values.length;
    });
  }

  void _focusOnTrack() {
    if (_trackPoints.isEmpty) return;
    _controller.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(_trackPoints),
        padding: const EdgeInsets.all(40),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.nunitoTextTheme(Theme.of(context).textTheme);

    return Scaffold(
      body: _trackPoints.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _controller,
                  options: MapOptions(
                    initialCenter: _trackPoints.first,
                    initialZoom: 16,
                  ),
                  children: [
                    BaseTileLayer(),

                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [
                            ..._trackPoints.take(
                              _trackPoints.length - 1,
                            ), // full history
                            _animatedPosition ??
                                _trackPoints.last, // moving head
                          ],
                          color: Colors.blueAccent,
                          strokeWidth: 6,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        // Moving marker
                        Marker(
                          point: _animatedPosition ?? _trackPoints.last,
                          width: 80,
                          height: 80,
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              final scale = 1 + (_pulseController.value * 0.4);
                              return Center(
                                child: Container(
                                  width: 30 * scale,
                                  height: 30 * scale,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withValues(
                                      alpha: 0.5 * (1 - _pulseController.value),
                                    ),
                                  ),
                                  child: const Icon(
                                    FontAwesomeIcons.locationDot,
                                    color: Colors.black,
                                    size: 24,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Static history points
                        ..._trackPoints
                            .take(_trackPoints.length - 1)
                            .map(
                              (point) => Marker(
                                width: 50,
                                height: 50,
                                point: point,
                                child: GestureDetector(
                                  onTap: () =>
                                      _showPointDetails(context, point),
                                  child: const Icon(
                                    FontAwesomeIcons.solidCircle,
                                    color: Colors.blueAccent,
                                    size: 12,
                                  ),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ],
                ),
                _buildUserCard(textTheme),
                _buildMapControls(),
              ],
            ),
    );
  }

  Widget _buildUserCard(TextTheme textTheme) {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(
                    'https://i.pravatar.cc/150?img=68',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'John Doe',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey.shade900,
                        ),
                      ),
                      Text(
                        'Last seen live',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.blueGrey.shade700,
                        ),
                      ),
                      Text(
                        'Speed: -- km/h',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.blueGrey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  FontAwesomeIcons.solidCircleCheck,
                  color: Colors.green,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      bottom: 30,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'focus',
            onPressed: _focusOnTrack,
            backgroundColor: Colors.white,
            child: const Icon(
              FontAwesomeIcons.crosshairs,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 14),
          FloatingActionButton(
            heroTag: 'style',
            onPressed: _nextMapStyle,
            backgroundColor: Colors.white,
            child: const Icon(FontAwesomeIcons.map, color: Colors.blueAccent),
          ),
          const SizedBox(height: 14),
          FloatingActionButton(
            heroTag: 'follow',
            onPressed: () {
              setState(() {
                _isFollowMode = !_isFollowMode;
              });
            },
            backgroundColor: _isFollowMode ? Colors.blueAccent : Colors.white,
            child: Icon(
              FontAwesomeIcons.locationArrow,
              color: _isFollowMode ? Colors.white : Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  void _showPointDetails(BuildContext context, LatLng point) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Waypoint Details',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Latitude: ${point.latitude.toStringAsFixed(5)}',
              style: GoogleFonts.nunito(fontSize: 16),
            ),
            Text(
              'Longitude: ${point.longitude.toStringAsFixed(5)}',
              style: GoogleFonts.nunito(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(FontAwesomeIcons.xmark),
              label: const Text('Close'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Tween for LatLng interpolation
class LatLngTween extends Tween<LatLng> {
  LatLngTween({required LatLng begin, required LatLng end})
    : super(begin: begin, end: end);

  @override
  LatLng lerp(double t) {
    return LatLng(
      begin!.latitude + (end!.latitude - begin!.latitude) * t,
      begin!.longitude + (end!.longitude - begin!.longitude) * t,
    );
  }
}
