import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dander/core/di/service_locator.dart';
import 'package:dander/core/navigation/app_router.dart';
import 'package:dander/core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local storage
  await Hive.initFlutter();

  // Dependency injection
  await setupLocator();

  runApp(const DanderApp());
}

/// Root application widget.
class DanderApp extends StatelessWidget {
  const DanderApp({super.key});

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
