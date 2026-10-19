import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import '../../app/app_shell.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/fuel/screens/nearby_fuel_screen.dart';
import '../../features/fuel/screens/station_details_screen.dart';
import '../../features/spatial/screens/spatial_mapping_screen.dart';
import 'package:fuelsense_mobile/features/fuel_quality/screens/fuel_quality_screen.dart';
import '../../features/fuel/screens/energy_history_screen.dart';
import '../../features/fuel/models/fuel_station_model.dart';
import '../../features/map/screens/map_screen.dart';
import '../../shared/models/vehicle.dart';
import '../../features/vehicle/screens/vehicle_setup_screen.dart';
import '../../features/vehicle/screens/vehicle_details_screen.dart';
import '../../features/garage/presentation/garage_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/vehicle-setup',
      builder: (context, state) {
        final vehicle = state.extra;
        return VehicleSetupScreen(vehicle: vehicle is Vehicle ? vehicle : null);
      },
    ),
    GoRoute(
      path: '/vehicle-details',
      builder: (context, state) {
        final vehicle = state.extra;
        if (vehicle is! Vehicle) {
          return const Scaffold(
            body: Center(child: Text('Vehicle information unavailable')),
          );
        }
        return VehicleDetailsScreen(vehicle: vehicle);
      },
    ),
    GoRoute(
      path: '/fuel-stations',
      builder: (context, state) => const NearbyFuelScreen(),
    ),
    GoRoute(
      path: '/energy-history',
      builder: (context, state) => const EnergyHistoryScreen(),
    ),
    GoRoute(
      path: '/fuel-quality',
      builder: (context, state) => const FuelQualityScreen(),
    ),
    GoRoute(
      path: '/spatial-mapping',
      builder: (context, state) => const SpatialMappingScreen(),
    ),

    GoRoute(
      path: '/station-details',
      builder: (context, state) {
        final station = state.extra;

        if (station is! FuelStation) {
          return const Scaffold(
            body: Center(child: Text('Station information unavailable')),
          );
        }

        return StationDetailsScreen(station: station);
      },
    ),
    GoRoute(
      path: '/map',
      builder: (context, state) {
        final stationId = state.uri.queryParameters['stationId'];

        return MapScreen(
          initialStationId: stationId == null ? null : int.tryParse(stationId),
        );
      },
    ),
    GoRoute(path: '/garage', builder: (context, state) => const GarageScreen()),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const AppShell()),
  ],
);

