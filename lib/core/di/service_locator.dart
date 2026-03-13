import 'package:get_it/get_it.dart';

/// Global service locator instance.
final GetIt serviceLocator = GetIt.instance;

/// Registers all application services with the dependency injection container.
///
/// Call once at app startup before [runApp].
void setupLocator() {
  // Future services will be registered here as features are added.
  // e.g. serviceLocator.registerLazySingleton<LocationService>(LocationServiceImpl.new);
}
