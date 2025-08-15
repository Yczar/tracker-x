import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/tracking_cubit.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'tracking_cubit.dart'; // your existing cubit imports

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.nunitoTextTheme(Theme.of(context).textTheme);

    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      body: SafeArea(
        child: BlocBuilder<TrackingCubit, TrackingState>(
          builder: (context, state) {
            final pos = state.position;

            return Stack(
              children: [
                // Background gradient
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFdfe9f3), Color(0xFFffffff)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Content
                Center(
                  child: pos == null
                      ? _NoLocationView(textTheme: textTheme)
                      : _TrackingCard(state: state, textTheme: textTheme),
                ),
                // Floating control button
                Positioned(
                  bottom: 30,
                  right: 20,
                  child: _TrackingFAB(state: state),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// --- COMPONENTS ---

class _NoLocationView extends StatelessWidget {
  final TextTheme textTheme;
  const _NoLocationView({required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          'No location yet',
          style: textTheme.titleMedium?.copyWith(
            color: Colors.blueGrey.shade800,
          ),
        ),
      ],
    );
  }
}

class _TrackingCard extends StatelessWidget {
  final TrackingState state;
  final TextTheme textTheme;
  const _TrackingCard({required this.state, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    final pos = state.position!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                FontAwesomeIcons.locationDot,
                size: 36,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 16),
              Text(
                'Live Location',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey.shade900,
                ),
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.blueGrey.shade100),
              const SizedBox(height: 12),
              _InfoRow(
                label: 'Latitude',
                value: pos.latitude.toStringAsFixed(5),
                textTheme: textTheme,
              ),
              _InfoRow(
                label: 'Longitude',
                value: pos.longitude.toStringAsFixed(5),
                textTheme: textTheme,
              ),
              _InfoRow(
                label: 'Speed',
                value: '${pos.speed.toStringAsFixed(1)} m/s',
                textTheme: textTheme,
              ),
              _InfoRow(
                label: 'Accuracy',
                value: '${pos.accuracy.toStringAsFixed(1)} m',
                textTheme: textTheme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextTheme textTheme;
  const _InfoRow({
    required this.label,
    required this.value,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.blueGrey.shade700,
            ),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingFAB extends StatelessWidget {
  final TrackingState state;
  const _TrackingFAB({required this.state});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        final cubit = context.read<TrackingCubit>();
        state.running ? cubit.stop() : cubit.start();
      },
      backgroundColor: state.running ? Colors.redAccent : Colors.blueAccent,
      child: Icon(
        state.running ? Icons.stop : Icons.play_arrow,
        color: Colors.white,
      ),
    );
  }
}
