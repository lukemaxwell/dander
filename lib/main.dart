import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/app/app_initializer.dart';
import 'core/di/service_locator.dart';
import 'core/navigation/app_router.dart';
import 'core/network/connectivity_service.dart';
import 'core/quiz/quiz_repository.dart';
import 'core/storage/app_state_repository.dart';
import 'core/storage/hive_boxes.dart';
import 'core/streets/street_repository.dart';
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
  // Dependency injection
  // ------------------------------------------------------------------
  await setupLocator();

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
