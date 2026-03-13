import 'package:get_it/get_it.dart';

import '../discoveries/discovery_repository.dart';
import '../discoveries/discovery_service.dart';
import '../discoveries/overpass_client.dart';
import '../location/location_service.dart';
import '../location/walk_repository.dart';
import '../location/walk_service.dart';

/// Global service locator instance.
final GetIt serviceLocator = GetIt.instance;

/// Alias for [serviceLocator] for convenience.
final GetIt sl = serviceLocator;

/// Registers all application services with the dependency injection container.
///
/// Call once at app startup before [runApp].
Future<void> setupLocator() async {
  // Infrastructure
  sl.registerLazySingleton<LocationService>(GeolocatorLocationService.new);
  sl.registerLazySingleton<WalkRepository>(HiveWalkRepository.new);
  sl.registerLazySingleton<OverpassClient>(HttpOverpassClient.new);
  sl.registerLazySingleton<DiscoveryRepository>(HiveDiscoveryRepository.new);

  // Domain services
  sl.registerLazySingleton<WalkService>(
    () => WalkService(
      locationService: sl<LocationService>(),
      repository: sl<WalkRepository>(),
    ),
  );
  sl.registerLazySingleton<DiscoveryService>(
    () => DiscoveryService(
      overpassClient: sl<OverpassClient>(),
      repository: sl<DiscoveryRepository>(),
    ),
  );
}
