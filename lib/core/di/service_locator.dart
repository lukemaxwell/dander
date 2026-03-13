import 'package:get_it/get_it.dart';

import '../discoveries/discovery_repository.dart';
import '../discoveries/discovery_service.dart';
import '../discoveries/overpass_client.dart';
import '../location/location_service.dart';
import '../location/walk_repository.dart';
import '../location/walk_service.dart';
import '../progress/progress_repository.dart';
import '../progress/progress_service.dart';
import '../quiz/quiz_repository.dart';

/// Global service locator instance.
final GetIt serviceLocator = GetIt.instance;

/// Alias for [serviceLocator] for convenience.
final GetIt sl = serviceLocator;

/// Registers all application services with the dependency injection container.
///
/// Call once at app startup before [runApp].
///
/// Registration strategy:
/// - [GeolocatorLocationService] — singleton: one GPS stream for the app lifetime.
/// - [HiveWalkRepository]        — singleton: single Hive box reference.
/// - [WalkService]               — singleton: one active walk session at a time.
/// - [HttpOverpassClient]        — singleton: shared HTTP client for Overpass queries.
/// - [HiveDiscoveryRepository]   — singleton: single Hive box reference for POI cache.
/// - [DiscoveryService]          — singleton: one discovery pipeline for the app lifetime.
/// - [HiveProgressRepository]    — singleton: single Hive box reference for progress data.
/// - [ProgressService]           — singleton: exploration %, badges, and streak logic.
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

  // Progress
  sl.registerLazySingleton<ProgressRepository>(HiveProgressRepository.new);
  sl.registerLazySingleton<ProgressService>(ProgressService.new);

  // Quiz
  sl.registerLazySingleton<QuizRepository>(HiveQuizRepository.new);
}
