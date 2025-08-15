import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tracker_x/core/network/api_client.dart';
import 'package:tracker_x/core/services/background_task.dart';
import 'package:tracker_x/core/services/location_service.dart';
import 'package:tracker_x/features/tracking/cubit/tracking_cubit.dart';
import 'package:tracker_x/features/tracking/data/tracking_local_ds.dart';
import 'package:tracker_x/features/tracking/data/tracking_repository.dart';
import 'package:tracker_x/features/welcome/presentation/welcome_screen.dart';
import 'package:tracker_x/firebase_options.dart';

import 'package:workmanager/workmanager.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options:
        DefaultFirebaseOptions.currentPlatform, // from flutterfire configure
  );
  final appDocDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocDir.path);

  final localDS = TrackingLocalDS();
  await localDS.init();

  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    'locationTask',
    'fetchLocation',
    frequency: const Duration(minutes: 15),
  );

  final repo = TrackingRepository(
    LocationService(),
    ApiClient('https://trackerx-5jbx2mw-ayotomide-babalola.globeapp.dev'),
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
      child: MaterialApp(home: WelcomeScreen(repo: repo)),
    );
  }
}
