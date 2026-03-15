import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/app/app_initializer.dart';
import 'core/config/app_config.dart';
import 'core/di/service_locator.dart';
import 'core/navigation/app_router.dart';
import 'core/network/connectivity_service.dart';
import 'core/onboarding/first_launch_service.dart';
import 'core/quiz/quiz_repository.dart';
import 'core/storage/app_state_repository.dart';
import 'core/storage/hive_boxes.dart';
import 'core/streets/street_repository.dart';
import 'core/subscription/subscription_service.dart';
import 'core/sync/sync_service.dart';
import 'core/theme/app_theme.dart';
import 'core/zone/zone_migration.dart';
import 'core/zone/zone_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ------------------------------------------------------------------
  // Hive initialisation
  // ------------------------------------------------------------------
  await Hive.initFlutter();

  // Open all required boxes up-front so the rest of the app can
  // access them synchronously via Hive.box(...).
  await Future.wait([
    Hive.openBox<dynamic>(HiveBoxes.fogState),
    Hive.openBox<dynamic>(HiveBoxes.walks),
    Hive.openBox<dynamic>(HiveBoxes.discoveries),
    Hive.openBox<dynamic>(HiveBoxes.progress),
    Hive.openBox<dynamic>(HiveBoxes.appState),
    Hive.openBox<dynamic>(HiveBoxes.streets),
    Hive.openBox<dynamic>(HiveBoxes.quiz),
    Hive.openBox<dynamic>(HiveBoxes.zones),
    Hive.openBox<dynamic>(HiveBoxes.mysteryPois),
    Hive.openBox<dynamic>(HiveBoxes.poiCooldowns),
    Hive.openBox<dynamic>(HiveBoxes.challenges),
    Hive.openBox<dynamic>(HiveBoxes.subscription),
    Hive.openBox<dynamic>(HiveBoxes.quizDailyLimit),
    Hive.openBox<dynamic>(HiveBoxes.bannerCooldown),
    Hive.openBox<dynamic>(HiveBoxes.milestoneProFrequency),
    Hive.openBox<dynamic>(HiveBoxes.analytics),
  ]);

  // ------------------------------------------------------------------
  // App state repository (backed by the appState box)
  // ------------------------------------------------------------------
  final appStateBox = Hive.box<dynamic>(HiveBoxes.appState);
  final appStateRepository = AppStateRepositoryImpl(box: appStateBox);

  // ------------------------------------------------------------------
  // App initialisation — first-launch detection
  // ------------------------------------------------------------------
  final initializer = AppInitializer(appStateRepository: appStateRepository);
  final initResult = await initializer.initialize();

  if (initResult.isFirstLaunch) {
    // Mark first launch complete immediately so subsequent starts are fast.
    await appStateRepository.markFirstLaunchComplete();
  }

  // ------------------------------------------------------------------
  // First-launch onboarding state
  // ------------------------------------------------------------------
  final sl = GetIt.instance;
  sl.registerSingleton<FirstLaunchService>(
    FirstLaunchService(isFirstLaunch: initResult.isFirstLaunch),
  );

  // ------------------------------------------------------------------
  // Config validation — fails loudly in debug if API keys are missing
  // ------------------------------------------------------------------
  AppConfig.validate();

  // ------------------------------------------------------------------
  // Dependency injection
  // ------------------------------------------------------------------
  await setupLocator();

  // ------------------------------------------------------------------
  // Subscription service initialisation — loads cached state and fetches
  // live entitlement from RevenueCat in the background.
  // ------------------------------------------------------------------
  // ignore: unawaited_futures
  sl<SubscriptionService>().initialize();

  // ------------------------------------------------------------------
  // Zone migration — convert legacy data into zone model (one-shot)
  // ------------------------------------------------------------------
  await ZoneMigration.migrate(
    zoneRepo: sl<ZoneRepository>(),
    appStateRepo: appStateRepository,
    streetRepo: sl<StreetRepository>(),
    quizRepo: sl<QuizRepository>(),
  );

  // ------------------------------------------------------------------
  // Connectivity + sync service
  // ------------------------------------------------------------------
  final connectivityService = ConnectivityServiceImpl();
  final syncService = SyncService(
    connectivity: connectivityService,
    appStateRepository: appStateRepository,
    // POI sync callback — placeholder; replaced by real implementation
    // once the POI loading feature is wired in.
    poiSyncCallback: (_) async {},
  );

  runApp(
    DanderApp(
      initResult: initResult,
      syncService: syncService,
    ),
  );
}

/// Root application widget.
class DanderApp extends StatefulWidget {
  const DanderApp({
    super.key,
    required this.initResult,
    required this.syncService,
  });

  final InitResult initResult;
  final SyncService syncService;

  @override
  State<DanderApp> createState() => _DanderAppState();
}

class _DanderAppState extends State<DanderApp> {
  @override
  void dispose() {
    widget.syncService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Dander',
      theme: buildAppTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
