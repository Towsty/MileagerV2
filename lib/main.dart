import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Providers
import 'providers/vehicle_provider.dart';
import 'providers/trip_provider.dart';

// Services
import 'services/location_service.dart';
import 'services/bluetooth_service.dart';
import 'services/trip_tracking_service.dart';
import 'services/activity_recognition_service.dart';
import 'services/auto_tracking_service.dart';

// Screens
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProvider(create: (_) => TripProvider()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(create: (_) => BluetoothService()),
        ChangeNotifierProvider(create: (_) => ActivityRecognitionService()),
        ChangeNotifierProxyProvider4<TripProvider, VehicleProvider,
            ActivityRecognitionService, LocationService, TripTrackingService>(
          create: (context) => TripTrackingService(
            context.read<TripProvider>(),
            context.read<VehicleProvider>(),
            context.read<ActivityRecognitionService>(),
            context.read<LocationService>(),
          ),
          update: (context, tripProvider, vehicleProvider, activityService,
                  locationService, previous) =>
              previous ??
              TripTrackingService(tripProvider, vehicleProvider,
                  activityService, locationService),
        ),
      ],
      child: MaterialApp(
        title: 'Mileager',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
          ),
        ),
        themeMode: ThemeMode.system, // Follow system theme
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
