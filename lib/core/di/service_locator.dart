import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

import '../analytics/analytics_service.dart';
import '../analytics/install_date_repository.dart';
import '../challenges/challenge_repository.dart';
import '../compass/compass_charges_repository.dart';
import '../config/app_config.dart';
import '../discoveries/discovery_repository.dart';
import '../discoveries/discovery_service.dart';
import '../discoveries/overpass_client.dart';
import '../location/compass_heading_service.dart';
import '../location/location_service.dart';
import '../location/walk_repository.dart';
import '../location/walk_service.dart';
import '../progress/progress_repository.dart';
import '../progress/progress_service.dart';
import '../quiz/quiz_repository.dart';
import '../storage/hive_boxes.dart';
import '../streets/street_overpass_client.dart';
import '../streets/street_repository.dart';
import '../subscription/banner_cooldown_repository.dart';
import '../subscription/milestone_pro_suggestion_frequency.dart';
import '../subscription/purchases_adapter.dart';
import '../subscription/quiz_daily_limit_repository.dart';
import '../subscription/revenuecat_purchases_adapter.dart';
import '../subscription/subscription_service.dart';
import '../subscription/subscription_storage.dart';
import '../zone/mystery_poi_repository.dart';
import '../zone/mystery_poi_service.dart';
import '../zone/poi_cooldown_repository.dart';
import '../zone/zone_detector.dart';
import '../zone/zone_repository.dart';
import '../zone/zone_service.dart';
import '../zone/zone_stats_service.dart';

/// Global service locator instance.
final GetIt serviceLocator = GetIt.instance;

/// Alias for [serviceLocator] for convenience.
final GetIt sl = serviceLocator;

/// Registers all application services with the dependency injection container.
///
/// Call once at app startup before [runApp].
///
/// Registration strategy:
/// - [GeolocatorLocationService]    — singleton: one GPS stream for the app lifetime.
/// - [HiveWalkRepository]           — singleton: single Hive box reference.
/// - [WalkService]                  — singleton: one active walk session at a time.
/// - [HttpOverpassClient]           — singleton: shared HTTP client for POI Overpass queries.
/// - [HiveDiscoveryRepository]      — singleton: single Hive box reference for POI cache.
/// - [DiscoveryService]             — singleton: one discovery pipeline for the app lifetime.
/// - [HiveProgressRepository]       — singleton: single Hive box reference for progress data.
/// - [ProgressService]              — singleton: exploration %, badges, and streak logic.
/// - [HttpStreetOverpassClient]     — singleton: shared HTTP client for street Overpass queries.
/// - [HiveStreetRepository]         — singleton: single Hive box reference for street cache.
/// - [RevenueCatPurchasesAdapter]   — singleton: one RevenueCat SDK instance.
/// - [HiveSubscriptionStorage]      — singleton: single Hive box reference for subscription cache.
/// - [SubscriptionService]          — singleton: subscription state manager.
Future<void> setupLocator() async {
  // Infrastructure
  sl.registerSingleton<CompassHeadingService>(FlutterCompassHeadingService());
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

  // Streets
  sl.registerLazySingleton<StreetOverpassClient>(
      HttpStreetOverpassClient.new);
  sl.registerLazySingleton<StreetRepository>(HiveStreetRepository.new);

  // Quiz
  sl.registerLazySingleton<QuizRepository>(HiveQuizRepository.new);

  // Challenges
  sl.registerLazySingleton<ChallengeRepository>(
      HiveChallengeRepository.new);

  // Compass
  sl.registerLazySingleton<CompassChargesRepository>(
      HiveCompassChargesRepository.new);

  // Zones
  sl.registerLazySingleton<ZoneRepository>(HiveZoneRepository.new);
  sl.registerLazySingleton<ZoneDetector>(ZoneDetector.new);
  sl.registerLazySingleton<ZoneService>(
    () => ZoneService(repository: sl<ZoneRepository>()),
  );
  sl.registerLazySingleton<ZoneStatsService>(
    () => ZoneStatsService(
      streetRepository: sl<StreetRepository>(),
      discoveryRepository: sl<DiscoveryRepository>(),
      walkRepository: sl<WalkRepository>(),
      quizRepository: sl<QuizRepository>(),
    ),
  );
  sl.registerLazySingleton<MysteryPoiRepository>(
      HiveMysteryPoiRepository.new);
  sl.registerLazySingleton<PoiCooldownRepository>(
      HivePoiCooldownRepository.new);
  sl.registerLazySingleton<MysteryPoiService>(
    () => MysteryPoiService(
      repository: sl<MysteryPoiRepository>(),
      overpassClient: sl<OverpassClient>(),
      zoneDetector: sl<ZoneDetector>(),
    ),
  );

  // Subscription
  sl.registerLazySingleton<PurchasesAdapter>(
    RevenueCatPurchasesAdapter.new,
  );
  sl.registerLazySingleton<SubscriptionStorage>(
    () => HiveSubscriptionStorage(Hive.box<dynamic>(HiveBoxes.subscription)),
  );
  sl.registerLazySingleton<SubscriptionService>(
    () => SubscriptionService(
      adapter: sl<PurchasesAdapter>(),
      storage: sl<SubscriptionStorage>(),
      revenueCatApiKey: defaultTargetPlatform == TargetPlatform.iOS
          ? AppConfig.revenueCatIosApiKey
          : AppConfig.revenueCatAndroidApiKey,
    ),
  );
  sl.registerLazySingleton<QuizDailyLimitRepository>(
    () => QuizDailyLimitRepository(
      storage: HiveQuizLimitStorage(Hive.box<dynamic>(HiveBoxes.quizDailyLimit)),
      clock: DateTime.now,
      subscriptionState: () => sl<SubscriptionService>().state.value,
    ),
  );
  sl.registerLazySingleton<BannerCooldownRepository>(
    () => BannerCooldownRepository.withBox(
      Hive.box<dynamic>(HiveBoxes.bannerCooldown),
    ),
  );
  sl.registerLazySingleton<MilestoneProSuggestionFrequency>(
    () => MilestoneProSuggestionFrequency(),
  );

  // Analytics
  sl.registerLazySingleton<AnalyticsService>(
    () => kDebugMode
        ? DebugAnalyticsService()
        : const NoOpAnalyticsService(),
  );
  sl.registerLazySingleton<InstallDateRepository>(
    () => InstallDateRepository(Hive.box<dynamic>(HiveBoxes.analytics)),
  );
}
